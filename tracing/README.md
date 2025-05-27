# Jaeger 분산 추적 시스템

Jaeger는 마이크로서비스 환경에서 분산 추적을 위한 오픈소스 시스템입니다. OpenTelemetry와 함께 사용하여 애플리케이션의 요청 흐름을 추적하고 성능 병목 지점을 식별할 수 있습니다.

## 포트 할당

- **10004**: Jaeger UI (외부 노출)
- **14268**: Jaeger HTTP Collector (내부)
- **14250**: Jaeger gRPC Collector (내부)
- **4317**: OTLP gRPC Receiver (내부)
- **4318**: OTLP HTTP Receiver (내부)
- **6831/6832**: Jaeger Agent UDP (내부)
- **5778**: Jaeger Agent HTTP (내부)
- **9411**: Zipkin Receiver (내부)

## 아키텍처

- **Jaeger UI**: 분산 추적 데이터 시각화 및 분석
- **Jaeger Collector**: 트레이스 데이터 수집 및 저장
- **Jaeger Query**: 트레이스 데이터 조회 서비스
- **Jaeger Agent**: 애플리케이션에서 트레이스 수집 (옵션)
- **OpenTelemetry Collector**: 다양한 형식의 텔레메트리 데이터 수집
- **Elasticsearch**: 트레이스 데이터 저장소

## 로컬 개발 환경 (Docker Compose)

### 시작하기

```bash
# Jaeger 스택 시작
docker-compose up -d

# 서비스 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f jaeger elasticsearch

# 스택 중지
docker-compose down
```

### 서비스 접속

```bash
# Jaeger UI
open http://localhost:10004

# Elasticsearch (Jaeger용)
curl http://localhost:9201

# OpenTelemetry Collector 헬스체크
curl http://localhost:13133

# OpenTelemetry Collector zPages
open http://localhost:55679/debug/tracez

# Jaeger Collector 상태
curl http://localhost:14269
```

### 트레이스 데이터 전송 테스트

#### HTTP를 통한 OTLP 전송
```bash
# JSON 형식의 트레이스 데이터 전송
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service"}
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "12345678901234567890123456789012",
          "spanId": "1234567890123456",
          "name": "test-span",
          "kind": 1,
          "startTimeUnixNano": "'$(date +%s%N)'",
          "endTimeUnixNano": "'$(date +%s%N)'",
          "attributes": [{
            "key": "http.method",
            "value": {"stringValue": "GET"}
          }]
        }]
      }]
    }]
  }'
```

#### Jaeger Thrift를 통한 전송
```bash
# Jaeger 바이너리를 사용한 테스트 (설치 필요)
echo "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n" | \
  jaeger-client --service test-service --operation test-operation
```

## Kubernetes 환경

### 배포하기

```bash
# 네임스페이스 및 설정 생성
kubectl apply -f k8s/01-namespace-config.yaml

# Elasticsearch 배포
kubectl apply -f k8s/02-elasticsearch.yaml

# Elasticsearch가 준비될 때까지 대기
kubectl wait --for=condition=ready pod -l app=jaeger-elasticsearch -n tracing --timeout=300s

# Jaeger 컴포넌트 배포
kubectl apply -f k8s/03-jaeger.yaml

# OpenTelemetry Collector 배포
kubectl apply -f k8s/04-otel-collector.yaml

# 모든 서비스가 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/jaeger-collector -n tracing
kubectl wait --for=condition=available --timeout=300s deployment/jaeger-query -n tracing
kubectl wait --for=condition=available --timeout=300s deployment/otel-collector -n tracing
```

### 서비스 접속

```bash
# 포트 포워딩으로 로컬 접속
kubectl port-forward svc/jaeger-query 16686:16686 -n tracing &
kubectl port-forward svc/otel-collector 4317:4317 -n tracing &
kubectl port-forward svc/otel-collector 4318:4318 -n tracing &

# 또는 NodePort로 접속 (클러스터 노드 IP 필요)
# Jaeger UI: http://<NODE_IP>:30004
```

### 상태 확인

```bash
# 모든 리소스 상태 확인
kubectl get all -n tracing

# Jaeger Collector 로그 확인
kubectl logs deployment/jaeger-collector -n tracing

# OpenTelemetry Collector 로그 확인
kubectl logs deployment/otel-collector -n tracing

# Elasticsearch 상태 확인
kubectl exec -it jaeger-elasticsearch-0 -n tracing -- curl localhost:9200/_cluster/health
```

