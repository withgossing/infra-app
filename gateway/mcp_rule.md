# Meritz Infrastructure 프로젝트 MCP 규칙

## 프로젝트 기본 정보

### 📁 폴더 구조
- **기본 폴더**: `/Users/gossing/WorkPlace`
- **인프라 폴더**: `/Users/gossing/WorkPlace/infra-app`
- **게이트웨이 폴더**: `/Users/gossing/WorkPlace/infra-app/gateway`

### 🌐 포트 할당 규칙
외부 노출 포트는 **1000번부터 순차적**으로 할당하여 충돌 방지:
- **1000**: Traefik 대시보드
- **1001**: (예약됨)
- **1002**: Prometheus
- **1003**: Grafana
- **1004**: Loki
- **1005**: Jaeger UI
- **1006**: Jaeger Collector
- **1007**: Node Exporter
- **1008**: cAdvisor
- **1009**: Uptime Kuma
- **1010+**: 추후 서비스용

### 🏷️ 도메인 구조
- **기본 도메인**: `meritz.com`
- **와일드카드**: `*.meritz.com`
- **지원 서브도메인**:
  - `www.meritz.com` → 메인 웹사이트
  - `api.meritz.com` → API 서비스
  - `admin.meritz.com` → 관리자 대시보드
  - `traefik.meritz.com` → Traefik 대시보드
  - `grafana.meritz.com` → Grafana 모니터링
  - `prometheus.meritz.com` → Prometheus 메트릭
  - `monitoring.meritz.com` → 모니터링 통합
  - `dev.meritz.com` → 개발 환경
  - `기타.meritz.com` → 기본 404 페이지

## 🔧 기술 스택

### Gateway & Reverse Proxy
- **Traefik v3.0**: 메인 게이트웨이
- **Let's Encrypt**: 자동 SSL 인증서
- **Docker**: 컨테이너화

### 모니터링 스택
- **Prometheus v2.47.0**: 메트릭 수집
- **Grafana v10.2.0**: 시각화 대시보드
- **Loki v2.9.0**: 로그 수집/분석
- **Promtail v2.9.0**: 로그 에이전트
- **Jaeger v1.50**: 분산 트레이싱
- **Node Exporter v1.6.0**: 시스템 메트릭
- **cAdvisor v0.47.0**: 컨테이너 메트릭
- **Uptime Kuma v1.23.0**: 업타임 모니터링

## 📋 개발 원칙

### 안정성
- ✅ 예외 처리 및 에러 핸들링
- ✅ 헬스체크 및 모니터링
- ✅ 장애 복구 및 재시도 로직
- ✅ 로깅 및 알림 시스템
- ✅ 백업 및 복구 자동화

### 효율성 & 최적화
- ✅ 컨테이너 이미지 최적화
- ✅ 메모리 효율성 고려
- ✅ 캐싱 전략 적용
- ✅ 로드 밸런싱 구현
- ✅ 성능 모니터링 도구

### 보안
- ✅ HTTPS/TLS 강제 적용
- ✅ 기본 인증 시스템
- ✅ 보안 헤더 설정
- ✅ 레이트 리미팅
- ✅ 입력 데이터 검증

### 확장성
- ✅ 모듈식 설계 (Docker Compose)
- ✅ 수평 확장 가능한 구조
- ✅ 마이크로서비스 패턴
- ✅ 동적 서비스 디스커버리

## 🗂️ 파일 구조

```
/Users/gossing/WorkPlace/infra-app/gateway/
├── docker-compose.yml          # 메인 서비스 정의
├── .env                        # 환경 변수
├── README.md                   # 프로젝트 문서
├── mcp_rule.md                # 이 파일 (연속성 규칙)
├── traefik/
│   ├── config/
│   │   ├── traefik.yml        # Traefik 메인 설정
│   │   └── dynamic/
│   │       └── routes.yml     # 동적 라우팅 설정
│   ├── ssl/                   # SSL 인증서 저장소
│   └── logs/                  # 로그 파일
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml     # Prometheus 설정
│   ├── grafana/
│   │   └── provisioning/      # Grafana 자동 설정
│   ├── loki/
│   │   └── local-config.yaml  # Loki 설정
│   ├── promtail/
│   │   └── config.yml         # Promtail 설정
│   ├── default-pages/
│   │   └── index.html         # 404 페이지
│   └── uptime-kuma/           # Uptime Kuma 데이터
└── scripts/
    ├── start.sh               # 시작 스크립트
    ├── stop.sh                # 종료 스크립트
    ├── health-check.sh        # 헬스체크
    ├── backup.sh              # 백업 스크립트
    ├── restore.sh             # 복구 스크립트
    └── cleanup.sh             # 정리 스크립트
```

## 🚀 사용 방법

### 초기 설정
```bash
cd /Users/gossing/WorkPlace/infra-app/gateway
chmod +x scripts/*.sh
./scripts/start.sh
```

### 일상 관리
```bash
# 상태 확인
./scripts/health-check.sh

# 백업
./scripts/backup.sh

# 서비스 재시작
./scripts/stop.sh && ./scripts/start.sh
```

### 새 서비스 추가 시
1. `docker-compose.yml`에 서비스 추가
2. `traefik/config/dynamic/routes.yml`에 라우팅 규칙 추가
3. `monitoring/prometheus/prometheus.yml`에 모니터링 타겟 추가
4. 다음 포트 번호 사용 (현재 최신: 1009)

## 🔄 업데이트 이력

### v1.0.0 (2024-05-24)
- ✅ Traefik Gateway 기본 구성
- ✅ *.meritz.com 도메인 라우팅
- ✅ 전체 모니터링 스택 구축
- ✅ 자동화 스크립트 작성
- ✅ SSL/TLS 자동 인증서
- ✅ 헬스체크 및 백업 시스템

## 📞 문제 해결

### 일반적인 이슈
- **포트 충돌**: 1000-1009 포트 범위 확인
- **도메인 라우팅**: DNS 설정 및 Traefik 라우터 확인
- **SSL 인증서**: Let's Encrypt 한도 및 도메인 검증 확인
- **메모리 부족**: Docker 리소스 제한 및 시스템 메모리 확인

### 로그 위치
- **Traefik**: `./traefik/logs/`
- **컨테이너**: `docker-compose logs [service]`
- **시스템**: `./scripts/health-check.sh`

## 🎯 다음 단계 계획

### 단기 계획
- [ ] 추가 백엔드 서비스 연결
- [ ] Grafana 대시보드 커스터마이징
- [ ] 알림 시스템 구축 (Alertmanager)
- [ ] 보안 스캔 자동화

### 장기 계획
- [ ] Kubernetes 마이그레이션 준비
- [ ] CI/CD 파이프라인 통합
- [ ] 멀티 리전 배포
- [ ] 재해 복구 시스템

---

**⚡ 이 파일은 새로운 MCP 세션에서 프로젝트 연속성을 보장하기 위한 참조 문서입니다.**
