#!/bin/bash

# Meritz Gateway 복구 스크립트
# 백업 파일로부터 데이터를 복구합니다

set -e

if [ $# -eq 0 ]; then
    echo "❌ 사용법: $0 <backup_file>"
    echo "예시: $0 meritz_gateway_backup_20241224_143000.tar.gz"
    echo ""
    echo "📁 사용 가능한 백업 파일들:"
    ls -la ./backups/meritz_gateway_backup_*.tar.gz 2>/dev/null || echo "백업 파일이 없습니다."
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="./restore_temp"

# 백업 파일 경로 확인
if [ ! -f "./backups/$BACKUP_FILE" ] && [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 백업 파일을 찾을 수 없습니다: $BACKUP_FILE"
    exit 1
fi

# 파일 경로 정규화
if [ -f "./backups/$BACKUP_FILE" ]; then
    BACKUP_FILE="./backups/$BACKUP_FILE"
fi

echo "🔄 Meritz Gateway 복구를 시작합니다..."
echo "📁 백업 파일: $BACKUP_FILE"

echo ""
read -p "⚠️  현재 데이터가 덮어쓰여집니다. 계속하시겠습니까? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 복구가 취소되었습니다."
    exit 1
fi

# 임시 복구 디렉토리 생성
echo "📂 임시 복구 디렉토리 생성 중..."
rm -rf $RESTORE_DIR
mkdir -p $RESTORE_DIR

# 백업 파일 압축 해제
echo "📦 백업 파일 압축 해제 중..."
tar -xzf "$BACKUP_FILE" -C $RESTORE_DIR

# 서비스 중지
echo "🛑 서비스 중지 중..."
./scripts/stop.sh || echo "서비스가 이미 중지되어 있습니다."

# 설정 파일 복구
echo "⚙️  설정 파일 복구 중..."
for config_file in $RESTORE_DIR/config_*.tar.gz; do
    if [ -f "$config_file" ]; then
        echo "  - 설정 파일 복구..."
        tar -xzf "$config_file" -C ./ --overwrite
        break
    fi
done

# Docker 볼륨 복구
echo "💾 Docker 볼륨 복구 중..."

# Prometheus 데이터 복구
for prom_file in $RESTORE_DIR/prometheus_*.tar.gz; do
    if [ -f "$prom_file" ]; then
        echo "  - Prometheus 데이터 복구..."
        docker volume create gateway_prometheus_data
        docker run --rm -v gateway_prometheus_data:/target -v $(pwd)/$RESTORE_DIR:/source \
            alpine tar -xzf "/source/$(basename $prom_file)" -C /target
        break
    fi
done

# Grafana 데이터 복구
for grafana_file in $RESTORE_DIR/grafana_*.tar.gz; do
    if [ -f "$grafana_file" ]; then
        echo "  - Grafana 데이터 복구..."
        docker volume create gateway_grafana_data
        docker run --rm -v gateway_grafana_data:/target -v $(pwd)/$RESTORE_DIR:/source \
            alpine tar -xzf "/source/$(basename $grafana_file)" -C /target
        break
    fi
done

# Loki 데이터 복구
for loki_file in $RESTORE_DIR/loki_*.tar.gz; do
    if [ -f "$loki_file" ]; then
        echo "  - Loki 데이터 복구..."
        docker volume create gateway_loki_data
        docker run --rm -v gateway_loki_data:/target -v $(pwd)/$RESTORE_DIR:/source \
            alpine tar -xzf "/source/$(basename $loki_file)" -C /target
        break
    fi
done

# Uptime Kuma 데이터 복구
for uptime_file in $RESTORE_DIR/uptime_kuma_*.tar.gz; do
    if [ -f "$uptime_file" ]; then
        echo "  - Uptime Kuma 데이터 복구..."
        tar -xzf "$uptime_file" -C ./ --overwrite
        break
    fi
done

# SSL 인증서 복구
for ssl_file in $RESTORE_DIR/ssl_*.tar.gz; do
    if [ -f "$ssl_file" ]; then
        echo "  - SSL 인증서 복구..."
        mkdir -p ./traefik/ssl
        tar -xzf "$ssl_file" -C ./ --overwrite
        chmod 600 ./traefik/ssl/*
        break
    fi
done

# 로그 파일 복구
for log_file in $RESTORE_DIR/logs_*.tar.gz; do
    if [ -f "$log_file" ]; then
        echo "  - 로그 파일 복구..."
        mkdir -p ./traefik/logs
        tar -xzf "$log_file" -C ./ --overwrite
        break
    fi
done

# 임시 디렉토리 정리
echo "🧹 임시 파일 정리 중..."
rm -rf $RESTORE_DIR

# 권한 설정
echo "🔐 파일 권한 설정 중..."
chmod +x ./scripts/*.sh
chmod 600 ./traefik/ssl/* 2>/dev/null || true

echo ""
echo "✅ 복구가 완료되었습니다!"
echo ""
echo "🚀 서비스를 시작하려면:"
echo "  ./scripts/start.sh"
echo ""
echo "📋 복구된 항목들:"
echo "  - 설정 파일들"
echo "  - Prometheus 데이터"
echo "  - Grafana 대시보드"
echo "  - Loki 로그 데이터"
echo "  - SSL 인증서"
echo "  - 모니터링 설정"
