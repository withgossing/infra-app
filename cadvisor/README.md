# cAdvisor 컨테이너 메트릭

Docker 컨테이너의 리소스 사용량 및 성능 메트릭을 수집하는 구글의 오픈소스 도구입니다.

## 🎯 수집 메트릭

- **컨테이너 리소스**: CPU, 메모리, 네트워크, 디스크
- **프로세스 정보**: 실행 중인 프로세스 수
- **파일시스템**: 컨테이너별 디스크 사용량
- **네트워크**: 인터페이스별 트래픽 통계

## 🚀 사용 방법

```bash
# 서비스 시작
docker-compose up -d

# 웹 UI 접속
open http://localhost:1008

# 메트릭 확인
curl http://localhost:1008/metrics
```

## 🌐 접속 정보

- **로컬**: http://localhost:1008
- **메트릭 엔드포인트**: /metrics

## 📊 주요 메트릭

```promql
# 컨테이너 CPU 사용률
rate(container_cpu_usage_seconds_total[5m]) * 100

# 컨테이너 메모리 사용률
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# 컨테이너 네트워크 I/O
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])
```

## 🔗 연동 서비스

- **Prometheus**: 메트릭 수집
- **Grafana**: 컨테이너 대시보드
