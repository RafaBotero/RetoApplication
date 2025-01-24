# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


# Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "acme-vpc"
  }
}

# Create Public Subnets
resource "aws_subnet" "public" {
  count       = length(var.public_subnet_cidr_blocks)
  vpc_id      = aws_vpc.main.id
  cidr_block  = element(var.public_subnet_cidr_blocks, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true 

  tags = {
    Name = "public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = 1
  }
}

# Create Private Subnets
resource "aws_subnet" "private" {
  count       = length(var.private_subnet_cidr_blocks)
  vpc_id      = aws_vpc.main.id
  cidr_block  = element(var.private_subnet_cidr_blocks, count.index)
  availability_zone = element(var.availability_zones, count.index)
 # availability_zone = "us-east-1a" # Replace with your desired AZ

  tags = {
    Name = "private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = 1
  }
}

## Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "acme-internet-gateway"
  }
}

# Route Tables
# -----------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-route-table"
  }
}

# Create a separate route table for each private subnet
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-${count.index + 1}"
  }
}

resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0" 
  gateway_id     = aws_internet_gateway.main.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate public subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# NAT Gateway
# ------------------------------------

# Create NAT Gateways (one per AZ)
resource "aws_nat_gateway" "main" {
  count         = 2  # Create 2 NAT Gateways
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id  # Place NAT Gateway in public subnets

  tags = {
    Name = "acme-gateway-${count.index + 1}"
  }

  # Add dependency to ensure the Internet Gateway is created first
  depends_on = [aws_internet_gateway.main]
}

# Create Elastic IPs for the NAT Gateways
resource "aws_eip" "nat" {
  count = 2  # Create 2 EIPs

  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}

# Create a route for private subnets to use the NAT Gateway
resource "aws_route" "private_route" {
  count                  = 2
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

#### Security Groups and  ACLs
# -----------------------

# Security Group for Public Instances (e.g., bastion hosts, web servers)
resource "aws_security_group" "public" {
  name        = "public-sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.main.id  # Replace with your VPC reference

  # Inbound Rules
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from anywhere (consider restricting to your IP)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # For better security, replace with your IP: ["your-ip/32"]
  }

  # Outbound Rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "public-sg"
    CreatedBy = "RafaBotero"
    CreatedAt = "2025-01-22"
  }
}

# Security Group for Private Instances
resource "aws_security_group" "private" {
  name        = "private-sg"
  description = "Security group for private instances"
  vpc_id      = aws_vpc.main.id  # Replace with your VPC reference

  # Inbound Rules
  ingress {
    description     = "Allow SSH from public subnet instances only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]  # Allow SSH only from public security group
  }

  ingress {
    description = "Allow HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # Replace with your VPC CIDR
  }

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # Replace with your VPC CIDR
  }

  # Outbound Rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "private-sg"
    CreatedBy = "RafaBotero"
    CreatedAt = "2025-01-22"
  }
}


# Create an EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-0df8c184d5f6ae949" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.public.id]
  associate_public_ip_address = true 
  key_name = "acme" 
  tags = {
    Name = "Test EC2 Instance"
  }
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip 
}

## EKS 
## ------
# Create the EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "acme-eks-cluster"
  cluster_version = "1.28"

  # VPC configuration
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

    eks_managed_node_groups = {
        one = {
            name = "node-group-1"

            instance_types = ["t3.micro"]

            min_size     = 1
            max_size     = 3
            desired_size = 2
        }

        two = {
            name = "node-group-2"

            instance_types = ["t3.micro"]

            min_size     = 1
            max_size     = 2
            desired_size = 1
        }
    }
}