package com.example.Hello;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
    @GetMapping("")
    public String None(){
        return "OKOKOKOKOKOKOKOK webhook";
    }
    @GetMapping("/hello")
    public String Hello(){
        return "Hello Jenkins";
    }
}
