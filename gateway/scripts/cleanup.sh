#!/bin/bash

# Meritz Gateway 완전 정리 스크립트
# 모든 컨테이너, 볼륨, 네트워크를 제거합니다

set -e

echo "🧹 Meritz Gateway 완전 정리를 시작합니다..."
echo "⚠️  경고: 이 작업은 모든 데이터를 삭제합니다!"

echo ""
read -p "정말로 모든 데이터를 삭제하시겠습니까? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "마지막 확인: 모든 모니터링 데이터가 삭제됩니다. 계속하시겠습니까? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 서비스 중지 및 컨테이너 제거
        echo "🛑 서비스 중지 중..."
        docker-compose down --remove-orphans
        
        # 볼륨 제거
        echo "💾 볼륨 제거 중..."
        docker volume rm gateway_prometheus_data 2>/dev/null || echo "prometheus_data 볼륨이 존재하지 않습니다"
        docker volume rm gateway_grafana_data 2>/dev/null || echo "grafana_data 볼륨이 존재하지 않습니다"
        docker volume rm gateway_loki_data 2>/dev/null || echo "loki_data 볼륨이 존재하지 않습니다"
        docker volume rm gateway_jaeger_data 2>/dev/null || echo "jaeger_data 볼륨이 존재하지 않습니다"
        
        # 이미지 제거 (선택적)
        echo ""
        read -p "Docker 이미지도 제거하시겠습니까? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  이미지 제거 중..."
            docker image rm traefik:v3.0 2>/dev/null || echo "Traefik 이미지가 존재하지 않습니다"
            docker image rm prom/prometheus:v2.47.0 2>/dev/null || echo "Prometheus 이미지가 존재하지 않습니다"
            docker image rm grafana/grafana:10.2.0 2>/dev/null || echo "Grafana 이미지가 존재하지 않습니다"
            docker image rm grafana/loki:2.9.0 2>/dev/null || echo "Loki 이미지가 존재하지 않습니다"
            docker image rm grafana/promtail:2.9.0 2>/dev/null || echo "Promtail 이미지가 존재하지 않습니다"
            docker image rm jaegertracing/all-in-one:1.50 2>/dev/null || echo "Jaeger 이미지가 존재하지 않습니다"
            docker image rm prom/node-exporter:v1.6.0 2>/dev/null || echo "Node Exporter 이미지가 존재하지 않습니다"
            docker image rm gcr.io/cadvisor/cadvisor:v0.47.0 2>/dev/null || echo "cAdvisor 이미지가 존재하지 않습니다"
            docker image rm louislam/uptime-kuma:1.23.0 2>/dev/null || echo "Uptime Kuma 이미지가 존재하지 않습니다"
            docker image rm nginx:alpine 2>/dev/null || echo "Nginx 이미지가 존재하지 않습니다"
        fi
        
        # 로컬 데이터 제거
        echo "📁 로컬 데이터 제거 중..."
        rm -rf ./traefik/ssl/*
        rm -rf ./traefik/logs/*
        rm -rf ./monitoring/uptime-kuma/*
        
        # 네트워크 제거 (다른 서비스가 사용 중일 수 있으므로 조건부)
        echo "🌐 네트워크 정리 중..."
        docker network rm meritz-network 2>/dev/null || echo "meritz-network가 다른 서비스에서 사용 중이거나 존재하지 않습니다"
        
        # 사용하지 않는 리소스 정리
        echo "🧽 Docker 시스템 정리 중..."
        docker system prune -f
        
        echo ""
        echo "✅ 완전 정리가 완료되었습니다!"
        echo ""
        echo "🔄 재설치하려면:"
        echo "  ./scripts/start.sh"
        
    else
        echo "❌ 정리가 취소되었습니다."
    fi
else
    echo "❌ 정리가 취소되었습니다."
fi
