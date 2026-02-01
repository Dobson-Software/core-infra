package com.cobalt.notification.integration;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.icegreen.greenmail.configuration.GreenMailConfiguration;
import com.icegreen.greenmail.junit5.GreenMailExtension;
import com.icegreen.greenmail.util.ServerSetupTest;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class MailConfigIntegrationTest extends AbstractIntegrationTest {

    @RegisterExtension
    static GreenMailExtension greenMail = new GreenMailExtension(
            ServerSetupTest.SMTP)
        .withConfiguration(
            GreenMailConfiguration.aConfig()
                .withDisabledAuthentication());

    @DynamicPropertySource
    static void configureMailProperties(
            DynamicPropertyRegistry registry) {
        registry.add("spring.mail.host", () -> "localhost");
        registry.add("spring.mail.port",
            () -> ServerSetupTest.SMTP.getPort());
    }

    @Autowired
    private JavaMailSender javaMailSender;

    @Test
    void javaMailSenderBeanIsPresent() {
        assertThat(javaMailSender).isNotNull();
    }

    @Test
    void sendSimpleEmailAndReceiveViaGreenMail() throws Exception {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom("noreply@cobalt.com");
        message.setTo("customer@example.com");
        message.setSubject("Test Notification");
        message.setText("Your HVAC service is scheduled.");

        javaMailSender.send(message);

        MimeMessage[] received = greenMail.getReceivedMessages();
        assertThat(received).hasSize(1);
        assertThat(received[0].getSubject())
            .isEqualTo("Test Notification");
    }
}
