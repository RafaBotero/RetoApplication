package com.acmeclub.accountservice;

public class AcmeClubAccount {

    
    private int id;
    private String name;
    private String email;
    private int pointsBalance;

    public AcmeClubAccount(int id, String name, String email, int pointsBalance) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.pointsBalance = pointsBalance; 
    }

    public int getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public int getPointsBalance() {
        return pointsBalance;
    }

    public void setPointsBalance(int pointsBalance) {
        this.pointsBalance = pointsBalance;
    }
}