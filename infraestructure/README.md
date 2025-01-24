# Infraestructura de AcmeClub

Este directorio contiene las configuraciones y la configuración de infraestructura para el proyecto AcmeClub.

## Descripción General

El componente de infraestructura gestiona todos los aspectos de despliegue, configuración y mantenimiento de la aplicación AcmeClub.

## Estructura

```
infraestructura/
├── README.md
└── main.tf
└── terraform.tfvars
└── variables.tf
```


## Configuración Inicial

- [ ] Instalar terraform 5 o superior
- [ ] Instalar aws cli


## Requisitos

- Una cuenta de AWS
- Crear un usuario usando el IAM con permisos para crear infra
- Generar un par key de ssh

## Despliegue

```
terraform plan
terraform apply 
```

Para preguntas relacionadas con la infraestructura, por favor contacte al Rafa Botero o cree un issue.   