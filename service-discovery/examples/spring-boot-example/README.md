# Spring Boot + Consul Service Discovery 예제

이 예제는 Spring Boot 애플리케이션에서 Consul을 사용한 서비스 디스커버리 구현을 보여줍니다.

## 🎯 주요 기능

- **자동 서비스 등록**: 애플리케이션 시작 시 Consul에 자동 등록
- **서비스 발견**: 다른 서비스 인스턴스 조회 및 호출
- **로드밸런싱**: 여러 인스턴스 간 자동 로드밸런싱
- **헬스체크**: 주기적인 상태 확인
- **동적 설정**: Consul KV Store를 통한 설정 관리
- **설정 새로고침**: @RefreshScope를 통한 런타임 설정 변경

## 🏗️ 프로젝트 구조

```
spring-boot-example/
├── src/main/java/com/example/consul/
│   ├── ConsulDiscoveryExampleApplication.java  # 메인 애플리케이션
│   ├── DiscoveryController.java                # REST API 컨트롤러
│   └── AppConfig.java                          # 설정 클래스
├── src/main/resources/
│   └── application.yml                         # 애플리케이션 설정
├── Dockerfile                                  # Docker 이미지 빌드
├── docker-compose.yml                          # 멀티 인스턴스 테스트
└── pom.xml                                     # Maven 의존성
```

## 🚀 실행 방법

### 1. 전제 조건
- Java 17+
- Maven 3.6+
- Docker (선택사항)
- Consul 클러스터 실행 중

### 2. 로컬 실행
```bash
# 의존성 설치 및 컴파일
mvn clean compile

# 애플리케이션 실행
mvn spring-boot:run

# 또는 JAR 빌드 후 실행
mvn clean package
java -jar target/consul-discovery-example-1.0.0.jar
```

### 3. Docker로 실행
```bash
# 이미지 빌드
docker build -t consul-discovery-example .

# 컨테이너 실행
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=docker \
  --network consul-network \
  consul-discovery-example
```

### 4. Docker Compose로 멀티 인스턴스 실행
```bash
# Consul 네트워크가 실행 중인지 확인
docker network ls | grep consul-network

# 멀티 인스턴스 실행
docker-compose up -d

# 로그 확인
docker-compose logs -f
```

## 📚 API 엔드포인트

### 기본 정보
- `GET /api/info` - 애플리케이션 정보
- `GET /api/health` - 헬스체크 (커스텀)
- `GET /actuator/health` - Spring Actuator 헬스체크

### 서비스 디스커버리
- `GET /api/services` - 등록된 모든 서비스 목록
- `GET /api/services/{serviceName}` - 특정 서비스 인스턴스 정보
- `GET /api/instance` - 현재 인스턴스 정보

### 서비스 호출
- `GET /api/call/{serviceName}` - 다른 서비스 호출 예제

### 설정 관리
- `GET /api/config` - 현재 설정값 조회

## 🧪 테스트 시나리오

### 1. 서비스 등록 확인
```bash
# 등록된 서비스 목록 조회
curl http://localhost:8081/api/services

# 특정 서비스 인스턴스 조회
curl http://localhost:8081/api/services/consul-discovery-example
```

### 2. 서비스 간 통신 테스트
```bash
# 다른 인스턴스 호출
curl http://localhost:8081/api/call/consul-discovery-example

# API Gateway를 통한 호출
curl http://localhost:8083/api/call/consul-discovery-example
```

### 3. 로드밸런싱 테스트
```bash
# 여러 번 호출하여 다른 인스턴스로 분산되는지 확인
for i in {1..10}; do
  curl -s http://localhost:8081/api/call/consul-discovery-example | grep instance
done
```

### 4. 동적 설정 테스트
```bash
# Consul KV Store에 설정 추가
curl -X PUT http://localhost:10500/v1/kv/config/consul-discovery-example/data \
  -d 'app:
  message: "Consul에서 동적으로 읽은 메시지"
  version: "2.0.0"'

# 설정 새로고침 (Spring Boot Actuator)
curl -X POST http://localhost:8081/actuator/refresh

# 변경된 설정 확인
curl http://localhost:8081/api/config
```

## 🔧 설정 설명

### application.yml 주요 설정

```yaml
spring:
  cloud:
    consul:
      host: localhost
      port: 10500
      discovery:
        enabled: true                    # 서비스 디스커버리 활성화
        register: true                   # 자동 등록 활성화
        health-check-path: /actuator/health  # 헬스체크 경로
        health-check-interval: 10s       # 헬스체크 주기
        tags:                           # 서비스 태그
          - version=1.0.0
          - environment=development
```

### Maven 의존성

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-consul-discovery</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-consul-config</artifactId>
</dependency>
```

## 🔍 모니터링

### Consul UI
- URL: http://localhost:10500
- Services 탭에서 등록된 서비스 확인
- Nodes 탭에서 클러스터 상태 확인

### Spring Boot Actuator
- Health: http://localhost:8081/actuator/health
- Metrics: http://localhost:8081/actuator/metrics
- Info: http://localhost:8081/actuator/info

### 로그 모니터링
```bash
# Docker Compose 로그
docker-compose logs -f app-1

# 특정 컨테이너 로그
docker logs -f consul-app-1
```

## 🔧 문제 해결

### 일반적인 문제들

1. **Consul 연결 실패**
   ```
   org.springframework.cloud.consul.discovery.ConsulDiscoveryClientConfigServiceBootstrapConfiguration
   ```
   - Consul 서버가 실행 중인지 확인
   - 포트 및 호스트 설정 확인

2. **서비스 등록 실패**
   - 헬스체크 경로가 올바른지 확인
   - 애플리케이션이 완전히 시작된 후 등록되는지 확인

3. **로드밸런싱 동작 안함**
   - @LoadBalanced 어노테이션 확인
   - RestTemplate Bean 설정 확인

### 디버깅 설정
```yaml
logging:
  level:
    org.springframework.cloud.consul: DEBUG
    org.springframework.cloud.discovery: DEBUG
```

## 📝 확장 가능한 기능

- **Circuit Breaker**: Hystrix 또는 Resilience4j 통합
- **분산 트레이싱**: Sleuth + Zipkin 통합
- **보안**: Spring Security + OAuth2 통합
- **API Gateway**: Spring Cloud Gateway 통합
- **설정 암호화**: Consul Transit Secret Engine 사용
