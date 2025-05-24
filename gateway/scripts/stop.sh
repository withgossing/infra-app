#!/bin/bash

# Meritz Gateway 종료 스크립트
# 모든 서비스를 안전하게 종료합니다

set -e

echo "🛑 Meritz Gateway를 종료합니다..."

# 환경 변수 로드
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# 컨테이너 상태 확인
echo "📋 현재 실행 중인 컨테이너들:"
docker-compose ps

echo ""
read -p "정말로 모든 서비스를 종료하시겠습니까? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 서비스들을 차례대로 종료합니다..."
    
    # Graceful shutdown
    echo "📊 모니터링 서비스들 종료 중..."
    docker-compose stop grafana prometheus loki promtail jaeger uptime-kuma cadvisor node-exporter
    
    echo "🚪 게이트웨이 종료 중..."
    docker-compose stop traefik
    
    echo "🧹 기본 서비스 종료 중..."
    docker-compose stop default-app
    
    echo "🗑️  컨테이너 제거 중..."
    docker-compose down
    
    echo ""
    echo "✅ 모든 서비스가 성공적으로 종료되었습니다."
    echo ""
    echo "💡 참고사항:"
    echo "  - 데이터는 Docker 볼륨에 보존됩니다"
    echo "  - 재시작: ./scripts/start.sh"
    echo "  - 완전 삭제: ./scripts/cleanup.sh"
else
    echo "❌ 종료가 취소되었습니다."
fi
