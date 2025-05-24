# Meritz Infrastructure 프로젝트 MCP 규칙 (v2.0)

## 프로젝트 기본 정보

### 📁 폴더 구조 (모듈화된 마이크로서비스 아키텍처)
- **기본 폴더**: `/Users/gossing/WorkPlace`
- **인프라 폴더**: `/Users/gossing/WorkPlace/infra-app`
- **서비스별 독립 폴더**: 각 모니터링 도구가 개별 폴더로 분리

### 🌐 포트 할당 규칙
외부 노출 포트는 **10000번부터 순차적**으로 할당:
- **10000**: Traefik 대시보드
- **10001**: Prometheus
- **10002**: Grafana
- **10003**: Loki
- **10004**: Jaeger UI
- **10005**: Jaeger Collector
- **10006**: Node Exporter
- **10007**: cAdvisor
- **10008**: Uptime Kuma
- **10009+**: 추후 서비스용 (Alertmanager 등)

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
  - `loki.meritz.com` → Loki 로그
  - `jaeger.meritz.com` → Jaeger 트레이싱
  - `uptime.meritz.com` → Uptime Kuma
  - `기타.meritz.com` → 기본 404 페이지

## 🏗️ 모듈화된 아키텍처

### 새로운 폴더 구조
```
/Users/gossing/WorkPlace/infra-app/
├── docker-compose.yml          # 전체 통합 관리
├── README.md                   # 메인 문서
├── scripts/                    # 전체 관리 스크립트
│   ├── start-all.sh           # 모든 서비스 시작
│   ├── stop-all.sh            # 모든 서비스 중지
│   └── status.sh              # 전체 상태 확인
├── gateway/                    # API Gateway (Traefik)
│   ├── docker-compose.yml
│   ├── .env
│   ├── README.md
│   ├── traefik/config/
│   └── scripts/
├── prometheus/                 # 메트릭 수집 (독립 서비스)
│   ├── docker-compose.yml
│   ├── .env
│   ├── README.md
│   └── config/
├── grafana/                   # 시각화 대시보드 (독립 서비스)
│   ├── docker-compose.yml
│   ├── .env
│   ├── README.md
│   ├── provisioning/
│   └── dashboards/
├── loki/                      # 로그 수집 (독립 서비스)
│   ├── docker-compose.yml
│   ├── .env
│   ├── README.md
│   └── config/
├── jaeger/                    # 분산 트레이싱 (독립 서비스)
│   ├── docker-compose.yml
│   ├── .env
│   └── README.md
├── uptime-kuma/              # 가용성 모니터링 (독립 서비스)
│   ├── docker-compose.yml
│   ├── .env
│   ├── README.md
│   └── data/
├── node-exporter/            # 시스템 메트릭 (독립 서비스)
│   ├── docker-compose.yml
│   ├── .env
│   └── README.md
├── cadvisor/                 # 컨테이너 메트릭 (독립 서비스)
│   ├── docker-compose.yml
│   ├── .env
│   └── README.md
└── promtail/                 # 로그 에이전트 (독립 서비스)
    ├── docker-compose.yml
    ├── .env
    ├── README.md
    └── config/
```

## 🔧 기술 스택

### Gateway & Reverse Proxy
- **Traefik v3.0**: 메인 게이트웨이 (독립 서비스)

### 모니터링 스택 (모든 서비스 독립 운영)
- **Prometheus v2.47.0**: 메트릭 수집
- **Grafana v10.2.0**: 시각화 대시보드
- **Loki v2.9.0**: 로그 수집/분석
- **Promtail v2.9.0**: 로그 에이전트
- **Jaeger v1.50**: 분산 트레이싱
- **Node Exporter v1.6.0**: 시스템 메트릭
- **cAdvisor v0.47.0**: 컨테이너 메트릭
- **Uptime Kuma v1.23.0**: 업타임 모니터링

