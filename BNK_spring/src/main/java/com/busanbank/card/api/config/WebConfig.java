package com.busanbank.card.api.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.*;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**") // 모든 경로에 대해
                .allowedOrigins("*") // 모든 origin 허용
                .allowedMethods("*") // GET, POST, PUT, DELETE 등 허용
                .allowedHeaders("*") // 모든 헤더 허용
                .allowCredentials(false); // 쿠키 인증 등은 false
    }
}
