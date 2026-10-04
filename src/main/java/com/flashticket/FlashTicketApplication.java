package com.flashticket;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * FlashTicket - High-Throughput Event Ticketing & Flash Sale Platform.
 *
 * Packaged as a WAR (not the default JAR) purely so the embedded Tomcat
 * container can compile and serve JSPs under src/main/webapp. It still runs
 * the same way: `mvn spring-boot:run` or `java -jar/-war target/flashticket.war`.
 */
@SpringBootApplication
@EnableScheduling // powers the Outbox relay poller
public class FlashTicketApplication extends SpringBootServletInitializer {

    public static void main(String[] args) {
        SpringApplication.run(FlashTicketApplication.class, args);
    }

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(FlashTicketApplication.class);
    }
}
