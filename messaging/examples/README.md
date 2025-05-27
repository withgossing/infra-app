# Apache Kafka 사용 예제

이 폴더는 Apache Kafka를 다양한 언어와 프레임워크에서 사용하는 예제들을 포함합니다.

## 📋 예제 목록

### 1. Spring Boot 통합
- Kafka Producer/Consumer 구현
- 트랜잭션 처리
- 에러 핸들링 및 재시도

### 2. Node.js 통합  
- KafkaJS 라이브러리 사용
- 스트리밍 처리
- 클러스터 관리

### 3. Python 통합
- kafka-python 라이브러리 사용
- 배치 처리
- 모니터링 및 메트릭

### 4. 성능 최적화
- 배치 크기 튜닝
- 압축 설정
- 파티셔닝 전략

## 🚀 빠른 시작

### Docker Compose 환경에서 테스트

1. **Kafka 클러스터 시작**
```bash
cd /Users/gossing/WorkPlace/infra-app/messaging
docker-compose up -d
```

2. **토픽 생성**
```bash
# 테스트 토픽 생성
docker exec -it kafka-1 kafka-topics.sh \
  --create \
  --topic test-events \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 3
```

3. **메시지 전송 (Producer)**
```bash
# 콘솔 프로듀서로 메시지 전송
docker exec -it kafka-1 kafka-console-producer.sh \
  --topic test-events \
  --bootstrap-server localhost:9092
```

4. **메시지 수신 (Consumer)**
```bash
# 콘솔 컨슈머로 메시지 수신
docker exec -it kafka-1 kafka-console-consumer.sh \
  --topic test-events \
  --bootstrap-server localhost:9092 \
  --from-beginning
```

### Kubernetes 환경에서 테스트

1. **Kafka 클러스터 배포**
```bash
kubectl apply -f k8s/
```

2. **Pod에서 토픽 생성**
```bash
kubectl exec -it kafka-0 -n messaging -- kafka-topics.sh \
  --create \
  --topic k8s-events \
  --bootstrap-server kafka-headless.messaging.svc.cluster.local:9092 \
  --partitions 3 \
  --replication-factor 3
```

## 🔧 설정 가이드

### 프로듀서 설정 (고성능)
```properties
# 처리량 최적화
batch.size=16384
linger.ms=5
compression.type=lz4
buffer.memory=33554432

# 안정성 최적화  
acks=all
retries=2147483647
max.in.flight.requests.per.connection=5
enable.idempotence=true
```

### 컨슈머 설정 (안정성)
```properties
# 자동 오프셋 커밋 비활성화
enable.auto.commit=false

# 세션 타임아웃 및 하트비트
session.timeout.ms=10000
heartbeat.interval.ms=3000

# 배치 처리
max.poll.records=500
fetch.min.bytes=1
fetch.max.wait.ms=500
```

## 📊 모니터링

### 주요 메트릭

#### 프로듀서 메트릭
- `record-send-rate`: 초당 전송 레코드 수
- `record-error-rate`: 초당 에러 레코드 수
- `request-latency-avg`: 평균 요청 지연시간

#### 컨슈머 메트릭
- `records-consumed-rate`: 초당 소비 레코드 수
- `records-lag-max`: 최대 컨슈머 랙
- `commit-latency-avg`: 평균 커밋 지연시간

#### 브로커 메트릭
- `MessagesInPerSec`: 초당 메시지 입력률
- `BytesInPerSec`: 초당 바이트 입력률
- `LeaderElectionRateAndTimeMs`: 리더 선출 비율

### Kafka UI 접속
- Docker: http://localhost:10703
- Kubernetes: kubectl port-forward -n messaging svc/kafka-ui 10703:8080

## 🧪 테스트 시나리오

### 1. 기본 메시지 전송/수신
```bash
# 프로듀서 테스트
echo "Hello Kafka" | docker exec -i kafka-1 kafka-console-producer.sh \
  --topic test-events --bootstrap-server localhost:9092

# 컨슈머 테스트
docker exec kafka-1 kafka-console-consumer.sh \
  --topic test-events --bootstrap-server localhost:9092 \
  --from-beginning --max-messages 1
```

### 2. 성능 테스트
```bash
# 100만 메시지 성능 테스트
docker exec kafka-1 kafka-producer-perf-test.sh \
  --topic performance-test \
  --num-records 1000000 \
  --record-size 1024 \
  --throughput 50000 \
  --producer-props bootstrap.servers=localhost:9092

# 컨슈머 성능 테스트
docker exec kafka-1 kafka-consumer-perf-test.sh \
  --topic performance-test \
  --messages 1000000 \
  --bootstrap-server localhost:9092
```

### 3. 고가용성 테스트
```bash
# 브로커 하나 중단
docker stop kafka-2

# 토픽 상태 확인 (리더 변경 확인)
docker exec kafka-1 kafka-topics.sh \
  --describe --topic test-events \
  --bootstrap-server localhost:9092

# 브로커 재시작
docker start kafka-2
```

## 🔐 보안 설정

### SSL/TLS 인증서 생성
```bash
cd config/ssl
./generate-ssl-certs.sh
```

### SASL 인증 설정
```properties
# server.properties에 추가
security.inter.broker.protocol=SASL_SSL
sasl.mechanism.inter.broker.protocol=SCRAM-SHA-512
sasl.enabled.mechanisms=SCRAM-SHA-512
```

## 🔧 문제 해결

### 일반적인 문제들

1. **Connection refused**
   - 브로커가 시작되었는지 확인
   - advertised.listeners 설정 확인
   - 네트워크 방화벽 규칙 확인

2. **메시지 손실**
   - acks=all 설정 확인
   - min.insync.replicas 확인
   - 복제 인수 확인

3. **높은 컨슈머 랙**
   - 컨슈머 처리 성능 확인
   - 파티션 수 늘리기 고려
   - 컨슈머 그룹 인스턴스 수 늘리기

4. **디스크 공간 부족**
   - 로그 보존 정책 확인
   - 압축 설정 확인
   - 로그 정리 설정 확인

### 로그 확인
```bash
# Docker 환경
docker logs kafka-1

# Kubernetes 환경
kubectl logs -n messaging kafka-0

# Kafka UI에서 에러 확인
curl http://localhost:10703/api/clusters/k8s-cluster/brokers
```

## 📚 참고 자료

- [Apache Kafka 공식 문서](https://kafka.apache.org/documentation/)
- [Kafka Streams 가이드](https://kafka.apache.org/documentation/streams/)
- [Schema Registry 가이드](https://docs.confluent.io/platform/current/schema-registry/)
- [Kafka Connect 가이드](https://kafka.apache.org/documentation/#connect)
