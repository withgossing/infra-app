# Kong API Gateway

Kong은 마이크로서비스를 위한 클라우드 네이티브 API 게이트웨이입니다. 이 설정은 PostgreSQL을 데이터베이스로 사용하며 로컬 개발 및 Kubernetes 환경을 모두 지원합니다.

## 포트 할당

- **10000**: HTTP Gateway (외부 노출)
- **10001**: HTTPS Gateway (외부 노출)
- **8001**: Admin API HTTP (내부용)
- **8444**: Admin API HTTPS (내부용)

## 로컬 개발 환경 (Docker Compose)

### 시작하기

```bash
# Kong 및 PostgreSQL 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f kong

# 헬스체크 확인
curl http://localhost:8001/status

# 서비스 중지
docker-compose down
```

### Kong 설정 확인

```bash
# Kong 상태 확인
curl http://localhost:8001/status

# Kong 정보 확인
curl http://localhost:8001/

# 플러그인 목록 확인
curl http://localhost:8001/plugins/enabled
```

## Kubernetes 환경

### 배포하기

```bash
# 네임스페이스 및 설정 생성
kubectl apply -f k8s/01-namespace-config.yaml

# PostgreSQL 배포
kubectl apply -f k8s/02-postgres.yaml

# PostgreSQL이 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n kong-system

# Kong 마이그레이션 및 서비스 배포
kubectl apply -f k8s/03-kong.yaml

# Kong이 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/kong -n kong-system
```

### 상태 확인

```bash
# 모든 리소스 상태 확인
kubectl get all -n kong-system

# Kong 로그 확인
kubectl logs -f deployment/kong -n kong-system

# Kong Admin API 접근 (포트 포워딩)
kubectl port-forward svc/kong-admin 8001:8001 -n kong-system

# 헬스체크 (다른 터미널에서)
curl http://localhost:8001/status
```

### 정리하기

```bash
# 모든 Kong 리소스 삭제
kubectl delete namespace kong-system
```

## Kong 관리

### 서비스 등록

```bash
# 서비스 생성
curl -X POST http://localhost:8001/services \
  --data "name=example-service" \
  --data "url=http://example.com"

# 라우트 생성
curl -X POST http://localhost:8001/services/example-service/routes \
  --data "hosts[]=example.local"
```

### 플러그인 설정

```bash
# Rate Limiting 플러그인 추가
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=100" \
  --data "config.hour=1000"

# Key Authentication 플러그인 추가
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=key-auth"
```

### 소비자 관리

```bash
# 소비자 생성
curl -X POST http://localhost:8001/consumers \
  --data "username=example-user"

# API 키 생성
curl -X POST http://localhost:8001/consumers/example-user/key-auth \
  --data "key=my-api-key"
```

## 모니터링

### 메트릭 수집

Kong은 다양한 메트릭을 제공하며, Prometheus 플러그인을 통해 메트릭을 노출할 수 있습니다.

```bash
# Prometheus 플러그인 활성화
curl -X POST http://localhost:8001/plugins \
  --data "name=prometheus"

# 메트릭 확인
curl http://localhost:8001/metrics
```

### 로깅

Kong의 모든 로그는 stdout/stderr로 출력되며, 중앙화된 로깅 시스템으로 수집할 수 있습니다.

## 보안 설정

### HTTPS 설정

```bash
# SSL 인증서 업로드
curl -X POST http://localhost:8001/certificates \
  --form "cert=@/path/to/cert.pem" \
  --form "key=@/path/to/key.pem"

# SNI 설정
curl -X POST http://localhost:8001/snis \
  --data "name=example.com" \
  --data "certificate.id=<certificate-id>"
```

### 보안 플러그인

```bash
# CORS 플러그인
curl -X POST http://localhost:8001/plugins \
  --data "name=cors" \
  --data "config.origins=*" \
  --data "config.methods=GET,POST,PUT,DELETE" \
  --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token"

# IP Restriction 플러그인
curl -X POST http://localhost:8001/plugins \
  --data "name=ip-restriction" \
  --data "config.allow=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
```

## 문제 해결

### 일반적인 문제

1. **Kong이 시작되지 않는 경우**
   - PostgreSQL이 준비되었는지 확인
   - 마이그레이션이 성공했는지 확인
   - 로그에서 오류 메시지 확인

2. **Admin API에 접근할 수 없는 경우**
   - Admin API 리스너 설정 확인
   - 방화벽 설정 확인
   - 네트워크 연결 확인

3. **프록시가 작동하지 않는 경우**
   - 서비스와 라우트 설정 확인
   - 업스트림 서비스 상태 확인
   - Kong 프록시 로그 확인

### 유용한 명령어

```bash
# Kong 설정 확인
kong config -c /etc/kong/kong.conf

# Kong 설정 검증
kong check /etc/kong/kong.conf

# Kong 재로드 (무중단)
kong reload

# Kong 상태 확인
kong health
```

## 참고 자료

- [Kong 공식 문서](https://docs.konghq.com/)
- [Kong Admin API 문서](https://docs.konghq.com/gateway/api/)
- [Kong 플러그인 허브](https://docs.konghq.com/hub/)
- [Kong Kubernetes 가이드](https://docs.konghq.com/kubernetes-ingress-controller/)
