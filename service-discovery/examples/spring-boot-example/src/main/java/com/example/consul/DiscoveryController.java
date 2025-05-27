package com.example.consul;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 서비스 디스커버리 및 설정 관리 데모 컨트롤러
 */
@RestController
@RequestMapping("/api")
@RefreshScope
public class DiscoveryController {

    @Autowired
    private DiscoveryClient discoveryClient;

    @Autowired
    private RestTemplate restTemplate;

    // Consul KV Store에서 동적으로 설정을 읽어옴
    @Value("${app.message:기본 메시지}")
    private String message;

    @Value("${app.version:1.0.0}")
    private String version;

    /**
     * 애플리케이션 정보 반환
     */
    @GetMapping("/info")
    public Map<String, Object> getInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("application", "consul-discovery-example");
        info.put("version", version);
        info.put("message", message);
        info.put("timestamp", LocalDateTime.now());
        return info;
    }

    /**
     * 등록된 모든 서비스 목록 조회
     */
    @GetMapping("/services")
    public List<String> getServices() {
        return discoveryClient.getServices();
    }

    /**
     * 특정 서비스의 인스턴스 정보 조회
     */
    @GetMapping("/services/{serviceName}")
    public List<ServiceInstance> getServiceInstances(@PathVariable String serviceName) {
        return discoveryClient.getInstances(serviceName);
    }

    /**
     * 다른 서비스 호출 예제
     */
    @GetMapping("/call/{serviceName}")
    public Map<String, Object> callService(@PathVariable String serviceName) {
        List<ServiceInstance> instances = discoveryClient.getInstances(serviceName);
        
        if (instances.isEmpty()) {
            Map<String, Object> result = new HashMap<>();
            result.put("error", "서비스 '" + serviceName + "'을 찾을 수 없습니다.");
            return result;
        }

        ServiceInstance instance = instances.get(0); // 첫 번째 인스턴스 사용
        String url = String.format("http://%s:%d/api/info", 
                                   instance.getHost(), 
                                   instance.getPort());
        
        try {
            Map<String, Object> response = restTemplate.getForObject(url, Map.class);
            Map<String, Object> result = new HashMap<>();
            result.put("called_service", serviceName);
            result.put("instance", String.format("%s:%d", instance.getHost(), instance.getPort()));
            result.put("response", response);
            return result;
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("error", "서비스 호출 실패: " + e.getMessage());
            result.put("service_url", url);
            return result;
        }
    }

    /**
     * 현재 인스턴스 정보 조회
     */
    @GetMapping("/instance")
    public Map<String, Object> getCurrentInstance() {
        List<ServiceInstance> instances = discoveryClient.getInstances("consul-discovery-example");
        Map<String, Object> result = new HashMap<>();
        result.put("service_name", "consul-discovery-example");
        result.put("instances_count", instances.size());
        result.put("instances", instances);
        return result;
    }

    /**
     * 헬스체크 엔드포인트 (커스텀)
     */
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now());
        health.put("service", "consul-discovery-example");
        health.put("version", version);
        return health;
    }

    /**
     * 설정 테스트 엔드포인트
     */
    @GetMapping("/config")
    public Map<String, Object> getConfig() {
        Map<String, Object> config = new HashMap<>();
        config.put("message", message);
        config.put("version", version);
        config.put("note", "이 값들은 Consul KV Store에서 동적으로 읽어옵니다.");
        return config;
    }
}
