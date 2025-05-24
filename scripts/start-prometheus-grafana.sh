#!/bin/bash

# Prometheus와 Grafana를 순서대로 시작하는 스크립트

set -e

echo "🚀 Prometheus와 Grafana를 시작합니다..."
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# infra-app 디렉토리로 이동
cd /Users/gossing/WorkPlace/infra-app

# Prometheus 시작
echo -e "${BLUE}[진행중]${NC} Prometheus 시작 중..."
cd prometheus
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi
echo -e "${GREEN}[완료]${NC} Prometheus 시작 완료"
echo ""

# Prometheus가 준비될 때까지 대기
echo "Prometheus가 준비될 때까지 대기 중..."
sleep 10

# Prometheus 상태 확인
if curl -f -s "http://localhost:10001" > /dev/null 2>&1; then
    echo -e "✅ Prometheus (포트 10001): ${GREEN}정상${NC}"
else
    echo -e "❌ Prometheus (포트 10001): ${RED}확인 필요${NC}"
fi
echo ""

# Grafana 시작
cd ..
echo -e "${BLUE}[진행중]${NC} Grafana 시작 중..."
cd grafana
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi
echo -e "${GREEN}[완료]${NC} Grafana 시작 완료"
echo ""

# Grafana가 준비될 때까지 대기
echo "Grafana가 준비될 때까지 대기 중..."
sleep 10

# Grafana 상태 확인
if curl -f -s "http://localhost:10002" > /dev/null 2>&1; then
    echo -e "✅ Grafana (포트 10002): ${GREEN}정상${NC}"
else
    echo -e "❌ Grafana (포트 10002): ${RED}확인 필요${NC}"
fi

echo ""
echo "📊 서비스 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "prometheus|grafana|loki" || true

echo ""
echo "📊 접속 정보:"
echo "  - Prometheus: http://localhost:10001"
echo "  - Grafana: http://localhost:10002 (admin/admin123)"
echo "  - Loki: http://localhost:10003"
