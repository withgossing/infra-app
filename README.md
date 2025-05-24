# Meritz Infrastructure Platform

`*.meritz.com` 도메인을 위한 모듈식 인프라 플랫폼입니다. 각 서비스가 독립적으로 관리되는 마이크로서비스 아키텍처로 구성되었습니다.

## 🏗️ 아키텍처

```
Internet → Traefik Gateway → Backend Services
              ↓
         Monitoring Services
    (Prometheus, Grafana, Loki, Jaeger)
              ↓
         System Metrics
    (Node Exporter, cAdvisor)
```

## 📁 프로젝트 구조

```
/infra-app/
├── docker-compose.yml          # 전체 인프라 통합 관리
├── scripts/                    # 전체 관리 스크립트
│   ├── start-all.sh           # 모든 서비스 시작
│   ├── stop-all.sh            # 모든 서비스 중지
│   └── status.sh              # 전체 상태 확인
├── gateway/                    # API Gateway (Traefik)
│   ├── docker-compose.yml
│   ├── traefik/config/
│   └── scripts/
├── prometheus/                 # 메트릭 수집
│   ├── docker-compose.yml
│   └── config/
├── grafana/                   # 시각화 대시보드
│   ├── docker-compose.yml
│   ├── provisioning/
│   └── dashboards/
├── loki/                      # 로그 수집
│   ├── docker-compose.yml
│   └── config/
├── jaeger/                    # 분산 트레이싱
│   └── docker-compose.yml
├── uptime-kuma/              # 가용성 모니터링
│   └── docker-compose.yml
├── node-exporter/            # 시스템 메트릭
│   └── docker-compose.yml
├── cadvisor/                 # 컨테이너 메트릭
│   └── docker-compose.yml
└── promtail/                 # 로그 에이전트
    ├── docker-compose.yml
    └── config/
```

## 🚀 주요 기능

### 🌐 Gateway (Traefik)
- **도메인 라우팅**: `*.meritz.com` 모든 서브도메인 지원
- **자동 SSL/TLS**: Let's Encrypt 인증서 자동 발급/갱신
- **로드 밸런싱**: 다중 백엔드 서비스 지원
- **미들웨어**: 보안 헤더, CORS, 인증, 레이트 리미팅

### 📊 모니터링 스택
- **Prometheus** (포트: 10001): 메트릭 수집 및 저장
- **Grafana** (포트: 10002): 시각화 대시보드
- **Loki** (포트: 10003): 로그 수집 및 분석
- **Jaeger** (포트: 10004): 분산 트레이싱
- **Uptime Kuma** (포트: 10008): 서비스 가용성 모니터링

### 🔍 시스템 메트릭
- **Node Exporter** (포트: 10006): 시스템 메트릭
- **cAdvisor** (포트: 10007): 컨테이너 메트릭
- **Promtail**: 로그 수집 에이전트

## ⚡ 빠른 시작

### 1. 전체 인프라 시작
```bash
cd /Users/gossing/WorkPlace/infra-app
chmod +x scripts/*.sh
./scripts/start-all.sh
```

### 2. 개별 서비스 관리
```bash
# 개별 서비스 시작
cd prometheus
docker-compose up -d

# 개별 서비스 중지
cd grafana
docker-compose down

# 개별 서비스 재시작
cd loki
docker-compose restart
```

### 3. 전체 상태 확인
```bash
./scripts/status.sh
```

## 🌐 포트 및 접속 정보

| 서비스 | 로컬 포트 | 도메인 | 계정 |
|--------|-----------|--------|------|
| Traefik | 10000 | traefik.meritz.com | admin/admin123 |
| Prometheus | 10001 | prometheus.meritz.com | admin/admin123 |
| Grafana | 10002 | grafana.meritz.com | admin/admin123 |
| Loki | 10003 | loki.meritz.com | admin/admin123 |
| Jaeger | 10004 | jaeger.meritz.com | admin/admin123 |
| Node Exporter | 10006 | - | - |
| cAdvisor | 10007 | - | - |
| Uptime Kuma | 10008 | uptime.meritz.com | 초기 설정 필요 |

## 🔧 관리 명령어

### 전체 인프라 관리
```bash
# 모든 서비스 시작
./scripts/start-all.sh

# 모든 서비스 중지  
./scripts/stop-all.sh

# 전체 상태 확인
./scripts/status.sh
```

### 개별 서비스 관리
```bash
# 특정 서비스로 이동
cd [service-name]

# 서비스 시작
docker-compose up -d

# 서비스 중지
docker-compose down

# 로그 확인
docker-compose logs -f

# 서비스 재시작
docker-compose restart
```

## 🌐 지원 도메인

### 기본 서비스
- `www.meritz.com` → 메인 웹사이트 (설정 필요)
- `api.meritz.com` → API 서비스 (설정 필요)
- `admin.meritz.com` → 관리자 대시보드 (설정 필요)

### 모니터링 서비스
- `traefik.meritz.com` → Traefik 대시보드
- `grafana.meritz.com` → Grafana 모니터링
- `prometheus.meritz.com` → Prometheus 메트릭
- `loki.meritz.com` → Loki 로그
- `jaeger.meritz.com` → Jaeger 트레이싱
- `uptime.meritz.com` → Uptime Kuma