## 애플리케이션 계측 (Instrumentation)

### Java (Spring Boot)

#### 의존성 추가 (Maven)
```xml
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-api</artifactId>
    <version>1.32.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk</artifactId>
    <version>1.32.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
    <version>1.32.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-spring-boot-starter</artifactId>
    <version>1.32.0-alpha</version>
</dependency>
```

#### 설정 (application.yml)
```yaml
management:
  tracing:
    sampling:
      probability: 1.0
  otlp:
    tracing:
      endpoint: http://localhost:4318/v1/traces

otel:
  service:
    name: spring-boot-app
  exporter:
    otlp:
      endpoint: http://localhost:4318
  resource:
    attributes:
      environment: development
```

#### 수동 계측
```java
@RestController
public class UserController {
    
    private final Tracer tracer;
    
    public UserController() {
        this.tracer = GlobalOpenTelemetry.getTracer("user-service");
    }
    
    @GetMapping("/users/{id}")
    public User getUser(@PathVariable String id) {
        Span span = tracer.spanBuilder("get-user")
                .setSpanKind(SpanKind.SERVER)
                .setAttribute("user.id", id)
                .startSpan();
        
        try (Scope scope = span.makeCurrent()) {
            // 비즈니스 로직
            User user = userService.findById(id);
            
            span.setAttribute("user.name", user.getName());
            span.setStatus(StatusCode.OK);
            
            return user;
        } catch (Exception e) {
            span.setStatus(StatusCode.ERROR, e.getMessage());
            throw e;
        } finally {
            span.end();
        }
    }
}
```

### Node.js (Express)

#### 패키지 설치
```bash
npm install @opentelemetry/api
npm install @opentelemetry/sdk-node
npm install @opentelemetry/auto-instrumentations-node
npm install @opentelemetry/exporter-otlp-http
```

#### 설정 (tracing.js)
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-http');

const traceExporter = new OTLPTraceExporter({
  url: 'http://localhost:4318/v1/traces',
});

const sdk = new NodeSDK({
  traceExporter,
  instrumentations: [getNodeAutoInstrumentations()],
  serviceName: 'nodejs-app',
  serviceVersion: '1.0.0',
});

sdk.start();

process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
```

#### 애플리케이션 시작
```javascript
// app.js 맨 위에 추가
require('./tracing');

const express = require('express');
const { trace } = require('@opentelemetry/api');

const app = express();
const tracer = trace.getTracer('express-server');

app.get('/users/:id', async (req, res) => {
  const span = tracer.startSpan('get-user');
  
  try {
    span.setAttributes({
      'user.id': req.params.id,
      'http.method': req.method,
      'http.url': req.url
    });
    
    // 비즈니스 로직
    const user = await getUserById(req.params.id);
    
    span.setAttributes({
      'user.name': user.name,
      'http.status_code': 200
    });
    
    res.json(user);
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: 2, message: error.message });
    res.status(500).json({ error: error.message });
  } finally {
    span.end();
  }
});
```

### Python (FastAPI)

#### 패키지 설치
```bash
pip install opentelemetry-api
pip install opentelemetry-sdk
pip install opentelemetry-instrumentation-fastapi
pip install opentelemetry-exporter-otlp
```

#### 설정
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import Resource

# 리소스 설정
resource = Resource.create({
    "service.name": "python-app",
    "service.version": "1.0.0",
    "environment": "development"
})

# TracerProvider 설정
trace.set_tracer_provider(TracerProvider(resource=resource))
tracer = trace.get_tracer(__name__)

# OTLP Exporter 설정
otlp_exporter = OTLPSpanExporter(
    endpoint="http://localhost:4318/v1/traces"
)

span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# FastAPI 앱
from fastapi import FastAPI

app = FastAPI()

# 자동 계측 활성화
FastAPIInstrumentor.instrument_app(app)

@app.get("/users/{user_id}")
async def get_user(user_id: str):
    with tracer.start_as_current_span("get-user") as span:
        span.set_attribute("user.id", user_id)
        
        try:
            # 비즈니스 로직
            user = await fetch_user(user_id)
            
            span.set_attribute("user.name", user["name"])
            span.set_attribute("user.status", "found")
            
            return user
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            raise
```

