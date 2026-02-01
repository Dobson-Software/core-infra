package com.cobalt.common.test;

import java.util.UUID;

public final class TestFixtures {

    public static final UUID DEMO_TENANT_ID =
        UUID.fromString("00000000-0000-0000-0000-000000000001");
    public static final String DEMO_ADMIN_EMAIL = "admin@demo.com";
    public static final String DEMO_PASSWORD = "password123";
    public static final String DEMO_TENANT_SLUG = "demo";

    public static final String JWT_SECRET =
        "dGVzdC1qd3Qtc2VjcmV0LWtleS1mb3ItY29iYWx0LXBsYXRmb3JtLXRlc3RpbmctMjAyNS1tdXN0LWJlLTI1Ni1iaXRz";

    private TestFixtures() {
    }

    public static UUID randomTenantId() {
        return UUID.randomUUID();
    }

    public static UUID randomUserId() {
        return UUID.randomUUID();
    }
}