## 🚀 운영 방식

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
# 특정 서비스 디렉토리로 이동
cd prometheus

# 개별 서비스 시작/중지
docker-compose up -d
docker-compose down

# 개별 서비스 로그 확인
docker-compose logs -f
```

### 새 서비스 추가 절차
1. **새 폴더 생성**: `/infra-app/new-service/`
2. **Docker Compose 파일**: 표준 템플릿 사용
3. **환경 변수 파일**: `.env` 파일 생성
4. **README 파일**: 서비스별 사용 가이드
5. **포트 할당**: 다음 순번 포트 사용 (현재 최신: 10008)
6. **네트워크 연결**: `meritz-network` 사용
7. **Gateway 라우팅**: 필요시 Traefik 설정 추가

## 📋 개발 원칙 (기존 동일)

### 안정성
- ✅ 예외 처리 및 에러 핸들링
- ✅ 헬스체크 및 모니터링
- ✅ 장애 복구 및 재시도 로직
- ✅ 로깅 및 알림 시스템
- ✅ 백업 및 복구 자동화

### 확장성 (모듈화로 대폭 개선)
- ✅ **독립 서비스 구조**: 각 서비스가 완전히 독립적
- ✅ **수평 확장**: 개별 서비스별 확장 가능
- ✅ **마이크로서비스 패턴**: 서비스 간 느슨한 결합
- ✅ **독립적 배포**: 개별 서비스 업데이트 가능

### 유지보수성 (모듈화로 대폭 개선)
- ✅ **서비스별 문서**: 각 서비스마다 전용 README
- ✅ **독립적 설정**: 각 서비스별 환경 변수
- ✅ **격리된 로그**: 서비스별 로그 관리
- ✅ **단순한 구조**: 이해하기 쉬운 디렉토리 구조

## 🔄 업데이트 이력

### v2.1.2 (2025-05-25) - 헬스체크 및 API 접근 개선
- ✅ **Traefik API 활성화**: `api.insecure: true` 설정으로 대시보드 접근 허용
- ✅ **헬스체크 개선**: 서비스별 적절한 엔드포인트 사용
- ✅ **새로운 스크립트 추가**:
  - `healthcheck.sh`: 개선된 헬스체크 스크립트
  - `debug-services.sh`: 서비스 문제 진단 스크립트
  - `restart-problematic.sh`: 문제 서비스 재시작 스크립트

#### 헬스체크 엔드포인트:
- **Traefik**: `/api/overview` (포트 10000)
- **Prometheus**: `/-/healthy` (포트 10001)
- **Grafana**: `/api/health` (포트 10002)
- **Loki**: `/ready` (포트 10003)
- **Jaeger**: `/` (포트 10004)
- **Node Exporter**: `/metrics` (포트 10006)
- **cAdvisor**: `/metrics` (포트 10007)
- **Uptime Kuma**: `/` (포트 10008)

### v2.1.1 (2025-05-25) - Docker Compose 호환성 개선
- ✅ **version 속성 제거**: 최신 Docker Compose에서 obsolete된 version 속성 제거
- ✅ **depends_on 제거**: 서비스 간 독립성 강화를 위해 depends_on 제거
- ✅ **external_links 유지**: 컨테이너 간 통신은 external_links로 처리
- ✅ **개별 서비스 시작 스크립트**: start-prometheus-grafana.sh 스크립트 추가

#### 주요 변경 사항:
1. **docker-compose.yml version 제거**
   - 모든 서비스의 docker-compose.yml에서 `version: '3.8'` 제거
   - 최신 Docker Compose에서는 version이 필요하지 않음

2. **Grafana depends_on 문제 해결**
   - Grafana의 docker-compose.yml에서 `depends_on: - prometheus` 제거
   - 대신 `external_links`를 사용하여 다른 컨테이너 참조
   - 서비스 간 독립성 유지

3. **서비스 시작 순서**
   - Prometheus를 먼저 시작한 후 Grafana 시작
   - 각 서비스가 독립적으로 실행되도록 구성

4. **새로운 스크립트 추가**
   - `start-prometheus-grafana.sh`: Prometheus와 Grafana를 순차적으로 시작
   - `fix-compose-versions.sh`: 모든 docker-compose.yml에서 version 속성 제거
   - `start-missing.sh`: 현재 중지된 서비스만 시작

5. **주의사항**
   - 최신 Docker Compose는 version 속성을 지원하지 않음
   - 서비스 간 의존성은 external_links로 처리
   - 모든 서비스는 독립적으로 시작/중지 가능

### v2.1.0 (2025-05-24) - 포트 변경 및 정리
- ✅ **포트 번호 변경**: 1000번대 → 10000번대로 이동
- ✅ **중복 파일 정리**: gateway 폴더 내 monitoring 폴더 삭제
- ✅ **충돌 방지**: 일반적으로 사용하지 않는 10000번대 포트 사용

### v2.0.0 (2024-05-24) - 모듈화 버전
- ✅ **모든 모니터링 도구 분리**: 개별 폴더로 독립 운영
- ✅ **마이크로서비스 아키텍처**: 서비스별 완전 독립
- ✅ **개별 문서화**: 각 서비스별 README 및 환경 설정
- ✅ **통합 관리 스크립트**: 전체 인프라 일괄 관리 도구
- ✅ **확장성 극대화**: 새 서비스 추가 용이
- ✅ **유지보수성 향상**: 개별 서비스 독립 관리

### v1.0.0 (이전 버전)
- ✅ Traefik Gateway 기본 구성
- ✅ *.meritz.com 도메인 라우팅
- ✅ 통합 모니터링 스택 (단일 Compose)
- ✅ 자동화 스크립트 작성

## 📞 문제 해결

### 서비스별 독립 문제 해결
```bash
# 특정 서비스 문제 해결
cd [service-name]
docker-compose logs
docker-compose restart

