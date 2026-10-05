package com.flashticket.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

import org.springframework.boot.autoconfigure.kafka.KafkaProperties;
import org.springframework.kafka.core.KafkaAdmin;

/**
 * Declares the Kafka topics FlashTicket depends on. In production these
 * would be managed by Schema Registry + a GitOps topic-config repo; here
 * Spring Boot auto-creates them on startup for local development.
 */
@Configuration
public class KafkaTopicConfig {

    @Value("${flashticket.kafka.topics.order-created}")
    private String orderCreatedTopic;

    @Value("${flashticket.kafka.topics.payment-confirmed}")
    private String paymentConfirmedTopic;

    @Value("${flashticket.kafka.topics.notification}")
    private String notificationTopic;

    @Bean
    public KafkaAdmin kafkaAdmin(KafkaProperties properties) {
        KafkaAdmin admin = new KafkaAdmin(properties.buildAdminProperties());
        admin.setFatalIfBrokerNotAvailable(false);
        admin.setOperationTimeout(3);
        return admin;
    }

    @Bean
    public NewTopic orderCreatedTopic() {
        // Partitioned so ordering per-event (concert/show) is preserved,
        // while different shows process in parallel.
        return TopicBuilder.name(orderCreatedTopic).partitions(6).replicas(1).build();
    }

    @Bean
    public NewTopic paymentConfirmedTopic() {
        return TopicBuilder.name(paymentConfirmedTopic).partitions(6).replicas(1).build();
    }

    @Bean
    public NewTopic notificationTopic() {
        return TopicBuilder.name(notificationTopic).partitions(3).replicas(1).build();
    }
}