### Go

#### 모듈 설치
```bash
go mod init my-app
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/sdk
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp
go get go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp
```

#### 설정
```go
package main

import (
    "context"
    "log"
    "net/http"
    
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/resource"
    "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
    "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

func initTracer() func() {
    ctx := context.Background()
    
    // OTLP HTTP exporter
    exporter, err := otlptracehttp.New(ctx,
        otlptracehttp.WithEndpoint("http://localhost:4318"),
        otlptracehttp.WithInsecure(),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Resource 설정
    res := resource.NewWithAttributes(
        semconv.SchemaURL,
        semconv.ServiceNameKey.String("go-app"),
        semconv.ServiceVersionKey.String("1.0.0"),
        attribute.String("environment", "development"),
    )
    
    // TracerProvider 설정
    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
        trace.WithResource(res),
    )
    
    otel.SetTracerProvider(tp)
    
    return func() {
        if err := tp.Shutdown(ctx); err != nil {
            log.Printf("Error shutting down tracer provider: %v", err)
        }
    }
}

func getUserHandler(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    tracer := otel.Tracer("user-service")
    
    // 스팬 시작
    ctx, span := tracer.Start(ctx, "get-user")
    defer span.End()
    
    // 속성 설정
    userID := r.URL.Query().Get("id")
    span.SetAttributes(
        attribute.String("user.id", userID),
        attribute.String("http.method", r.Method),
    )
    
    // 비즈니스 로직
    user, err := fetchUser(ctx, userID)
    if err != nil {
        span.RecordError(err)
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    
    span.SetAttributes(
        attribute.String("user.name", user.Name),
        attribute.Int("http.status_code", http.StatusOK),
    )
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

func main() {
    cleanup := initTracer()
    defer cleanup()
    
    // HTTP 핸들러에 계측 추가
    handler := otelhttp.NewHandler(http.HandlerFunc(getUserHandler), "get-user")
    http.Handle("/users", handler)
    
    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

## Jaeger UI 사용법

### 트레이스 검색

1. **서비스 선택**: 드롭다운에서 추적할 서비스 선택
2. **오퍼레이션 선택**: 특정 오퍼레이션(API 엔드포인트) 선택
3. **시간 범위 설정**: 조회할 시간 범위 설정
4. **태그 필터**: 특정 태그 값으로 필터링
5. **검색 실행**: "Find Traces" 버튼 클릭

### 트레이스 분석

#### 트레이스 상세 보기
- **타임라인 뷰**: 스팬들의 시간순 실행 흐름
- **스팬 계층구조**: 부모-자식 관계 표시
- **스팬 상세정보**: 태그, 로그, 프로세스 정보

#### 성능 분석
- **총 실행 시간**: 전체 요청 처리 시간
- **임계 경로**: 가장 오래 걸린 경로 식별
- **병목 지점**: 느린 스팬 식별
- **에러 분석**: 실패한 스팬 및 오류 정보

### 대시보드 기능

#### 시스템 아키텍처
- **의존성 그래프**: 서비스 간 호출 관계 시각화
- **서비스 맵**: 마이크로서비스 토폴로지
- **트래픽 흐름**: 요청 흐름 패턴

#### 성능 메트릭
- **응답 시간 분포**: P50, P95, P99 지연시간
- **요청 처리량**: RPS (Requests Per Second)
- **에러율**: 실패한 요청 비율
- **SLA 모니터링**: 서비스 수준 목표 추적

## 고급 설정

### 샘플링 전략

#### 확률적 샘플링
```yaml
# 10% 샘플링
sampling_strategies:
  default_strategy:
    type: probabilistic
    param: 0.1
```

#### 적응형 샘플링
```yaml
sampling_strategies:
  default_strategy:
    type: adaptive
    param: 0.1
  per_service_strategies:
    - service: critical-service
      type: probabilistic
      param: 1.0  # 100% 샘플링
    - service: batch-service
      type: probabilistic
      param: 0.01  # 1% 샘플링
```

#### 비율 제한 샘플링
```yaml
sampling_strategies:
  default_strategy:
    type: ratelimiting
    param: 100  # 초당 100개 트레이스
