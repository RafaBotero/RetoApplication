package com.acmeclub.accountservice;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AcmeClubController {

    @GetMapping("/acme")
    public String getAcmeClubInfo() {
        return "Welcome to AcmeClub!";
    }
}