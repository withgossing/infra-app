# Consul Service Discovery 사용 예제

이 폴더는 Consul을 사용한 서비스 디스커버리 구현 예제들을 포함합니다.

## 📋 예제 목록

### 1. 기본 서비스 등록 및 발견
- REST API를 통한 서비스 등록
- DNS를 통한 서비스 발견
- 헬스체크 구성

### 2. 마이크로서비스 통신
- Spring Boot + Consul 통합
- Node.js + Consul 통합
- Python + Consul 통합

### 3. 설정 관리
- KV 스토어를 이용한 중앙 설정 관리
- 동적 설정 업데이트

### 4. Service Mesh (Consul Connect)
- 서비스 간 mTLS 통신
- 트래픽 라우팅 및 로드밸런싱

## 🚀 빠른 시작

### 1. 서비스 등록 (REST API)
```bash
curl -X PUT http://localhost:10500/v1/agent/service/register \
  -d '{
    "ID": "web-01",
    "Name": "web",
    "Tags": ["v1", "primary"],
    "Address": "192.168.1.100",
    "Port": 8080,
    "Check": {
      "HTTP": "http://192.168.1.100:8080/health",
      "Interval": "10s"
    }
  }'
```

### 2. 서비스 발견 (DNS)
```bash
# A 레코드 조회
dig @localhost -p 10600 web.service.consul

# SRV 레코드 조회 (포트 정보 포함)
dig @localhost -p 10600 web.service.consul SRV
```

### 3. 서비스 발견 (HTTP API)
```bash
# 건강한 서비스 인스턴스만 조회
curl http://localhost:10500/v1/health/service/web?passing

# 모든 서비스 인스턴스 조회
curl http://localhost:10500/v1/catalog/service/web
```

### 4. KV 스토어 사용
```bash
# 값 저장
curl -X PUT http://localhost:10500/v1/kv/config/database/host \
  -d 'db.example.com'

# 값 조회
curl http://localhost:10500/v1/kv/config/database/host?raw

# 재귀적 조회
curl http://localhost:10500/v1/kv/config/?recurse
```

## 🏗️ 실제 구현 예제

각 언어별 실제 구현 예제는 다음 파일들을 참조하세요:

- `spring-boot-example/`: Spring Boot + Spring Cloud Consul
- `nodejs-example/`: Node.js + consul 라이브러리
- `python-example/`: Python + python-consul
- `docker-compose-example/`: Docker Compose 멀티 서비스 예제
- `kubernetes-example/`: Kubernetes 네이티브 통합 예제

## 📊 모니터링 및 관찰

### Consul UI 접속
- Docker Compose: http://localhost:10500
- Kubernetes: kubectl port-forward -n consul svc/consul-ui 10500:10500

### 주요 확인사항
1. **클러스터 상태**: Members 탭에서 모든 노드가 alive 상태인지 확인
2. **서비스 상태**: Services 탭에서 등록된 서비스들의 헬스체크 상태 확인
3. **KV 스토어**: Key/Value 탭에서 저장된 설정값들 확인
4. **노드 상태**: Nodes 탭에서 각 노드의 상태 및 메타데이터 확인

## 🔧 문제 해결

### 일반적인 문제들

1. **서비스가 등록되지 않음**
   - Consul 에이전트가 실행 중인지 확인
   - 네트워크 연결성 확인
   - 등록 요청의 JSON 형식 확인

2. **헬스체크 실패**
   - 헬스체크 엔드포인트가 올바른지 확인
   - 타임아웃 설정 조정
   - 네트워크 방화벽 규칙 확인

3. **DNS 조회 실패**
   - DNS 포트(8600)가 열려있는지 확인
   - DNS 질의 형식이 올바른지 확인 (*.service.consul)

4. **클러스터 분할 (Split Brain)**
   - 네트워크 파티션 상황 확인
   - Raft 로그 상태 점검
   - 필요시 클러스터 재구성

### 로그 확인
```bash
# Docker Compose 환경
docker logs consul-server-1

# Kubernetes 환경  
kubectl logs -n consul consul-server-0
```
