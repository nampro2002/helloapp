package com.example.Hello;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
    @GetMapping("")
    public String None(){
        return "Spring application test Jenkins";
    }
    @GetMapping("/hello")
    public String Hello(){
        return "Hello Jenkins";
    }
}
