# Service Discovery - Consul

HashiCorp Consul 기반의 서비스 디스커버리 및 설정 관리 시스템입니다.

## ✨ 주요 기능

- **서비스 디스커버리**: 동적 서비스 등록 및 발견
- **헬스체크**: 서비스 상태 모니터링 및 자동 장애조치
- **KV 스토어**: 분산 설정 관리
- **Service Mesh**: Consul Connect를 통한 서비스 간 보안 통신
- **웹 UI**: 직관적인 관리 인터페이스
- **DNS 인터페이스**: DNS 기반 서비스 발견

## 🌐 접속 정보

### Docker Compose 환경
- **Consul UI**: http://localhost:10500
- **Consul API**: http://localhost:10500/v1/
- **Consul DNS**: localhost:10600

### Kubernetes 환경
- **Consul UI**: http://consul-ui.consul.svc.cluster.local:8500
- **Consul API**: http://consul-server.consul.svc.cluster.local:8500/v1/

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Consul-1      │    │   Consul-2      │    │   Consul-3      │
│   (Leader)      │◄──►│   (Follower)    │◄──►│   (Follower)    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Load Balancer │
                    │   (포트 10500)   │
                    └─────────────────┘
```

## 🚀 시작하기

### Docker Compose로 실행
```bash
cd /Users/gossing/WorkPlace/infra-app/service-discovery
docker-compose up -d
```

### Kubernetes로 실행
```bash
kubectl apply -f k8s/
```

## 📝 서비스 등록 예제

### REST API를 통한 등록
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

### DNS를 통한 조회
```bash
dig @localhost -p 10600 web.service.consul
```

## 🔧 설정 옵션

- **클러스터 크기**: 3개 노드 (고가용성)
- **데이터 백업**: 자동 스냅샷 기능
- **보안**: TLS 암호화 및 ACL 지원
- **성능**: SSD 스토리지 권장

## 📊 모니터링

Consul 메트릭은 Prometheus 형식으로 노출됩니다:
- 엔드포인트: http://localhost:10500/v1/agent/metrics?format=prometheus
