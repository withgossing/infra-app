# 모니터링 스택 (Prometheus + Grafana + AlertManager)

완전한 모니터링 솔루션으로 Prometheus 메트릭 수집, Grafana 시각화, AlertManager 알림 시스템을 포함합니다.

## 포트 할당

- **10001**: Prometheus (외부 노출)
- **10002**: Grafana (외부 노출)
- **9093**: AlertManager (내부/선택적 외부 노출)
- **9100**: Node Exporter (시스템 메트릭)
- **8080**: cAdvisor (컨테이너 메트릭)

## 아키텍처

- **Prometheus**: 메트릭 수집 및 저장, 알림 규칙 평가
- **Grafana**: 메트릭 시각화 및 대시보드
- **AlertManager**: 알림 라우팅 및 전송
- **Node Exporter**: 시스템 메트릭 수집
- **cAdvisor**: 컨테이너 메트릭 수집

## 로컬 개발 환경 (Docker Compose)

### 시작하기

```bash
# 모니터링 스택 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f prometheus grafana alertmanager

# 서비스 상태 확인
docker-compose ps

# 스택 중지
docker-compose down
```

### 서비스 접속

```bash
# Prometheus 웹 UI
open http://localhost:10001

# Grafana 웹 UI (admin/admin_password)
open http://localhost:10002

# AlertManager 웹 UI
open http://localhost:9093

# Node Exporter 메트릭
curl http://localhost:9100/metrics

# cAdvisor 웹 UI
open http://localhost:8080
```

### 초기 설정

1. **Grafana 로그인**
   - 사용자명: `admin`
   - 비밀번호: `admin_password`

2. **데이터소스 확인**
   - Prometheus 데이터소스가 자동으로 설정됨
   - URL: `http://prometheus:9090`

3. **대시보드 가져오기**
   - 기본 시스템 개요 대시보드가 자동으로 프로비저닝됨

## Kubernetes 환경

### 배포하기

```bash
# 네임스페이스 및 설정 생성
kubectl apply -f k8s/01-namespace-config.yaml

# Prometheus 배포
kubectl apply -f k8s/02-prometheus.yaml

# Prometheus가 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring

# Grafana 및 AlertManager 배포
kubectl apply -f k8s/03-grafana-alertmanager.yaml

# 모든 서비스가 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/alertmanager -n monitoring
```

### 서비스 접속

```bash
# 포트 포워딩으로 로컬 접속
kubectl port-forward svc/prometheus 9090:9090 -n monitoring &
kubectl port-forward svc/grafana 3000:3000 -n monitoring &
kubectl port-forward svc/alertmanager 9093:9093 -n monitoring &

# 또는 NodePort로 접속 (클러스터 노드 IP 필요)
# Prometheus: http://<NODE_IP>:30001
# Grafana: http://<NODE_IP>:30002
# AlertManager: http://<NODE_IP>:30003
```

### 상태 확인

```bash
# 모든 리소스 상태 확인
kubectl get all -n monitoring

# Prometheus 대상 확인
kubectl logs deployment/prometheus -n monitoring | grep "Server is ready"

# Grafana 로그 확인
kubectl logs deployment/grafana -n monitoring
```

## Prometheus 사용법

### 메트릭 쿼리 예제

```promql
# CPU 사용률
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 메모리 사용률
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 디스크 사용률
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# HTTP 요청 수
rate(http_requests_total[5m])

# HTTP 응답 시간 (95 백분위수)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# 컨테이너 메모리 사용량
container_memory_usage_bytes{container!=""}

# Pod 재시작 횟수
increase(kube_pod_container_status_restarts_total[1h])
```

### 레이블 활용

```promql
# 특정 인스턴스의 메트릭
node_cpu_seconds_total{instance="localhost:9100"}

# 특정 Job의 메트릭
up{job="prometheus"}

# 정규식 매칭
http_requests_total{status=~"5.."}

# 네거티브 매칭
node_filesystem_size_bytes{fstype!="tmpfs"}
```

## Grafana 대시보드

### 기본 대시보드

1. **시스템 개요**
   - CPU, 메모리, 디스크, 네트워크 사용률
   - 시스템 로드 및 프로세스 수

