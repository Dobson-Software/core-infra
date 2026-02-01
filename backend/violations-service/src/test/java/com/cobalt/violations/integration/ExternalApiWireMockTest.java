package com.cobalt.violations.integration;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.web.client.RestClient;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ExternalApiWireMockTest extends AbstractIntegrationTest {

    @RegisterExtension
    static WireMockExtension wireMock = WireMockExtension.newInstance()
        .options(wireMockConfig().dynamicPort())
        .build();

    @DynamicPropertySource
    static void configureSocrataProperties(
            DynamicPropertyRegistry registry) {
        registry.add("socrata.base-url", wireMock::baseUrl);
    }

    @Test
    void socrataApiStubRespondsCorrectly() {
        String responseBody = """
            [
                {
                    "isn_dob_bis_viol": "V-TEST-001",
                    "boro": "MANHATTAN",
                    "bin": "1234567",
                    "violation_type": "BOILER"
                }
            ]
            """;

        wireMock.stubFor(
            get(urlPathEqualTo("/resource/3h2n-5cm9.json"))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type",
                        MediaType.APPLICATION_JSON_VALUE)
                    .withBody(responseBody)));

        RestClient client = RestClient.create(wireMock.baseUrl());
        String result = client.get()
            .uri("/resource/3h2n-5cm9.json")
            .retrieve()
            .body(String.class);

        assertThat(result).contains("V-TEST-001");
        assertThat(result).contains("MANHATTAN");
        assertThat(result).contains("BOILER");
    }
}
