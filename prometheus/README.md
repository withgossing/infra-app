# Prometheus 메트릭 수집 서비스

Meritz 인프라의 중앙 메트릭 수집 및 저장 시스템입니다.

## 🎯 주요 기능

- **메트릭 수집**: 모든 인프라 구성 요소에서 메트릭 수집
- **시계열 데이터베이스**: 효율적인 메트릭 저장 및 조회
- **PromQL**: 강력한 쿼리 언어로 데이터 분석
- **알림 규칙**: 임계값 기반 알림 시스템

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

- **로컬**: http://localhost:1002
- **도메인**: https://prometheus.meritz.com
- **계정**: admin/admin123

## 📊 수집 타겟

현재 설정된 메트릭 수집 대상:

1. **Prometheus 자체** - 내부 메트릭
2. **Traefik** - HTTP 요청, 응답시간, 에러율
3. **Node Exporter** - 시스템 메트릭 (CPU, 메모리, 디스크)
4. **cAdvisor** - 컨테이너 메트릭
5. **Grafana** - 대시보드 메트릭

## ⚙️ 설정 파일

### 주요 설정
- `config/prometheus.yml` - 메인 설정 파일
- `config/rules/alerts.yml` - 알림 규칙

### 환경 변수
- `TZ=Asia/Seoul` - 타임존
- `PROMETHEUS_RETENTION_TIME=200h` - 데이터 보존 기간

## 🔧 유용한 PromQL 쿼리

### 시스템 메트릭
```promql
# CPU 사용률
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 메모리 사용률  
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 디스크 사용률
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
```

### HTTP 메트릭
```promql
# 요청률
rate(traefik_http_requests_total[5m])

# 에러율
rate(traefik_http_requests_total{code=~"5.."}[5m]) / rate(traefik_http_requests_total[5m])

# 응답시간 95%
histogram_quantile(0.95, sum(rate(traefik_http_request_duration_seconds_bucket[5m])) by (le))
```

## 📈 데이터 관리

### 데이터 보존
- **기본 보존 기간**: 200시간 (약 8일)
- **스토리지 위치**: Docker 볼륨 `prometheus_data`

### 백업 및 복구
```bash
# 데이터 백업
docker run --rm -v prometheus_prometheus_data:/source -v $(pwd):/backup alpine tar -czf /backup/prometheus-backup.tar.gz -C /source .

# 데이터 복구
docker run --rm -v prometheus_prometheus_data:/target -v $(pwd):/backup alpine tar -xzf /backup/prometheus-backup.tar.gz -C /target
```

## 🔧 트러블슈팅

### 일반적인 문제

1. **타겟이 수집되지 않음**
   ```bash
   # 타겟 상태 확인
   curl http://localhost:1002/api/v1/targets
   ```

2. **메모리 부족**
   ```bash
   # 메모리 사용량 확인
   docker stats meritz-prometheus
   ```

3. **디스크 공간 부족**
   ```bash
   # 볼륨 사용량 확인
   docker system df
   ```

## 🔗 관련 서비스

- **Grafana**: 시각화 대시보드
- **Alertmanager**: 알림 관리 (추후 추가 예정)
- **Node Exporter**: 시스템 메트릭 제공
- **cAdvisor**: 컨테이너 메트릭 제공
