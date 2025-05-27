# ELK Stack 로깅 시스템

Elasticsearch, Logstash, Kibana를 포함한 중앙화된 로깅 시스템입니다. Filebeat와 Metricbeat를 통해 로그와 메트릭을 수집하고 분석할 수 있습니다.

## 포트 할당

- **10003**: Kibana 웹 UI (외부 노출)
- **9200**: Elasticsearch HTTP API (내부)
- **9300**: Elasticsearch Transport (내부)
- **5044**: Logstash Beats Input (내부)
- **5000**: Logstash TCP Input (내부)
- **9600**: Logstash Monitoring API (내부)

## 아키텍처

- **Elasticsearch**: 로그 데이터 저장 및 검색 엔진
- **Logstash**: 로그 수집, 변환, 전송 파이프라인
- **Kibana**: 로그 데이터 시각화 및 분석 도구
- **Filebeat**: 로그 파일 수집 에이전트
- **Metricbeat**: 시스템 메트릭 수집 에이전트

## 로컬 개발 환경 (Docker Compose)

### 시작하기

```bash
# ELK Stack 시작
docker-compose up -d

# 서비스 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f elasticsearch logstash kibana

# 스택 중지
docker-compose down
```

### 서비스 접속

```bash
# Kibana 웹 UI
open http://localhost:10003

# Elasticsearch API
curl http://localhost:9200

# Elasticsearch 클러스터 상태
curl http://localhost:9200/_cluster/health

# Logstash 모니터링
curl http://localhost:9600

# Elasticsearch 인덱스 목록
curl http://localhost:9200/_cat/indices?v
```

### 로그 전송 테스트

```bash
# TCP로 JSON 로그 전송
echo '{"timestamp":"2024-01-01T12:00:00Z","level":"INFO","message":"Test log message","service":"test-app"}' | nc localhost 5000

# HTTP로 JSON 로그 전송
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2024-01-01T12:00:00Z","level":"ERROR","message":"Test error message","service":"test-app"}'

# 애플리케이션 로그 전송
curl -X POST http://localhost:8081 \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2024-01-01T12:00:00Z","level":"WARN","logger":"com.company.service","message":"Test warning","response_time":150.5}'
```

## Kubernetes 환경

### 배포하기

```bash
# 네임스페이스 및 설정 생성
kubectl apply -f k8s/01-namespace-config.yaml

# Elasticsearch 배포
kubectl apply -f k8s/02-elasticsearch.yaml

# Elasticsearch가 준비될 때까지 대기
kubectl wait --for=condition=ready pod -l app=elasticsearch -n logging --timeout=300s

# Logstash 배포
kubectl apply -f k8s/03-logstash.yaml

# Kibana 배포
kubectl apply -f k8s/04-kibana.yaml

# Filebeat 배포 (로그 수집)
kubectl apply -f k8s/05-filebeat.yaml

# 모든 서비스가 준비될 때까지 대기
kubectl wait --for=condition=available --timeout=300s deployment/logstash -n logging
kubectl wait --for=condition=available --timeout=300s deployment/kibana -n logging
```

### 서비스 접속

```bash
# 포트 포워딩으로 로컬 접속
kubectl port-forward svc/kibana 5601:5601 -n logging &
kubectl port-forward svc/elasticsearch 9200:9200 -n logging &
kubectl port-forward svc/logstash 5000:5000 -n logging &

# 또는 NodePort로 접속 (클러스터 노드 IP 필요)
# Kibana: http://<NODE_IP>:30003
# Elasticsearch: http://<NODE_IP>:30200
```

### 상태 확인

```bash
# 모든 리소스 상태 확인
kubectl get all -n logging

# Pod 상태 확인
kubectl get pods -n logging

# Elasticsearch 클러스터 상태
kubectl exec -it elasticsearch-0 -n logging -- curl localhost:9200/_cluster/health

# Logstash 파이프라인 상태
kubectl exec -it deployment/logstash -n logging -- curl localhost:9600/_node/stats/pipelines
```

## Elasticsearch 사용법

### 기본 API 작업

```bash
# 클러스터 정보 확인
curl http://localhost:9200

# 클러스터 상태 확인
curl http://localhost:9200/_cluster/health?pretty

# 노드 정보 확인
curl http://localhost:9200/_nodes?pretty

# 인덱스 목록 확인
curl http://localhost:9200/_cat/indices?v

# 특정 인덱스 정보 확인
curl http://localhost:9200/logstash-general-2024.01.01

# 인덱스 통계
curl http://localhost:9200/logstash-general-*/_stats?pretty
```

### 검색 쿼리

