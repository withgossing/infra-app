#!/bin/bash

# 문제가 있는 서비스의 상태와 로그를 확인하는 스크립트

echo "🔍 문제가 있는 서비스 확인 중..."
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Traefik 상태 확인
echo -e "${BLUE}=== Traefik 상태 확인 ===${NC}"
echo "컨테이너 상태:"
docker ps -a --filter "name=meritz-traefik" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "최근 로그 (마지막 20줄):"
docker logs meritz-traefik --tail 20 2>&1 || echo "로그를 가져올 수 없습니다."
echo ""

# Loki 상태 확인
echo -e "${BLUE}=== Loki 상태 확인 ===${NC}"
echo "컨테이너 상태:"
docker ps -a --filter "name=meritz-loki" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "최근 로그 (마지막 20줄):"
docker logs meritz-loki --tail 20 2>&1 || echo "로그를 가져올 수 없습니다."
echo ""

# 포트 사용 확인
echo -e "${BLUE}=== 포트 사용 상태 ===${NC}"
echo "포트 10000 (Traefik):"
lsof -i :10000 2>/dev/null || echo "포트 10000이 사용되지 않고 있습니다."
echo ""
echo "포트 10003 (Loki):"
lsof -i :10003 2>/dev/null || echo "포트 10003이 사용되지 않고 있습니다."
echo ""

# 헬스체크 URL 테스트
echo -e "${BLUE}=== 헬스체크 URL 테스트 ===${NC}"
echo "Traefik API:"
curl -v http://localhost:10000/api/overview 2>&1 | grep -E "(< HTTP|Connected to)" || echo "연결 실패"
echo ""
echo "Loki Ready 엔드포인트:"
curl -v http://localhost:10003/ready 2>&1 | grep -E "(< HTTP|Connected to)" || echo "연결 실패"