2. **애플리케이션 모니터링**
   - HTTP 요청 수 및 응답 시간
   - JVM 메트릭 (Java 애플리케이션)
   - 에러율 및 가용성

3. **컨테이너 모니터링**
   - 컨테이너 리소스 사용량
   - Pod 상태 및 재시작 횟수
   - Kubernetes 클러스터 상태

### 커스텀 대시보드 생성

1. **변수 설정**
   ```
   Name: instance
   Type: Query
   Query: label_values(up, instance)
   ```

2. **패널 추가**
   - Time series, Gauge, Stat, Table 등 다양한 시각화 타입
   - 임계값 설정으로 색상 변경
   - 단위 설정 (%, bytes, requests/sec 등)

3. **알림 설정**
   ```json
   {
     "conditions": [{
       "query": {"queryType": "", "refId": "A"},
       "reducer": {"type": "last", "params": []},
       "evaluator": {"params": [80], "type": "gt"}
     }],
     "executionErrorState": "alerting",
     "noDataState": "no_data",
     "frequency": "10s"
   }
   ```

## AlertManager 설정

### 알림 규칙 예제

```yaml
# CPU 사용률 높음
- alert: HighCPUUsage
  expr: cpu_usage_percent > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "높은 CPU 사용률"
    description: "{{ $labels.instance }}의 CPU 사용률이 {{ $value }}%입니다"

# 서비스 다운
- alert: ServiceDown
  expr: up == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "서비스 다운"
    description: "{{ $labels.job }}의 {{ $labels.instance }}가 다운되었습니다"
```

### 알림 채널 설정

#### 이메일 설정
```yaml
email_configs:
  - to: 'team@company.com'
    subject: '[Alert] {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      알림: {{ .Annotations.summary }}
      상세: {{ .Annotations.description }}
      {{ end }}
```

#### Slack 설정
```yaml
slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
    title: '{{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      {{ .Annotations.summary }}
      {{ .Annotations.description }}
      {{ end }}
```

#### 웹훅 설정
```yaml
webhook_configs:
  - url: 'http://your-webhook-endpoint.com/alerts'
    send_resolved: true
```

### 알림 테스트

```bash
# 수동으로 알림 생성 (테스트용)
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning"
    },
    "annotations": {
      "summary": "테스트 알림",
      "description": "이것은 테스트 알림입니다"
    }
  }]'

# 알림 상태 확인
curl http://localhost:9093/api/v1/alerts

# 알림 해제
curl -X DELETE http://localhost:9093/api/v1/alerts
```

## 메트릭 수집 확장

### 애플리케이션 모니터링

#### Spring Boot Actuator
```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    prometheus:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
```

#### Node.js 애플리케이션
```javascript
const client = require('prom-client');
const register = new client.Registry();

// 기본 메트릭 수집
client.collectDefaultMetrics({ register });

// 커스텀 메트릭
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

register.registerMetric(httpRequestsTotal);

// 메트릭 엔드포인트
app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(register.metrics());
});
```

### 외부 시스템 모니터링

#### Redis Exporter
```bash
# Docker로 Redis Exporter 실행
docker run -d \
  --name redis-exporter \
  -p 9121:9121 \
  oliver006/redis_exporter \
  --redis.addr=redis://localhost:6379
```

#### PostgreSQL Exporter
```bash
# Docker로 PostgreSQL Exporter 실행
docker run -d \
  --name postgres-exporter \
  -p 9187:9187 \
  -e DATA_SOURCE_NAME="postgresql://username:password@localhost:5432/database?sslmode=disable" \
  prometheuscommunity/postgres-exporter
```

#### Nginx Exporter
```bash
# Nginx 상태 모듈 활성화 필요
location /nginx_status {
  stub_status on;
  access_log off;
  allow 127.0.0.1;
  deny all;
}

# Docker로 Nginx Exporter 실행
docker run -d \
  --name nginx-exporter \
  -p 9113:9113 \
  nginx/nginx-prometheus-exporter:latest \
  -nginx.scrape-uri=http://localhost/nginx_status
```

## 성능 최적화

### Prometheus 최적화

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'

# 데이터 보존 설정
storage:
  tsdb:
    retention.time: 15d
    retention.size: 50GB