```bash
# 모든 문서 검색
curl -X GET http://localhost:9200/logstash-general-*/_search?pretty

# 특정 레벨 로그 검색
curl -X GET http://localhost:9200/logstash-general-*/_search?pretty \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "level": "ERROR"
      }
    }
  }'

# 시간 범위로 검색
curl -X GET http://localhost:9200/logstash-general-*/_search?pretty \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "range": {
        "@timestamp": {
          "gte": "2024-01-01T00:00:00Z",
          "lte": "2024-01-01T23:59:59Z"
        }
      }
    }
  }'

# 복합 쿼리 (AND/OR)
curl -X GET http://localhost:9200/logstash-general-*/_search?pretty \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          {"match": {"level": "ERROR"}},
          {"match": {"service": "test-app"}}
        ]
      }
    }
  }'

# 집계 쿼리 (로그 레벨별 카운트)
curl -X GET http://localhost:9200/logstash-general-*/_search?pretty \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "levels": {
        "terms": {
          "field": "level.keyword"
        }
      }
    }
  }'
```

### 인덱스 관리

```bash
# 인덱스 생성
curl -X PUT http://localhost:9200/custom-logs-2024.01.01 \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "@timestamp": {"type": "date"},
        "level": {"type": "keyword"},
        "message": {"type": "text"}
      }
    }
  }'

# 인덱스 삭제
curl -X DELETE http://localhost:9200/old-logs-*

# 인덱스 템플릿 생성
curl -X PUT http://localhost:9200/_index_template/application-logs \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["app-*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
        "index.refresh_interval": "30s"
      }
    }
  }'
```

## Logstash 파이프라인

### 파이프라인 구조

현재 구성된 파이프라인:

1. **main.conf**: 일반적인 로그 처리
2. **beats.conf**: Filebeat/Metricbeat 데이터 처리
3. **application.conf**: 애플리케이션별 로그 처리

### 커스텀 파이프라인 추가

1. **새 파이프라인 파일 생성**
   ```bash
   # config/pipeline/custom.conf 생성
   input {
     tcp {
       port => 5002
       codec => json_lines
       tags => ["custom"]
     }
   }
   
   filter {
     if "custom" in [tags] {
       # 커스텀 필터링 로직
     }
   }
   
   output {
     elasticsearch {
       hosts => ["elasticsearch:9200"]
       index => "custom-logs-%{+YYYY.MM.dd}"
     }
   }
   ```

2. **pipelines.yml 업데이트**
   ```yaml
   - pipeline.id: custom
     path.config: "/usr/share/logstash/pipeline/custom.conf"
     pipeline.workers: 1
   ```

3. **Logstash 재시작**
   ```bash
   docker-compose restart logstash
   ```

### 파이프라인 모니터링

```bash
# 파이프라인 통계
curl http://localhost:9600/_node/stats/pipelines?pretty

# 특정 파이프라인 통계
curl http://localhost:9600/_node/stats/pipelines/main?pretty

# 핫 스레드 분석
curl http://localhost:9600/_node/hot_threads

# 플러그인 정보
curl http://localhost:9600/_node/plugins?pretty
```

## Kibana 사용법

### 초기 설정

1. **Kibana 접속**: http://localhost:10003
2. **인덱스 패턴 생성**:
   - Management > Stack Management > Index Patterns
   - Create index pattern
   - 인덱스 패턴: `logstash-*` 또는 `app-*`
   - 타임스탬프 필드: `@timestamp`

### 주요 기능

#### 1. Discover (로그 탐색)
```
- 실시간 로그 스트림 확인
- 필터링 및 검색
- 필드별 분석
- 시간 범위 조정
```

#### 2. Visualize (시각화 생성)
```
- Line Chart: 시간별 로그 수 추이
- Pie Chart: 로그 레벨별 비율
- Data Table: 상위 에러 메시지
- Heat Map: 시간별/서비스별 로그 분포
```

#### 3. Dashboard (대시보드)
```
- 여러 시각화를 하나의 대시보드에 조합
- 실시간 업데이트
- 필터 공유
- 드릴다운 기능
```

#### 4. Alerts (알림 설정)
```
- 로그 레벨별 알림
- 에러 임계값 초과 알림
- 이메일/Slack 알림 연동
```

### 대시보드 예제

#### 시스템 모니터링 대시보드
1. **에러 로그 수 (Time Series)**
   ```json
   {
     "query": {
       "bool": {
         "filter": [
           {"term": {"level.keyword": "ERROR"}}
         ]
       }
     }
   }
   ```

2. **서비스별 로그 분포 (Pie Chart)**
   ```json
   {
     "aggs": {
       "services": {
         "terms": {
           "field": "service.keyword",
           "size": 10
         }
       }
     }
   }
   ```

3. **응답 시간 분포 (Histogram)**
   ```json
   {
     "aggs": {
       "response_times": {
         "histogram": {
           "field": "response_time",
           "interval": 100
         }
       }
     }
   }
   ```

