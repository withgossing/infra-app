# Redis 캐시 클러스터

Redis는 인메모리 데이터 구조 저장소로, 캐시, 메시지 브로커, 데이터베이스로 사용됩니다. 이 설정은 고가용성을 위한 Master-Replica 구조와 Redis Sentinel을 포함합니다.

## 포트 할당

- **10007**: Redis Master (외부 노출)
- **6379**: Redis 기본 포트 (내부)
- **26379**: Redis Sentinel 포트

## 아키텍처

- **Redis Master**: 쓰기 작업을 처리하는 주 서버
- **Redis Replica**: 읽기 작업을 처리하는 복제 서버 (2개)
- **Redis Sentinel**: 자동 장애조치를 위한 모니터링 서비스 (3개)

## 로컬 개발 환경 (Docker Compose)

### 시작하기

```bash
# Redis 클러스터 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f redis-master

# Redis 연결 테스트
docker exec -it redis-master redis-cli -a redis_password ping

# 클러스터 중지
docker-compose down
```

### Redis 명령어 테스트

```bash
# Master에 데이터 쓰기
docker exec -it redis-master redis-cli -a redis_password
> SET test:key "Hello Redis"
> GET test:key

# Replica에서 데이터 읽기
docker exec -it redis-replica-1 redis-cli -a redis_password
> GET test:key

# Sentinel 상태 확인
docker exec -it redis-sentinel-1 redis-cli -p 26379 -a redis_password
> SENTINEL masters
> SENTINEL replicas mymaster
```

## Kubernetes 환경

### 배포하기

```bash
# 네임스페이스 및 설정 생성
kubectl apply -f k8s/01-namespace-config.yaml

# Redis 클러스터 배포
kubectl apply -f k8s/02-redis-cluster.yaml

# Redis Master가 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/redis-master -n redis-system

# Redis Sentinel 배포
kubectl apply -f k8s/03-redis-sentinel.yaml

# 모든 파드가 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/redis-replica -n redis-system
kubectl wait --for=condition=available --timeout=300s deployment/redis-sentinel -n redis-system
```

### 상태 확인

```bash
# 모든 리소스 상태 확인
kubectl get all -n redis-system

# Redis Master 로그 확인
kubectl logs -f deployment/redis-master -n redis-system

# Redis 연결 테스트 (포트 포워딩)
kubectl port-forward svc/redis-master 6379:6379 -n redis-system

# 다른 터미널에서 테스트
redis-cli -h localhost -p 6379 -a redis_password ping
```

### 정리하기

```bash
# 모든 Redis 리소스 삭제
kubectl delete namespace redis-system
```

## Redis 사용법

### 기본 명령어

```bash
# 키-값 저장
SET mykey "myvalue"

# 값 조회
GET mykey

# 키 존재 확인
EXISTS mykey

# 키 삭제
DEL mykey

# 모든 키 조회
KEYS *

# 키 만료 시간 설정 (초)
EXPIRE mykey 60

# 남은 생존 시간 확인
TTL mykey
```

### 데이터 타입별 명령어

#### 해시 (Hash)
```bash
# 해시 필드 설정
HSET user:1 name "John" age 30 city "Seoul"

# 해시 필드 조회
HGET user:1 name

# 모든 해시 필드 조회
HGETALL user:1

# 해시 필드 삭제
HDEL user:1 age
```

#### 리스트 (List)
```bash
# 리스트 앞쪽에 추가
LPUSH queue "task1" "task2"

# 리스트 뒤쪽에 추가
RPUSH queue "task3"

# 리스트 앞쪽에서 제거
LPOP queue

# 리스트 길이 확인
LLEN queue

# 리스트 범위 조회
LRANGE queue 0 -1
```

#### 세트 (Set)
```bash
# 세트에 멤버 추가
SADD tags "redis" "cache" "database"

# 세트 멤버 확인
SISMEMBER tags "redis"

# 모든 멤버 조회
SMEMBERS tags

# 세트 크기 확인
SCARD tags
```

#### 정렬된 세트 (Sorted Set)
```bash
# 스코어와 함께 멤버 추가
ZADD leaderboard 100 "player1" 85 "player2" 95 "player3"

# 순위별 조회 (낮은 스코어부터)
ZRANGE leaderboard 0 -1 WITHSCORES

# 순위별 조회 (높은 스코어부터)
ZREVRANGE leaderboard 0 -1 WITHSCORES

# 특정 멤버의 순위 확인
ZRANK leaderboard "player1"
```

## 고급 기능

### Pub/Sub 메시징

```bash
# 채널 구독 (터미널 1)
SUBSCRIBE news

# 메시지 발행 (터미널 2)
PUBLISH news "Breaking news!"

# 패턴 구독
PSUBSCRIBE news:*
PUBLISH news:sports "Football match result"
```

### 트랜잭션

