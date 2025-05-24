#!/bin/bash

# 문제가 있는 서비스들을 재시작하는 스크립트

echo "🔧 문제가 있는 서비스들을 재시작합니다..."
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Traefik 재시작
echo -e "${BLUE}[진행중]${NC} Traefik 재시작 중..."
cd /Users/gossing/WorkPlace/infra-app/gateway
docker compose down
sleep 2
docker compose up -d
echo -e "${GREEN}[완료]${NC} Traefik 재시작 완료"
echo ""

# Loki 재시작
echo -e "${BLUE}[진행중]${NC} Loki 재시작 중..."
cd /Users/gossing/WorkPlace/infra-app/loki
docker compose down
sleep 2
docker compose up -d
echo -e "${GREEN}[완료]${NC} Loki 재시작 완료"
echo ""

# 재시작 대기
echo "서비스가 준비될 때까지 대기 중..."
sleep 10

# 헬스체크 수행
echo ""
echo "🔍 헬스체크 수행 중..."
echo ""

# Traefik 헬스체크
echo "Traefik 상태 확인:"
if curl -f -s "http://localhost:10000/api/overview" > /dev/null 2>&1; then
    echo -e "✅ Traefik API: ${GREEN}정상${NC}"
else
    echo -e "❌ Traefik API: ${RED}확인 필요${NC}"
    echo "로그 확인:"
    docker logs meritz-traefik --tail 10
fi
echo ""

# Loki 헬스체크
echo "Loki 상태 확인:"
if curl -f -s "http://localhost:10003/ready" > /dev/null 2>&1; then
    echo -e "✅ Loki: ${GREEN}정상${NC}"
else
    echo -e "❌ Loki: ${RED}확인 필요${NC}"
    echo "로그 확인:"
    docker logs meritz-loki --tail 10
fi
echo ""

# 전체 상태 확인
echo "📊 전체 서비스 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep meritz || true
