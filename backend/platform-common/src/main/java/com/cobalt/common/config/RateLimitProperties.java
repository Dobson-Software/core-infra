package com.cobalt.common.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "cobalt.rate-limit")
public record RateLimitProperties(
    Auth auth,
    Tenant tenant
) {

    public RateLimitProperties {
        if (auth == null) {
            auth = new Auth(10, 5);
        }
        if (tenant == null) {
            tenant = new Tenant(1000);
        }
    }

    public record Auth(int loginPerMinute, int registerPerMinute) {

        public Auth {
            if (loginPerMinute <= 0) {
                loginPerMinute = 10;
            }
            if (registerPerMinute <= 0) {
                registerPerMinute = 5;
            }
        }
    }

    public record Tenant(int requestsPerMinute) {

        public Tenant {
            if (requestsPerMinute <= 0) {
                requestsPerMinute = 1000;
            }
        }
    }
}