```bash
# 트랜잭션 시작
MULTI

# 명령어 큐잉
SET key1 "value1"
SET key2 "value2"
INCR counter

# 트랜잭션 실행
EXEC

# 트랜잭션 취소
DISCARD
```

### 파이프라인 (배치 처리)

```bash
# Python 예제
import redis

r = redis.Redis(host='localhost', port=6379, password='redis_password')

# 파이프라인 생성
pipe = r.pipeline()

# 여러 명령어 추가
pipe.set('key1', 'value1')
pipe.set('key2', 'value2')
pipe.get('key1')
pipe.get('key2')

# 배치 실행
results = pipe.execute()
print(results)  # [True, True, b'value1', b'value2']
```

## 모니터링

### Redis 정보 확인

```bash
# 서버 정보
INFO server

# 메모리 사용량
INFO memory

# 복제 상태
INFO replication

# 클라이언트 연결
INFO clients

# 키스페이스 정보
INFO keyspace
```

### 성능 모니터링

```bash
# 실시간 명령어 모니터링
MONITOR

# 슬로우 쿼리 로그 확인
SLOWLOG GET 10

# 현재 실행 중인 명령어
CLIENT LIST

# 메모리 사용량 분석
MEMORY USAGE mykey
```

### Sentinel 모니터링

```bash
# Sentinel에 연결
redis-cli -p 26379 -a redis_password

# 마스터 정보 확인
SENTINEL masters

# 복제본 정보 확인
SENTINEL replicas mymaster

# Sentinel 정보 확인
SENTINEL sentinels mymaster

# 마스터 주소 확인
SENTINEL get-master-addr-by-name mymaster
```

## 장애조치 테스트

### 수동 페일오버

```bash
# Sentinel을 통한 수동 페일오버
SENTINEL failover mymaster
```

### 마스터 다운 시뮬레이션

```bash
# Docker Compose 환경에서 마스터 중지
docker stop redis-master

# Sentinel 로그 확인
docker logs redis-sentinel-1

# 새로운 마스터 확인
docker exec -it redis-sentinel-1 redis-cli -p 26379 -a redis_password
> SENTINEL get-master-addr-by-name mymaster
```

## 백업 및 복구

### RDB 백업

```bash
# 즉시 백업 생성
BGSAVE

# 백업 상태 확인
LASTSAVE

# 백업 파일 복사
docker cp redis-master:/data/dump.rdb ./backup/
```

### AOF 백업

```bash
# AOF 재작성
BGREWRITEAOF

# AOF 파일 백업
docker cp redis-master:/data/appendonly.aof ./backup/
```

## 성능 최적화

### 메모리 최적화

```bash
# 메모리 정책 설정
CONFIG SET maxmemory-policy allkeys-lru

# 메모리 사용량 확인
MEMORY USAGE mykey

# 만료된 키 정리
FLUSHDB
```

### 연결 최적화

```bash
# 연결 풀 설정 (애플리케이션에서)
# - 최대 연결 수 제한
# - 연결 타임아웃 설정
# - 유휴 연결 정리

# 현재 연결 수 확인
INFO clients
```

## 보안 설정

### 접근 제어

```bash
# 사용자 생성 (Redis 6.0+)
ACL SETUSER myuser on >mypassword ~cached:* +get +set

# 사용자 목록 확인
ACL LIST

# 현재 사용자 확인
ACL WHOAMI
```

### 네트워크 보안

```bash
# 바인드 주소 제한
bind 127.0.0.1 10.0.0.1

# 보호 모드 활성화
protected-mode yes

# 비밀번호 설정
requirepass strong_password
```

## 문제 해결

### 일반적인 문제

1. **연결 실패**
   - 비밀번호 확인
   - 네트워크 연결 확인
   - 방화벽 설정 확인

2. **메모리 부족**
   - maxmemory 설정 확인
   - 만료 정책 확인
   - 불필요한 키 정리

3. **복제 지연**
   - 네트워크 대역폭 확인
   - 마스터 로드 확인
   - 복제 백로그 크기 조정

### 로그 분석

```bash
# Docker 환경에서 로그 확인
docker logs redis-master
docker logs redis-replica-1
docker logs redis-sentinel-1

# Kubernetes 환경에서 로그 확인
kubectl logs deployment/redis-master -n redis-system
kubectl logs deployment/redis-replica -n redis-system
kubectl logs deployment/redis-sentinel -n redis-system
```

## 참고 자료

- [Redis 공식 문서](https://redis.io/documentation)
- [Redis 명령어 레퍼런스](https://redis.io/commands)
- [Redis Sentinel 가이드](https://redis.io/docs/management/sentinel/)
- [Redis 클러스터 가이드](https://redis.io/docs/management/scaling/)
- [Redis 모니터링 가이드](https://redis.io/docs/management/optimization/)
