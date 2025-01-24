package com.acmeclub.accountservice;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AcmeClubController {

    private static final Map<String, AcmeClubAccount> accounts = new HashMap<>();

    static {
        accounts.put("rafa@acme.com", new AcmeClubAccount("Rafael", "rafa@acme.com", 100));
        accounts.put("samuel@acme.com" , new AcmeClubAccount("Samuel", "samuel@acme.com", 200)); 
        accounts.put("simon@acme.com" , new AcmeClubAccount("Simon", "simon@acme.com", 200)); 
        accounts.put("jenny@acme.com" , new AcmeClubAccount("Jenny", "jenny@acme.com", 200)); 
    }

    @GetMapping("/acme")
    public String getAcmeClubInfo() {
        return "Welcome to AcmeClub!";
    }

    @GetMapping("/accounts")
    public Map<String, AcmeClubAccount> getAllAccounts() {
        return accounts;
    }
}