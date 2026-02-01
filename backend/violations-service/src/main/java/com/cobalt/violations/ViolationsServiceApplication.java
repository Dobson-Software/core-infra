package com.cobalt.violations;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {"com.cobalt.violations", "com.cobalt.common"})
public class ViolationsServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(
            ViolationsServiceApplication.class, args);
    }
}