## 로그 수집 설정

### 애플리케이션에서 로그 전송

#### Java (Logback 설정)
```xml
<configuration>
  <appender name="TCP" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>localhost:5001</destination>
    <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
      <providers>
        <timestamp/>
        <logLevel/>
        <loggerName/>
        <message/>
        <mdc/>
        <stackTrace/>
      </providers>
    </encoder>
  </appender>
  
  <root level="INFO">
    <appender-ref ref="TCP"/>
  </root>
</configuration>
```

#### Node.js (Winston 설정)
```javascript
const winston = require('winston');
require('winston-logstash');

const logger = winston.createLogger({
  transports: [
    new winston.transports.Logstash({
      port: 5001,
      node_name: 'my-app',
      host: 'localhost'
    })
  ]
});

logger.info('Application started', { service: 'my-app', version: '1.0.0' });
```

#### Python (logging 설정)
```python
import logging
import json
import socket

class LogstashHandler(logging.Handler):
    def __init__(self, host='localhost', port=5001):
        super().__init__()
        self.host = host
        self.port = port
        
    def emit(self, record):
        log_data = {
            'timestamp': record.created,
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'service': 'python-app'
        }
        
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((self.host, self.port))
            sock.send((json.dumps(log_data) + '\n').encode())
            sock.close()
        except Exception:
            pass

logger = logging.getLogger(__name__)
logger.addHandler(LogstashHandler())
logger.setLevel(logging.INFO)

logger.info("Application started")
```

### Docker 로그 수집

#### 로그 드라이버 설정
```bash
# JSON 파일 로그 드라이버 (기본)
docker run -d --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 my-app

# Syslog 드라이버
docker run -d --log-driver syslog --log-opt syslog-address=tcp://localhost:5514 my-app

# Logstash 직접 연결
docker run -d --log-driver gelf --log-opt gelf-address=udp://localhost:12201 my-app
```

#### Docker Compose 로그 설정
```yaml
version: '3.8'
services:
  my-app:
    image: my-app:latest
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service,environment"
    labels:
      - "service=my-app"
      - "environment=production"
```

## 성능 최적화

### Elasticsearch 최적화

```bash
# 인덱스 설정 최적화
curl -X PUT http://localhost:9200/logs-*/_settings \
  -H "Content-Type: application/json" \
  -d '{
    "index": {
      "refresh_interval": "30s",
      "number_of_replicas": 0,
      "merge.policy.max_merged_segment": "5gb"
    }
  }'

# 매핑 최적화
curl -X PUT http://localhost:9200/_template/logs-template \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["logs-*"],
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.refresh_interval": "30s"
    },
    "mappings": {
      "properties": {
        "message": {"type": "text", "index": false},
        "level": {"type": "keyword"},
        "@timestamp": {"type": "date"}
      }
    }
  }'
```

### Logstash 최적화

```yaml
# logstash.yml
pipeline.workers: 4
pipeline.batch.size: 1000
pipeline.batch.delay: 50

# 큐 설정
queue.type: persisted
queue.max_bytes: 1gb
queue.max_events: 0
```

### Filebeat 최적화

```yaml
# filebeat.yml
queue.mem:
  events: 4096
  flush.min_events: 2048
  flush.timeout: 1s

output.logstash:
  hosts: ["logstash:5044"]
  bulk_max_size: 2048
  template.name: "filebeat"
  template.pattern: "filebeat-*"
```

## 보안 설정

### Elasticsearch 보안

```yaml
# elasticsearch.yml (보안 활성화)
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.enabled: true

# 사용자 생성
elasticsearch-users useradd logstash_writer -p password -r logstash_writer
elasticsearch-users useradd kibana_user -p password -r kibana_system
```

### HTTPS 설정

#### Nginx 프록시 설정
```nginx
server {
    listen 443 ssl;
    server_name kibana.company.com;
    
    ssl_certificate /etc/ssl/certs/kibana.crt;
    ssl_certificate_key /etc/ssl/private/kibana.key;
    
    location / {
        proxy_pass http://localhost:10003;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 네트워크 보안

```yaml
# docker-compose.yml
networks:
  logging-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          
services:
  elasticsearch:
    networks:
      logging-net:
        ipv4_address: 172.20.0.10
```

## 모니터링 및 알림

### Elasticsearch 모니터링

```bash
# 클러스터 헬스 모니터링
curl http://localhost:9200/_cluster/health?level=indices

# 노드 통계
curl http://localhost:9200/_nodes/stats

# 인덱스 통계
curl http://localhost:9200/_stats

# 느린 쿼리 로그 설정
curl -X PUT http://localhost:9200/logs-*/_settings \
  -H "Content-Type: application/json" \
  -d '{
    "index.search.slowlog.threshold.query.warn": "10s",
    "index.search.slowlog.threshold.query.info": "5s"
  }'
