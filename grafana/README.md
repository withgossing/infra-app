# Grafana 시각화 대시보드

Meritz 인프라의 중앙 모니터링 대시보드 시스템입니다.

## 🎯 주요 기능

- **시각화 대시보드**: 메트릭과 로그를 직관적으로 시각화
- **멀티 데이터소스**: Prometheus, Loki, Jaeger 통합
- **알림 기능**: 임계값 기반 알림 설정
- **사용자 관리**: 역할 기반 접근 제어

## 🚀 사용 방법

### 서비스 시작
```bash
docker-compose up -d
```

### 서비스 중지
```bash
docker-compose down
```

### 로그 확인
```bash
docker-compose logs -f
```

## 🌐 접속 정보

- **로컬**: http://localhost:1003
- **도메인**: https://grafana.meritz.com
- **관리자 계정**: admin/admin123

## 📊 기본 대시보드

### 1. Meritz Infrastructure Overview
- 전체 인프라 상태 요약
- CPU, 메모리, 네트워크 사용률
- HTTP 트래픽 및 응답시간

### 2. System Monitoring (예정)
- 상세 시스템 메트릭
- 디스크 I/O, 네트워크 트래픽
- 프로세스 모니터링

### 3. Container Monitoring (예정)
- Docker 컨테이너 리소스 사용량
- 컨테이너 상태 및 재시작 이력
- 이미지 및 볼륨 사용량

## 🔌 데이터소스 설정

### 자동 프로비저닝된 데이터소스
1. **Prometheus** (기본)
   - URL: http://meritz-prometheus:9090
   - 메트릭 데이터 제공

2. **Loki**
   - URL: http://meritz-loki:3100
   - 로그 데이터 제공

3. **Jaeger**
   - URL: http://meritz-jaeger:16686
   - 분산 트레이싱 데이터 제공

## 📈 대시보드 커스터마이징

### 새 대시보드 생성
1. 좌측 메뉴 "+" → "Dashboard"
2. "Add new panel" 클릭
3. 데이터소스 선택 (Prometheus 권장)
4. 쿼리 작성 및 시각화 설정

### 유용한 패널 타입
- **Time series**: 시계열 데이터 (CPU, 메모리 등)
- **Stat**: 단일 값 표시 (현재 상태)
- **Gauge**: 게이지 형태 (사용률 표시)
- **Table**: 테이블 형태 (목록 데이터)

## 🔔 알림 설정

### 알림 채널 설정
1. "Alerting" → "Notification channels"
2. 새 채널 추가 (Slack, Email 등)
3. 대시보드에서 알림 규칙 설정

### 권장 알림 규칙
- CPU 사용률 > 80%
- 메모리 사용률 > 80%
- 디스크 사용률 > 85%
- HTTP 에러율 > 5%

## 📁 파일 구조

```
grafana/
├── docker-compose.yml          # 서비스 정의
├── .env                       # 환경 변수
├── provisioning/              # 자동 설정
│   ├── datasources/          # 데이터소스 설정
│   └── dashboards/           # 대시보드 설정
└── dashboards/               # 대시보드 JSON 파일
    └── infra-overview.json   # 기본 대시보드
```

## ⚙️ 설정 커스터마이징

### 환경 변수 수정
`.env` 파일에서 다음 설정 변경 가능:
- `GF_SECURITY_ADMIN_PASSWORD`: 관리자 비밀번호
- `GF_SERVER_ROOT_URL`: 외부 접근 URL
- `GF_INSTALL_PLUGINS`: 추가 플러그인

### 플러그인 설치
```bash
# 새 플러그인 추가
echo "GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel,new-plugin" > .env
docker-compose up -d
```

## 🎨 대시보드 개발

### 패널 쿼리 예시

#### 시스템 메트릭
```promql
# CPU 사용률
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 메모리 사용률
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

#### HTTP 메트릭
```promql
# 요청률
sum(rate(traefik_http_requests_total[5m])) by (service)

# 응답시간
histogram_quantile(0.95, sum(rate(traefik_http_request_duration_seconds_bucket[5m])) by (le))
```

### 로그 쿼리 (Loki)
```logql
# 에러 로그
{job="traefik-access"} |= "error"

# 특정 서비스 로그
{job="applications", service="api"}
```

## 🔧 트러블슈팅

### 일반적인 문제

1. **대시보드가 로드되지 않음**
   ```bash
   # Grafana 상태 확인
   curl http://localhost:1003/api/health
   ```

2. **데이터소스 연결 실패**
   ```bash
   # Prometheus 연결 확인
   curl http://meritz-prometheus:9090/-/healthy
   ```

3. **로그인 문제**
   - 기본 계정: admin/admin123
   - 비밀번호 재설정: `.env` 파일 수정 후 재시작

## 💾 백업 및 복구

### 대시보드 백업
```bash
# 대시보드 JSON 내보내기
curl -H "Authorization: Bearer <API_KEY>" \
     http://localhost:3000/api/dashboards/uid/<dashboard-uid>
```

### 설정 백업
```bash
# Grafana 데이터 백업
docker run --rm -v grafana_grafana_data:/source -v $(pwd):/backup \
    alpine tar -czf /backup/grafana-backup.tar.gz -C /source .
```

## 🔗 관련 서비스

- **Prometheus**: 메트릭 데이터 제공
- **Loki**: 로그 데이터 제공  
- **Jaeger**: 트레이싱 데이터 제공
- **Alertmanager**: 알림 관리 (추후 연동)

## 📚 참고 자료

- [Grafana 공식 문서](https://grafana.com/docs/)
- [PromQL 가이드](https://prometheus.io/docs/prometheus/latest/querying/)
- [LogQL 가이드](https://grafana.com/docs/loki/latest/logql/)
