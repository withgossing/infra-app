#!/bin/bash

# Meritz 인프라 초기 설정 스크립트
# 모든 서비스의 권한 및 환경을 설정합니다

set -e

echo "🔧 Meritz 인프라 초기 설정을 시작합니다..."
echo "📅 $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

progress() {
    echo -e "${BLUE}[진행중]${NC} $1"
}

success() {
    echo -e "${GREEN}[완료]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[주의]${NC} $1"
}

error() {
    echo -e "${RED}[오류]${NC} $1"
}

# 1. Docker 환경 확인
progress "Docker 환경 확인 중..."

if ! command -v docker &> /dev/null; then
    error "Docker가 설치되지 않았습니다."
    exit 1
fi

if ! docker ps &> /dev/null; then
    error "Docker 서비스가 실행되지 않았습니다."
    exit 1
fi

success "Docker 환경 확인 완료"

# 2. 스크립트 실행 권한 설정
progress "스크립트 실행 권한 설정 중..."

chmod +x scripts/*.sh 2>/dev/null || warning "메인 스크립트 권한 설정 실패"
chmod +x gateway/scripts/*.sh 2>/dev/null || warning "Gateway 스크립트 권한 설정 실패"

success "스크립트 실행 권한 설정 완료"

# 3. Docker 네트워크 생성
progress "Docker 네트워크 생성 중..."

docker network create meritz-network 2>/dev/null || warning "meritz-network가 이미 존재합니다"
success "Docker 네트워크 설정 완료"

# 4. 필수 디렉토리 생성
progress "필수 디렉토리 생성 중..."

DIRECTORIES=(
    "gateway/traefik/ssl"
    "gateway/traefik/logs"
    "gateway/default-pages"
    "uptime-kuma/data"
)

for dir in "${DIRECTORIES[@]}"; do
    mkdir -p "$dir"
done

# 권한 설정
chmod 700 gateway/traefik/ssl 2>/dev/null || warning "SSL 디렉토리 권한 설정 실패"
touch gateway/traefik/logs/traefik.log gateway/traefik/logs/access.log 2>/dev/null || warning "로그 파일 생성 실패"

success "필수 디렉토리 생성 완료"

# 5. 환경 변수 파일 확인
progress "환경 변수 파일 확인 중..."

SERVICES=(
    "gateway"
    "prometheus"
    "grafana"
    "loki"
    "jaeger"
    "uptime-kuma"
    "node-exporter"
    "cadvisor"
    "promtail"
)

for service in "${SERVICES[@]}"; do
    if [ -f "${service}/.env" ]; then
        success "${service}: 환경 변수 파일 존재"
    else
        warning "${service}: 환경 변수 파일 없음"
    fi
done

# 6. 설정 파일 유효성 검사
progress "설정 파일 유효성 검사 중..."

for service in "${SERVICES[@]}"; do
    if [ -f "${service}/docker-compose.yml" ]; then
        cd "${service}"
        if docker-compose config &> /dev/null; then
            success "${service}: Docker Compose 설정 유효"
        else
            error "${service}: Docker Compose 설정 오류"
        fi
        cd ..
    else
        error "${service}: docker-compose.yml 파일 없음"
    fi
done

# 7. 포트 충돌 확인
progress "포트 충돌 확인 중..."

PORTS=(80 443 1000 1002 1003 1004 1005 1006 1007 1008 1009)
CONFLICTS=0

for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        warning "포트 $port가 이미 사용 중입니다"
        ((CONFLICTS++))
    fi
done

if [ $CONFLICTS -eq 0 ]; then
    success "포트 충돌 없음"
else
    warning "$CONFLICTS개 포트에서 충돌 발견"
fi

# 8. 시스템 리소스 확인
progress "시스템 리소스 확인 중..."

# 메모리 확인
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
if [ "$TOTAL_MEM" -lt 4096 ]; then
    warning "권장 메모리(4GB) 미만: ${TOTAL_MEM}MB"
else
    success "메모리: ${TOTAL_MEM}MB (충분)"
fi

# 디스크 공간 확인
AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 20971520 ]; then  # 20GB in KB
    warning "권장 디스크 공간(20GB) 미만"
else
    success "디스크 공간: 충분"
fi

# 9. 서비스별 개별 체크
progress "서비스별 상세 확인 중..."

echo ""
echo "📊 서비스별 상태:"
echo "=================================================="

for service in "${SERVICES[@]}"; do
    if [ -d "${service}" ]; then
        printf "%-15s: " "$service"
        
        # Docker Compose 파일 존재 확인
        if [ -f "${service}/docker-compose.yml" ]; then
            echo -e "${GREEN}✅ 준비됨${NC}"
        else
            echo -e "${RED}❌ 설정 없음${NC}"
        fi
    else
        printf "%-15s: " "$service"
        echo -e "${RED}❌ 폴더 없음${NC}"
    fi
done

echo ""
echo "========================="
echo -e "${GREEN}🎉 초기 설정이 완료되었습니다!${NC}"
echo ""
echo "📋 다음 단계:"
echo "   1. DNS 설정: A 레코드로 *.meritz.com → 서버 IP"
echo "   2. 환경 변수 확인: 각 서비스의 .env 파일"
echo "   3. 전체 서비스 시작: ./scripts/start-all.sh"
echo ""
echo "🚀 빠른 시작:"
echo "   ./scripts/start-all.sh"
echo ""
echo "📊 상태 확인:"
echo "   ./scripts/status.sh"
echo ""
echo "🔧 개별 서비스 관리:"
echo "   cd [service-name] && docker-compose up -d"
echo ""
echo "📚 자세한 사용법:"
echo "   각 서비스 폴더의 README.md 참조"