# 전체 상태 한눈에 파악
./scripts/status.sh
```

### 네트워크 연결 문제
- 모든 서비스가 `meritz-network` 사용
- 서비스 간 통신: `meritz-[service-name]` 컨테이너명 사용

### 포트 충돌 방지
- 10000-10008 포트 범위 전용 사용
- 새 서비스 추가 시 순차적 포트 할당

## 🎯 다음 단계 계획

### 단기 계획
- [ ] **Alertmanager 추가** (포트 10009)
- [ ] 각 서비스별 백업 스크립트 개선
- [ ] Grafana 대시보드 추가 개발
- [ ] 서비스별 헬스체크 고도화

### 중기 계획  
- [ ] **ELK Stack 모듈** 추가 (포트 10010-10012)
- [ ] **Redis 캐시 모듈** 추가
- [ ] 서비스 메시 도입 고려
- [ ] 자동 스케일링 구현

### 장기 계획
- [ ] Kubernetes 마이그레이션 준비
- [ ] GitOps 파이프라인 구축
- [ ] 멀티 리전 배포
- [ ] 재해 복구 시스템

## 💡 모듈화의 장점

### 1. **독립성**
- 서비스별 독립적 업데이트 가능
- 한 서비스 장애가 다른 서비스에 영향 없음
- 개별 리소스 관리 최적화

### 2. **확장성**
- 필요한 서비스만 선택적 배포
- 서비스별 수평 확장 가능
- 새로운 도구 추가 용이

### 3. **유지보수성**
- 각 서비스별 전담 관리 가능
- 문제 발생 시 격리된 디버깅
- 명확한 책임 분리

---

**⚡ 이 v2.0 구조는 완전한 마이크로서비스 아키텍처로 확장성과 유지보수성이 극대화되었습니다.**

**새로운 MCP 세션에서는 이 구조를 기반으로 개별 서비스 관리 또는 전체 인프라 확장이 가능합니다.** 🚀