```

### 데이터 보존 정책

#### Elasticsearch 인덱스 관리
```bash
# 오래된 인덱스 삭제 (7일 이상)
curl -X DELETE "http://localhost:9201/jaeger-span-$(date -d '7 days ago' +%Y-%m-%d)"

# 인덱스 라이프사이클 정책 설정
curl -X PUT "http://localhost:9201/_ilm/policy/jaeger-policy" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "actions": {
            "rollover": {
              "max_size": "50gb",
              "max_age": "1d"
            }
          }
        },
        "delete": {
          "min_age": "7d"
        }
      }
    }
  }'
```

### 보안 설정

#### HTTPS 활성화
```yaml
# docker-compose.yml
jaeger:
  environment:
    - QUERY_BASE_PATH=/jaeger
  volumes:
    - ./certs/jaeger.crt:/etc/ssl/certs/jaeger.crt:ro
    - ./certs/jaeger.key:/etc/ssl/private/jaeger.key:ro
```

#### 인증 설정
```yaml
# OAuth2 프록시를 통한 인증
oauth2-proxy:
  image: quay.io/oauth2-proxy/oauth2-proxy:latest
  command:
    - --upstream=http://jaeger:16686
    - --http-address=0.0.0.0:4180
    - --provider=github
    - --client-id=your-client-id
    - --client-secret=your-client-secret
```

## 모니터링 및 알림

### Prometheus 메트릭

#### Jaeger 메트릭 수집
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'jaeger-collector'
    static_configs:
      - targets: ['jaeger-collector:14269']
  
  - job_name: 'jaeger-query'  
    static_configs:
      - targets: ['jaeger-query:16687']
      
  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8888']
```

#### 주요 메트릭
- `jaeger_collector_spans_received_total`: 수집된 스팬 수
- `jaeger_collector_spans_saved_total`: 저장된 스팬 수
- `jaeger_query_requests_total`: 쿼리 요청 수
- `jaeger_query_request_duration_seconds`: 쿼리 응답 시간

### 알림 규칙

```yaml
# alerting-rules.yml
groups:
- name: jaeger.rules
  rules:
  - alert: JaegerCollectorDown
    expr: up{job="jaeger-collector"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Jaeger Collector is down"
      
  - alert: JaegerHighSpanDropRate
    expr: rate(jaeger_collector_spans_dropped_total[5m]) > 100
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High span drop rate in Jaeger Collector"
      
  - alert: JaegerStorageErrors
    expr: rate(jaeger_collector_save_latency_count{result="err"}[5m]) > 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Jaeger storage errors detected"
```

## 성능 최적화

### Elasticsearch 최적화

```yaml
# elasticsearch.yml
# 대용량 트레이스 처리를 위한 설정
thread_pool.write.queue_size: 2000
thread_pool.search.queue_size: 2000
search.max_buckets: 100000
indices.query.bool.max_clause_count: 10240

# 메모리 최적화
indices.memory.index_buffer_size: 30%
indices.fielddata.cache.size: 40%

# 인덱스 최적화
index.refresh_interval: 30s
index.translog.flush_threshold_size: 1gb
```

### Jaeger Collector 최적화

```yaml
# collector 설정
args:
  - "--es.bulk.size=10000000"
  - "--es.bulk.workers=10"
  - "--es.bulk.flush-interval=1s"
  - "--collector.queue-size=8000"
  - "--collector.num-workers=100"
```

### OpenTelemetry Collector 최적화

```yaml
processors:
  batch:
    timeout: 200ms
    send_batch_size: 2048
    send_batch_max_size: 4096
  
  memory_limiter:
    limit_mib: 2048
    spike_limit_mib: 512
    check_interval: 5s

exporters:
  jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true
    sending_queue:
      enabled: true
      num_consumers: 10
      queue_size: 5000
    retry_on_failure:
      enabled: true
      initial_interval: 1s
      max_interval: 30s
      max_elapsed_time: 5m
```

## 문제 해결

### 일반적인 문제

1. **트레이스가 보이지 않는 경우**
   ```bash
   # Collector 로그 확인
   docker logs jaeger-collector
   
   # 스팬 수신 확인
   curl http://localhost:14269/metrics | grep spans_received
   
   # Elasticsearch 인덱스 확인
   curl http://localhost:9201/_cat/indices/jaeger*
   ```