# 메모리 사용량 제한
scrape_configs:
  - job_name: 'high-cardinality-job'
    scrape_interval: 60s  # 높은 카디널리티 메트릭은 긴 간격
    metric_relabel_configs:
    - source_labels: [__name__]
      regex: 'high_cardinality_metric_.*'
      action: drop  # 불필요한 메트릭 제거
```

### Grafana 최적화

```ini
# grafana.ini
[database]
# SQLite 대신 PostgreSQL/MySQL 사용 (프로덕션 환경)
type = postgres
host = localhost:5432
name = grafana
user = grafana
password = password

[caching]
# 캐싱 활성화
enabled = true

[dashboards]
# 대시보드 스냅샷 제한
versions_to_keep = 20
```

## 모니터링 및 문제 해결

### 일반적인 문제

1. **Prometheus 대상에 연결할 수 없음**
   ```bash
   # 대상 상태 확인
   curl http://localhost:10001/api/v1/targets
   
   # 네트워크 연결 테스트
   telnet target_host target_port
   ```

2. **메트릭이 수집되지 않음**
   ```bash
   # Prometheus 로그 확인
   docker logs prometheus
   
   # 메트릭 엔드포인트 직접 확인
   curl http://target:port/metrics
   ```

3. **Grafana에서 데이터가 보이지 않음**
   ```bash
   # 데이터소스 연결 테스트
   # Grafana UI에서 Data Sources > Test 클릭
   
   # 쿼리 직접 테스트
   # Explore 메뉴에서 PromQL 쿼리 실행
   ```

4. **알림이 전송되지 않음**
   ```bash
   # AlertManager 설정 확인
   curl http://localhost:9093/api/v1/status
   
   # 알림 규칙 상태 확인
   curl http://localhost:10001/api/v1/rules
   ```

### 로그 분석

```bash
# Prometheus 로그
docker logs prometheus 2>&1 | grep -i error

# Grafana 로그
docker logs grafana 2>&1 | grep -i error

# AlertManager 로그
docker logs alertmanager 2>&1 | grep -i error

# 메트릭 수집 상태 확인
curl -s http://localhost:10001/api/v1/label/__name__/values | jq .
```

### 성능 모니터링

```bash
# Prometheus 메트릭 확인
curl -s http://localhost:10001/metrics | grep prometheus_

# 메모리 사용량
prometheus_tsdb_head_memory_bytes

# 디스크 사용량
prometheus_tsdb_size_bytes

# 쿼리 성능
prometheus_engine_query_duration_seconds
```

## 백업 및 복구

### Prometheus 데이터 백업

```bash
# 스냅샷 생성
curl -X POST http://localhost:10001/api/v1/admin/tsdb/snapshot

# 백업 파일 복사
docker cp prometheus:/prometheus/snapshots/. ./prometheus-backup/
```

### Grafana 설정 백업

```bash
# 설정 파일 백업
docker cp grafana:/etc/grafana/grafana.ini ./grafana-backup/
docker cp grafana:/var/lib/grafana/grafana.db ./grafana-backup/
```

### 복구 절차

```bash
# Prometheus 데이터 복구
docker cp ./prometheus-backup/. prometheus:/prometheus/

# Grafana 설정 복구
docker cp ./grafana-backup/grafana.db grafana:/var/lib/grafana/
docker restart grafana
```

## 보안 설정

### HTTPS 활성화

```yaml
# Prometheus HTTPS 설정
web_config:
  tls_server_config:
    cert_file: /etc/prometheus/prometheus.crt
    key_file: /etc/prometheus/prometheus.key

# Grafana HTTPS 설정
[server]
protocol = https
cert_file = /etc/grafana/grafana.crt
cert_key = /etc/grafana/grafana.key
```

### 인증 설정

```yaml
# 기본 인증
basic_auth:
  username: prometheus
  password: secure_password

# OAuth 인증 (Grafana)
[auth.google]
enabled = true
client_id = your_client_id
client_secret = your_client_secret
```

## 참고 자료

- [Prometheus 공식 문서](https://prometheus.io/docs/)
- [Grafana 공식 문서](https://grafana.com/docs/)
- [AlertManager 가이드](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [PromQL 가이드](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Node Exporter 문서](https://github.com/prometheus/node_exporter)
- [모니터링 모범 사례](https://prometheus.io/docs/practices/)
