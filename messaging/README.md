# Messaging - Apache Kafka

Apache Kafka 기반의 고성능 분산 스트리밍 플랫폼입니다.

## ✨ 주요 기능

- **높은 처리량**: 초당 수백만 메시지 처리 가능
- **고가용성**: 3개 브로커로 구성된 클러스터
- **내구성**: 메시지 복제 및 지속성 보장
- **확장성**: 수평 확장 가능한 아키텍처
- **실시간**: 낮은 지연시간의 스트리밍 처리
- **KRaft 모드**: Zookeeper 없이 자체 메타데이터 관리

## 🌐 접속 정보

### Docker Compose 환경
- **Kafka Broker 1**: localhost:10700
- **Kafka Broker 2**: localhost:10701
- **Kafka Broker 3**: localhost:10702
- **Kafka UI**: http://localhost:10703
- **Schema Registry**: http://localhost:10704

### Kubernetes 환경
- **Kafka Service**: kafka.messaging.svc.cluster.local:9092
- **Kafka UI**: http://kafka-ui.messaging.svc.cluster.local:8080

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kafka-1       │    │   Kafka-2       │    │   Kafka-3       │
│   (Controller)  │◄──►│   (Broker)      │◄──►│   (Broker)      │
│   포트: 10700    │    │   포트: 10701    │    │   포트: 10702    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Kafka UI      │
                    │   포트: 10703    │
                    └─────────────────┘
```

## 🚀 시작하기

### Docker Compose로 실행
```bash
cd /Users/gossing/WorkPlace/infra-app/messaging
docker-compose up -d
```

### Kubernetes로 실행
```bash
kubectl apply -f k8s/
```

## 📝 기본 사용법

### 토픽 생성
```bash
# Docker 환경
docker exec -it kafka-1 kafka-topics.sh \
  --create \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 3

# 로컬 Kafka 클라이언트 사용
kafka-topics.sh \
  --create \
  --topic my-topic \
  --bootstrap-server localhost:10700 \
  --partitions 3 \
  --replication-factor 3
```

### 메시지 프로듀싱
```bash
# Docker 환경
docker exec -it kafka-1 kafka-console-producer.sh \
  --topic my-topic \
  --bootstrap-server localhost:9092

# 로컬 환경
kafka-console-producer.sh \
  --topic my-topic \
  --bootstrap-server localhost:10700
```

### 메시지 컨슈밍
```bash
# Docker 환경
docker exec -it kafka-1 kafka-console-consumer.sh \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --from-beginning

# 로컬 환경
kafka-console-consumer.sh \
  --topic my-topic \
  --bootstrap-server localhost:10700 \
  --from-beginning
```

## 🔧 설정 옵션

### 클러스터 설정
- **브로커 수**: 3개 (고가용성)
- **복제 인수**: 3 (데이터 안정성)
- **파티션 수**: 토픽당 3개 (기본값)
- **세그먼트 크기**: 1GB
- **로그 보존**: 7일

### 성능 튜닝
- **배치 크기**: 16KB
- **압축**: lz4 (기본값)
- **플러시 간격**: 10000 메시지 또는 1초
- **소켓 버퍼**: 102400

## 📊 모니터링

### Kafka UI
- **접속**: http://localhost:10703
- **기능**: 토픽, 브로커, 컨슈머 그룹 모니터링

### JMX 메트릭
- **포트**: 9999 (각 브로커)
- **Prometheus 연동**: JMX Exporter 사용

### 주요 메트릭
- `kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec`
- `kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec`
- `kafka.controller:type=KafkaController,name=OfflinePartitionsCount`

## 🔐 보안 설정

### SSL/TLS (선택사항)
```bash
# 인증서 생성 (개발용)
cd config/ssl
./generate-ssl-certs.sh
```

### SASL 인증 (선택사항)
- **메커니즘**: SCRAM-SHA-512
- **사용자 관리**: kafka-configs.sh 사용

## 🧪 테스트 시나리오

### 성능 테스트
```bash
# 프로듀서 성능 테스트
kafka-producer-perf-test.sh \
  --topic performance-test \
  --num-records 1000000 \
  --record-size 1024 \
  --throughput 50000 \
  --producer-props bootstrap.servers=localhost:10700

# 컨슈머 성능 테스트
kafka-consumer-perf-test.sh \
  --topic performance-test \
  --messages 1000000 \
  --bootstrap-server localhost:10700
```

### 고가용성 테스트
```bash
# 브로커 중단 테스트
docker stop kafka-2

# 리더십 변경 확인
kafka-topics.sh --describe --topic my-topic --bootstrap-server localhost:10700
```

## 📚 통합 예제

### Spring Boot 통합
```yaml
spring:
  kafka:
    bootstrap-servers: localhost:10700,localhost:10701,localhost:10702
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.JsonSerializer
    consumer:
      group-id: my-consumer-group
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.JsonDeserializer
```

### Node.js 통합
```javascript
const kafka = require('kafkajs');

const client = kafka({
  clientId: 'my-app',
  brokers: ['localhost:10700', 'localhost:10701', 'localhost:10702']
});

const producer = client.producer();
const consumer = client.consumer({ groupId: 'my-group' });
```

## 🔧 문제 해결

### 일반적인 문제들

1. **브로커 연결 실패**
   - 네트워크 연결성 확인
   - 포트 방화벽 설정 확인
   - advertised.listeners 설정 확인

2. **메시지 손실**
   - acks=all 설정 확인
   - min.insync.replicas 설정 확인
   - 복제 인수 확인

3. **파티션 불균형**
   - 토픽 재분산 실행
   - 브로커 부하 모니터링

### 로그 확인
```bash
# Docker 환경
docker logs kafka-1

# Kubernetes 환경
kubectl logs -n messaging kafka-0
```
