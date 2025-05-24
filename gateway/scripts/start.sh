#!/bin/bash

# Meritz Gateway 시작 스크립트
# 모든 서비스를 안전하게 시작합니다

set -e

echo "🚀 Meritz Gateway를 시작합니다..."

# 환경 변수 로드
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Docker 네트워크 생성 (존재하지 않는 경우)
echo "📡 Docker 네트워크 설정 중..."
docker network create meritz-network 2>/dev/null || echo "네트워크 'meritz-network'가 이미 존재합니다."

# SSL 인증서 디렉토리 권한 설정
echo "🔐 SSL 인증서 디렉토리 설정 중..."
mkdir -p ./traefik/ssl
chmod 600 ./traefik/ssl

# 로그 디렉토리 생성
echo "📝 로그 디렉토리 설정 중..."
mkdir -p ./traefik/logs
touch ./traefik/logs/traefik.log
touch ./traefik/logs/access.log

# Uptime Kuma 데이터 디렉토리 생성
echo "📊 모니터링 디렉토리 설정 중..."
mkdir -p ./monitoring/uptime-kuma

# Docker Compose로 서비스 시작
echo "🐳 Docker 컨테이너들을 시작합니다..."
docker-compose up -d

# 서비스 상태 확인
echo "⏳ 서비스 시작을 기다리는 중..."
sleep 10

echo "🔍 서비스 상태를 확인합니다..."
docker-compose ps

# 헬스체크
echo "💚 헬스체크를 수행합니다..."

# Traefik 헬스체크
if curl -f http://localhost:1000/ping > /dev/null 2>&1; then
    echo "✅ Traefik 게이트웨이가 정상 작동 중입니다"
else
    echo "❌ Traefik 게이트웨이에 문제가 있습니다"
fi

# Prometheus 헬스체크  
if curl -f http://localhost:1002/-/healthy > /dev/null 2>&1; then
    echo "✅ Prometheus가 정상 작동 중입니다"
else
    echo "❌ Prometheus에 문제가 있습니다"
fi

# Grafana 헬스체크
if curl -f http://localhost:1003/api/health > /dev/null 2>&1; then
    echo "✅ Grafana가 정상 작동 중입니다"
else
    echo "❌ Grafana에 문제가 있습니다"
fi

echo ""
echo "🎉 Meritz Gateway가 성공적으로 시작되었습니다!"
echo ""
echo "📊 접속 정보:"
echo "  - Traefik 대시보드: http://localhost:1000"
echo "  - Prometheus: http://localhost:1002"  
echo "  - Grafana: http://localhost:1003 (admin/admin123)"
echo "  - Uptime Kuma: http://localhost:1009"
echo "  - Jaeger: http://localhost:1005"
echo ""
echo "🌐 도메인 접속 (DNS 설정 후):"
echo "  - https://traefik.meritz.com"
echo "  - https://grafana.meritz.com"
echo "  - https://prometheus.meritz.com"
echo "  - https://uptime.meritz.com"
echo "  - https://jaeger.meritz.com"
echo ""
echo "🔧 로그 확인: docker-compose logs -f [service-name]"
echo "🛑 종료: ./scripts/stop.sh"
