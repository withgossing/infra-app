# Node Exporter 시스템 메트릭

Linux/Unix 시스템의 하드웨어 및 OS 메트릭을 수집하는 Prometheus Exporter입니다.

## 🎯 수집 메트릭

- **CPU**: 사용률, 로드 평균, 프로세스 수
- **메모리**: 사용량, 버퍼, 캐시
- **디스크**: 사용량, I/O 통계
- **네트워크**: 트래픽, 에러, 패킷 통계
- **파일시스템**: 마운트 포인트별 사용량

## 🚀 사용 방법

```bash
# 서비스 시작
docker-compose up -d

# 메트릭 확인
curl http://localhost:1007/metrics
```

## 🌐 접속 정보

- **로컬**: http://localhost:1007
- **메트릭 엔드포인트**: /metrics

## 📊 주요 메트릭

```promql
# CPU 사용률
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 메모리 사용률
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 디스크 사용률
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
```

## 🔗 연동 서비스

- **Prometheus**: 메트릭 수집
- **Grafana**: 시각화
