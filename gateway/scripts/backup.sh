#!/bin/bash

# Meritz Gateway 백업 스크립트
# 모든 설정과 데이터를 백업합니다

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="meritz_gateway_backup_${TIMESTAMP}.tar.gz"

echo "💾 Meritz Gateway 백업을 시작합니다..."

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR

echo "📦 데이터 백업 중..."

# 설정 파일 백업
echo "  - 설정 파일들..."
tar -czf "${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz" \
    .env \
    docker-compose.yml \
    traefik/config/ \
    monitoring/ \
    scripts/ \
    2>/dev/null || echo "일부 설정 파일을 건너뛰었습니다"

# Docker 볼륨 백업
echo "  - Prometheus 데이터..."
docker run --rm -v gateway_prometheus_data:/source -v $(pwd)/${BACKUP_DIR}:/backup \
    alpine tar -czf /backup/prometheus_${TIMESTAMP}.tar.gz -C /source . \
    2>/dev/null || echo "Prometheus 데이터를 건너뛰었습니다"

echo "  - Grafana 데이터..."
docker run --rm -v gateway_grafana_data:/source -v $(pwd)/${BACKUP_DIR}:/backup \
    alpine tar -czf /backup/grafana_${TIMESTAMP}.tar.gz -C /source . \
    2>/dev/null || echo "Grafana 데이터를 건너뛰었습니다"

echo "  - Loki 데이터..."
docker run --rm -v gateway_loki_data:/source -v $(pwd)/${BACKUP_DIR}:/backup \
    alpine tar -czf /backup/loki_${TIMESTAMP}.tar.gz -C /source . \
    2>/dev/null || echo "Loki 데이터를 건너뛰었습니다"

echo "  - Uptime Kuma 데이터..."
if [ -d "./monitoring/uptime-kuma" ]; then
    tar -czf "${BACKUP_DIR}/uptime_kuma_${TIMESTAMP}.tar.gz" monitoring/uptime-kuma/
fi

# SSL 인증서 백업
echo "  - SSL 인증서..."
if [ -d "./traefik/ssl" ] && [ "$(ls -A ./traefik/ssl)" ]; then
    tar -czf "${BACKUP_DIR}/ssl_${TIMESTAMP}.tar.gz" traefik/ssl/
fi

# 로그 파일 백업 (최근 7일)
echo "  - 로그 파일들..."
if [ -d "./traefik/logs" ]; then
    find ./traefik/logs -name "*.log" -mtime -7 -exec tar -czf "${BACKUP_DIR}/logs_${TIMESTAMP}.tar.gz" {} + 2>/dev/null || echo "로그 파일이 없습니다"
fi

# 전체 백업 파일 생성
echo "📦 전체 백업 파일 생성 중..."
cd $BACKUP_DIR
tar -czf $BACKUP_FILE *_${TIMESTAMP}.tar.gz
rm *_${TIMESTAMP}.tar.gz
cd ..

# 백업 파일 정보
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)

echo ""
echo "✅ 백업이 완료되었습니다!"
echo "📁 백업 파일: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "📏 파일 크기: ${BACKUP_SIZE}"
echo ""
echo "🔄 복구 방법:"
echo "  ./scripts/restore.sh ${BACKUP_FILE}"
echo ""

# 오래된 백업 파일 정리 (30일 이상)
find $BACKUP_DIR -name "meritz_gateway_backup_*.tar.gz" -mtime +30 -delete 2>/dev/null || true
echo "🧹 30일 이상된 백업 파일들을 정리했습니다."
