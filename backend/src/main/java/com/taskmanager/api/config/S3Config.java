package com.taskmanager.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class S3Config {
    @Bean(destroyMethod = "close")
    S3Presigner s3Presigner(@Value("${app.storage.region}") String region) {
        // Credentials are intentionally omitted. The SDK resolves an AWS profile,
        // environment credentials, or the IAM role attached to the deployment.
        return S3Presigner.builder()
            .region(Region.of(region))
            .build();
    }
}