```

### Logstash 모니터링

```bash
# 파이프라인 통계 수집
curl http://localhost:9600/_node/stats/pipelines | jq '.'

# 이벤트 처리 통계
curl http://localhost:9600/_node/stats/events | jq '.'

# JVM 통계
curl http://localhost:9600/_node/stats/jvm | jq '.'
```

### Prometheus 연동

```yaml
# metricbeat.yml
metricbeat.modules:
- module: elasticsearch
  metricsets: ["node", "node_stats", "cluster_stats"]
  period: 10s
  hosts: ["http://elasticsearch:9200"]

- module: logstash
  metricsets: ["node", "node_stats"]
  period: 10s
  hosts: ["http://logstash:9600"]

- module: kibana
  metricsets: ["status"]
  period: 10s
  hosts: ["http://kibana:5601"]
```

## 백업 및 복구

### Elasticsearch 스냅샷

```bash
# 스냅샷 리포지토리 등록
curl -X PUT http://localhost:9200/_snapshot/backup_repo \
  -H "Content-Type: application/json" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/usr/share/elasticsearch/backups"
    }
  }'

# 스냅샷 생성
curl -X PUT http://localhost:9200/_snapshot/backup_repo/snapshot_1 \
  -H "Content-Type: application/json" \
  -d '{
    "indices": "logs-*",
    "ignore_unavailable": true,
    "include_global_state": false
  }'

# 스냅샷 목록 확인
curl http://localhost:9200/_snapshot/backup_repo/_all

# 스냅샷 복구
curl -X POST http://localhost:9200/_snapshot/backup_repo/snapshot_1/_restore \
  -H "Content-Type: application/json" \
  -d '{
    "indices": "logs-2024.01.01",
    "rename_pattern": "(.+)",
    "rename_replacement": "restored_$1"
  }'
```

### 설정 백업

```bash
# Elasticsearch 설정 백업
docker cp elasticsearch:/usr/share/elasticsearch/config ./elasticsearch-config-backup

# Logstash 설정 백업
docker cp logstash:/usr/share/logstash/config ./logstash-config-backup
docker cp logstash:/usr/share/logstash/pipeline ./logstash-pipeline-backup

# Kibana 설정 백업
docker cp kibana:/usr/share/kibana/config ./kibana-config-backup
```

## 문제 해결

### 일반적인 문제

1. **Elasticsearch 시작 실패**
   ```bash
   # 메모리 설정 확인
   docker logs elasticsearch
   
   # vm.max_map_count 증가
   sudo sysctl -w vm.max_map_count=262144
   echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
   ```

2. **Logstash 연결 실패**
   ```bash
   # Elasticsearch 연결 테스트
   docker exec logstash curl -f http://elasticsearch:9200
   
   # 파이프라인 구문 검사
   docker exec logstash bin/logstash --config.test_and_exit
   ```

3. **Kibana 로딩 오류**
   ```bash
   # Elasticsearch 상태 확인
   curl http://localhost:9200/_cluster/health
   
   # Kibana 인덱스 재생성
   curl -X DELETE http://localhost:9200/.kibana*
   docker restart kibana
   ```

4. **디스크 공간 부족**
   ```bash
   # 오래된 인덱스 삭제
   curl -X DELETE http://localhost:9200/logs-2024.01.*
   
   # 인덱스 라이프사이클 정책 설정
   curl -X PUT http://localhost:9200/_ilm/policy/logs-policy \
     -H "Content-Type: application/json" \
     -d '{
       "policy": {
         "phases": {
           "delete": {
             "min_age": "30d"
           }
         }
       }
     }'
   ```

### 성능 문제 진단

```bash
# 클러스터 성능 확인
curl http://localhost:9200/_cluster/stats?human&pretty

# 느린 쿼리 확인
curl http://localhost:9200/_cluster/settings?include_defaults=true | grep slowlog

# 캐시 통계
curl http://localhost:9200/_nodes/stats/indices/query_cache,request_cache

# 힙 메모리 사용량
curl http://localhost:9200/_nodes/stats/jvm?human&pretty
```

## 참고 자료

- [Elasticsearch 공식 문서](https://www.elastic.co/guide/en/elasticsearch/reference/current/)
- [Logstash 공식 문서](https://www.elastic.co/guide/en/logstash/current/)
- [Kibana 공식 문서](https://www.elastic.co/guide/en/kibana/current/)
- [Filebeat 공식 문서](https://www.elastic.co/guide/en/beats/filebeat/current/)
- [ELK Stack 모범 사례](https://www.elastic.co/guide/en/elastic-stack-get-started/current/)
- [Elasticsearch 성능 튜닝](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-search-speed.html)
