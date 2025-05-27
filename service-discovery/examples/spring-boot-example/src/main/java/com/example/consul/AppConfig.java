package com.example.consul;

import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * 애플리케이션 설정 클래스
 */
@Configuration
public class AppConfig {

    /**
     * 로드밸런싱이 적용된 RestTemplate Bean
     * 
     * @LoadBalanced 어노테이션으로 인해 서비스 이름으로 호출할 때
     * 자동으로 로드밸런싱이 적용됩니다.
     */
    @Bean
    @LoadBalanced
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
