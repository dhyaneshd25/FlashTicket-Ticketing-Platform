package com.flashticket.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Maps /static/** URLs used by the JSP views to classpath:/static/ so CSS/JS
 * resolve correctly under the JSP + WAR setup (Spring Boot's default static
 * resource handling still applies, this just makes the mapping explicit).
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/static/**")
                .addResourceLocations("classpath:/static/");
    }
}