### 와일드카드 지원
- `*.meritz.com` → 기본 404 페이지

## 🔒 보안 기능

- ✅ **HTTPS 강제**: 모든 HTTP → HTTPS 리다이렉트
- ✅ **보안 헤더**: HSTS, XSS Protection, Content-Type Options
- ✅ **레이트 리미팅**: 분당 100회 요청 제한
- ✅ **기본 인증**: 관리 도구 접근 제한
- ✅ **SSL 인증서**: Let's Encrypt 자동 갱신

## 🚀 새로운 서비스 추가

### 1. 새 서비스 폴더 생성
```bash
mkdir /Users/gossing/WorkPlace/infra-app/my-service
cd my-service
```

### 2. Docker Compose 파일 생성
```yaml
# my-service/docker-compose.yml
version: '3.8'

networks:
  meritz-network:
    external: true

services:
  my-service:
    image: my-image
    container_name: meritz-my-service
    networks:
      - meritz-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-service.rule=Host(`my-service.meritz.com`)"
      - "traefik.http.routers.my-service.tls.certresolver=letsencrypt"
```

### 3. Gateway 라우팅 설정
`gateway/traefik/config/dynamic/routes.yml`에 라우터 추가

### 4. 모니터링 설정
`prometheus/config/prometheus.yml`에 타겟 추가

## 📊 모니터링 대시보드

### Grafana 대시보드
- **Infrastructure Overview**: 전체 인프라 상태
- **System Metrics**: CPU, 메모리, 디스크, 네트워크
- **Container Metrics**: Docker 컨테이너 리소스
- **Traefik Dashboard**: HTTP 트래픽 및 응답시간

### 주요 메트릭
- **시스템**: CPU/메모리 사용률, 디스크 I/O, 네트워크
- **HTTP**: 요청률, 응답시간, 에러율
- **컨테이너**: 리소스 사용량, 재시작 횟수
- **로그**: 에러 로그 발생률, 로그 볼륨

## 🔍 트러블슈팅

### 일반적인 문제

#### 1. 서비스가 시작되지 않음
```bash
# 개별 서비스 로그 확인
cd [service-name]
docker-compose logs

# 전체 상태 확인
./scripts/status.sh
```

#### 2. 포트 충돌
```bash
# 포트 사용 상태 확인
netstat -tulpn | grep :10000

# 해당 프로세스 종료 후 재시작
```

#### 3. SSL 인증서 문제
```bash
# Traefik 로그 확인
cd gateway
docker-compose logs traefik

# Let's Encrypt 제한 확인 (일일 발급 제한)
```

### 로그 위치
- **서비스 로그**: `docker-compose logs [service]`
- **Traefik 로그**: `gateway/traefik/logs/`
- **시스템 로그**: `/var/log/`

## 🔄 업데이트 및 유지보수

### 서비스 업데이트
```bash
# 이미지 업데이트
cd [service-name]
docker-compose pull
docker-compose up -d

# 전체 업데이트
./scripts/stop-all.sh
git pull
./scripts/start-all.sh
```

### 백업
각 서비스별로 개별 백업 스크립트 제공:
```bash
cd gateway
./scripts/backup.sh
```

## 📈 성능 최적화

### 시스템 요구사항
- **CPU**: 4 코어 이상
- **메모리**: 8GB 이상  
- **디스크**: SSD, 50GB 이상
- **네트워크**: 1Gbps 이상

### 리소스 모니터링
```bash
# 실시간 리소스 사용량
./scripts/status.sh

# Docker 컨테이너별 사용량
docker stats
```

## 🎯 확장 계획

### 단기 (1-2주)
- [ ] Alertmanager 추가 (알림 강화)
- [ ] Blackbox Exporter (외부 서비스 모니터링)
- [ ] 추가 Grafana 대시보드

### 중기 (1-2개월)  
- [ ] ELK Stack (고급 로그 분석)
- [ ] Redis (캐싱)
- [ ] 멀티 리전 배포

### 장기 (3-6개월)
- [ ] Kubernetes 마이그레이션
- [ ] CI/CD 파이프라인
- [ ] 재해복구 시스템

## 📞 지원

### 문제 해결 순서
1. `./scripts/status.sh`로 전체 상태 확인
2. 개별 서비스 로그 확인: `docker-compose logs [service]`
3. 서비스 재시작: `docker-compose restart [service]`
4. 전체 재시작: `./scripts/stop-all.sh && ./scripts/start-all.sh`

### 참고 자료
- [Traefik 문서](https://doc.traefik.io/traefik/)
- [Prometheus 문서](https://prometheus.io/docs/)
- [Grafana 문서](https://grafana.com/docs/)

---

## 🎉 완성! 

**모든 `*.meritz.com` 도메인 요청이 완벽하게 라우팅되는 엔터프라이즈급 인프라가 완성되었습니다!**

각 서비스가 독립적으로 관리되어 확장성과 유지보수성이 극대화되었습니다. 🚀
