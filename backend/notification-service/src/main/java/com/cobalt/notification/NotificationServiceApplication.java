package com.cobalt.notification;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {"com.cobalt.notification", "com.cobalt.common"})
public class NotificationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(
            NotificationServiceApplication.class, args);
    }
}