2. **높은 지연시간**
   ```bash
   # Elasticsearch 성능 확인
   curl http://localhost:9201/_cluster/stats
   
   # Collector 큐 상태 확인
   curl http://localhost:14269/metrics | grep queue
   ```

3. **메모리 부족**
   ```bash
   # Java 힙 사용량 확인
   docker exec jaeger-collector jcmd 1 VM.info
   
   # Elasticsearch 메모리 사용량
   curl http://localhost:9201/_nodes/stats/jvm
   ```

### 디버깅 도구

#### OpenTelemetry Collector 디버깅
```bash
# zPages 확인
open http://localhost:55679/debug/tracez

# 파이프라인 통계
curl http://localhost:8888/metrics | grep otelcol
```

#### Jaeger 디버깅
```bash
# Collector 상태
curl http://localhost:14269 | jq '.'

# Query 상태
curl http://localhost:16687 | jq '.'

# 스토리지 연결 테스트
curl "http://localhost:16686/api/services"
```

### 로그 분석

```bash
# 에러 로그 필터링
docker logs jaeger-collector 2>&1 | grep -i error

# 성능 로그 확인
docker logs otel-collector 2>&1 | grep -i "batch\|queue"

# Elasticsearch 로그
docker logs jaeger-elasticsearch 2>&1 | grep -E "(ERROR|WARN)"
```

## 통합 가이드

### ELK Stack과 연동

#### Logstash 파이프라인 설정
```ruby
# logstash pipeline
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][log_type] == "application" {
    # trace_id 추출
    grok {
      match => { "message" => ".*trace_id=(?<trace_id>[a-f0-9]{32}).*" }
    }
    
    if [trace_id] {
      mutate {
        add_field => { "jaeger_trace_url" => "http://localhost:10004/trace/%{trace_id}" }
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }
}
```

### Prometheus와 연동

#### 서비스 메트릭 수집
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'jaeger-spans-metrics'
    static_configs:
      - targets: ['otel-collector:8889']
    metrics_path: /metrics
    scrape_interval: 15s
```

#### Grafana 대시보드
```json
{
  "dashboard": {
    "title": "Jaeger Monitoring",
    "panels": [
      {
        "title": "Spans Received Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(jaeger_collector_spans_received_total[5m])"
          }
        ]
      },
      {
        "title": "Query Response Time",
        "type": "graph", 
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(jaeger_query_request_duration_seconds_bucket[5m]))"
          }
        ]
      }
    ]
  }
}
```

## 백업 및 복구

### Elasticsearch 백업

```bash
# 스냅샷 리포지토리 등록
curl -X PUT "http://localhost:9201/_snapshot/jaeger_backup" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/usr/share/elasticsearch/backups"
    }
  }'

# 스냅샷 생성
curl -X PUT "http://localhost:9201/_snapshot/jaeger_backup/jaeger_$(date +%Y%m%d)" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": "jaeger-*",
    "ignore_unavailable": true,
    "include_global_state": false
  }'

# 스냅샷 복구
curl -X POST "http://localhost:9201/_snapshot/jaeger_backup/jaeger_20240101/_restore" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": "jaeger-span-2024-01-01",
    "rename_pattern": "(.+)",
    "rename_replacement": "restored_$1"
  }'
```

### 설정 백업

```bash
# Jaeger 설정 백업
docker cp jaeger:/etc/jaeger/ ./jaeger-config-backup/

# OpenTelemetry Collector 설정 백업
docker cp otel-collector:/etc/otel-collector-config.yaml ./otel-config-backup/
```

## 참고 자료

- [Jaeger 공식 문서](https://www.jaegertracing.io/docs/)
- [OpenTelemetry 공식 문서](https://opentelemetry.io/docs/)
- [분산 추적 모범 사례](https://opentelemetry.io/docs/concepts/distributed-tracing/)
- [Jaeger 성능 튜닝 가이드](https://www.jaegertracing.io/docs/deployment/)
- [OpenTelemetry Collector 구성 가이드](https://opentelemetry.io/docs/collector/configuration/)
- [마이크로서비스 관찰 가능성](https://microservices.io/patterns/observability/distributed-tracing.html)
