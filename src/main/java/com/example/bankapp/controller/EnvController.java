package com.example.bankapp.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class EnvController {

    @Value("${APP_COLOR:UNKNOWN}")
    private String color;

    @GetMapping("/env")
    public String env() {
        return color;
    }
}
