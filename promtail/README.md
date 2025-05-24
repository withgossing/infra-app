# Promtail 로그 에이전트

Loki로 로그를 수집하고 전송하는 에이전트입니다.

## 🎯 주요 기능

- **로그 수집**: 다양한 소스에서 로그 수집
- **라벨링**: 로그에 라벨 자동 추가
- **파싱**: 로그 형식 파싱 및 구조화
- **필터링**: 로그 전송 전 필터링

## 🚀 사용 방법

```bash
# 서비스 시작
docker-compose up -d

# 상태 확인
curl http://localhost:9080/metrics
```

## 📊 수집 대상

### 현재 설정된 로그 소스
- **시스템 로그**: `/var/log/` 디렉토리
- **Docker 컨테이너**: 모든 컨테이너 로그
- **Traefik 로그**: 액세스 및 애플리케이션 로그
- **애플리케이션**: JSON 형식 커스텀 로그

### 로그 라벨
```yaml
# 자동 추가되는 라벨
job: "container-logs"
container_name: "meritz-grafana"
level: "info"
method: "GET"
status: "200"
```

## ⚙️ 설정 파일

- `config/config.yml`: Promtail 메인 설정
- 로그 파싱 파이프라인 설정
- Loki 전송 설정

## 🔗 연동 서비스

- **Loki**: 로그 전송 대상
- **Grafana**: 로그 시각화

## 📚 참고 자료

- [Promtail 문서](https://grafana.com/docs/loki/latest/clients/promtail/)
