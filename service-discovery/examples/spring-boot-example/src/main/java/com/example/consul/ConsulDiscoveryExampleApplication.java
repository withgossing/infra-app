package com.example.consul;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * Consul Service Discovery 예제 애플리케이션
 * 
 * 이 애플리케이션은 다음과 같은 기능을 제공합니다:
 * - Consul에 자동 서비스 등록
 * - 다른 서비스 발견 및 호출
 * - 설정 관리 (KV Store)
 * - 헬스체크 및 모니터링
 */
@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients
public class ConsulDiscoveryExampleApplication {

    public static void main(String[] args) {
        SpringApplication.run(ConsulDiscoveryExampleApplication.class, args);
    }
}
