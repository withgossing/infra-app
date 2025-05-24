#!/bin/bash

# Meritz Gateway 초기 설정 스크립트
# 프로젝트 설치 및 초기 구성을 수행합니다

set -e

echo "🚀 Meritz Gateway 초기 설정을 시작합니다..."
echo "📅 $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수: 진행 상황 표시
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

# 1. 환경 요구사항 확인
echo "🔍 시스템 요구사항 확인..."

# Docker 설치 확인
if ! command -v docker &> /dev/null; then
    error "Docker가 설치되지 않았습니다. Docker를 먼저 설치해주세요."
    exit 1
fi
success "Docker 설치 확인됨: $(docker --version | cut -d' ' -f3)"

# Docker Compose 설치 확인
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose가 설치되지 않았습니다. Docker Compose를 먼저 설치해주세요."
    exit 1
fi
success "Docker Compose 설치 확인됨: $(docker-compose --version | cut -d' ' -f4)"

# Docker 서비스 실행 확인
if ! docker ps &> /dev/null; then
    error "Docker 서비스가 실행되지 않았습니다. Docker를 시작해주세요."
    exit 1
fi
success "Docker 서비스 실행 중"

# 2. 디렉토리 권한 설정
progress "파일 권한 설정 중..."

# 스크립트 실행 권한 부여
chmod +x scripts/*.sh 2>/dev/null || warning "일부 스크립트 권한 설정에 실패했습니다"
success "스크립트 실행 권한 설정 완료"

# 디렉토리 생성 및 권한 설정
mkdir -p traefik/ssl traefik/logs monitoring/uptime-kuma
chmod 700 traefik/ssl 2>/dev/null || warning "SSL 디렉토리 권한 설정에 실패했습니다"
touch traefik/logs/traefik.log traefik/logs/access.log 2>/dev/null || warning "로그 파일 생성에 실패했습니다"
success "디렉토리 및 파일 권한 설정 완료"

# 3. 환경 변수 설정 확인
progress "환경 변수 설정 확인..."

if [ ! -f .env ]; then
    warning ".env 파일이 없습니다. 기본값을 사용합니다."
else
    success ".env 파일 존재 확인"
    
    # 환경 변수 유효성 검사
    source .env
    if [ -z "$DOMAIN" ]; then
        warning "DOMAIN 환경 변수가 설정되지 않았습니다"
    fi
    if [ -z "$EMAIL" ]; then
        warning "EMAIL 환경 변수가 설정되지 않았습니다"
    fi
fi

# 4. 포트 충돌 확인
progress "포트 충돌 확인..."

PORTS=(80 443 1000 1002 1003 1004 1005 1007 1008 1009)
for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        warning "포트 $port가 이미 사용 중입니다"
    fi
done
success "포트 상태 확인 완료"

# 5. Docker 네트워크 생성
progress "Docker 네트워크 설정..."

if ! docker network ls | grep -q "meritz-network"; then
    docker network create meritz-network
    success "meritz-network 생성 완료"
else
    success "meritz-network 이미 존재함"
fi

# 6. 필수 디렉토리 생성
progress "필수 디렉토리 생성..."

REQUIRED_DIRS=(
    "traefik/ssl"
    "traefik/logs"
    "traefik/config/dynamic"
    "monitoring/prometheus"
    "monitoring/grafana/provisioning/datasources"
    "monitoring/grafana/provisioning/dashboards"
    "monitoring/grafana/dashboards"
    "monitoring/loki"
    "monitoring/promtail"
    "monitoring/default-pages"
    "monitoring/uptime-kuma"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    mkdir -p "$dir"
done
success "필수 디렉토리 생성 완료"

# 7. 설정 파일 유효성 검사
progress "설정 파일 유효성 검사..."

# Docker Compose 파일 검사
if docker-compose config &> /dev/null; then
    success "docker-compose.yml 설정 유효함"
else
    error "docker-compose.yml 설정에 오류가 있습니다"
    docker-compose config
    exit 1
fi

# Traefik 설정 파일 검사
if [ -f "traefik/config/traefik.yml" ]; then
    success "Traefik 설정 파일 존재 확인"
else
    error "Traefik 설정 파일이 없습니다"
    exit 1
fi

# 8. 초기 이미지 다운로드 (선택적)
echo ""
read -p "Docker 이미지를 미리 다운로드하시겠습니까? (권장) (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    progress "Docker 이미지 다운로드 중..."
    docker-compose pull
    success "Docker 이미지 다운로드 완료"
fi

# 9. 시스템 리소스 확인
progress "시스템 리소스 확인..."

# 메모리 확인
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
if [ "$TOTAL_MEM" -lt 4096 ]; then
    warning "권장 메모리(4GB) 미만입니다. 현재: ${TOTAL_MEM}MB"
else
    success "메모리: ${TOTAL_MEM}MB (충분함)"
fi

# 디스크 공간 확인
AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 20971520 ]; then  # 20GB in KB
    warning "권장 디스크 공간(20GB) 미만입니다"
else
    success "디스크 공간: 충분함"
fi

# 10. 방화벽 설정 안내
echo ""
echo "🔥 방화벽 설정 안내:"
echo "   다음 포트들이 열려있어야 합니다:"
echo "   - 80/tcp (HTTP)"
echo "   - 443/tcp (HTTPS)"
echo "   - 1000-1009/tcp (관리 도구, 로컬에서만)"
echo ""

# 11. 초기 설정 완료
echo "========================="
echo -e "${GREEN}🎉 초기 설정이 완료되었습니다!${NC}"
echo ""
echo "📋 다음 단계:"
echo "   1. 도메인 DNS 설정 (A 레코드를 서버 IP로)"
echo "   2. .env 파일에서 도메인과 이메일 설정"
echo "   3. ./scripts/start.sh 실행"
echo ""
echo "🌐 서비스 시작 후 접속 주소:"
echo "   - Traefik 대시보드: http://localhost:1000"
echo "   - Grafana: http://localhost:1003 (admin/admin123)"
echo "   - Prometheus: http://localhost:1002"
echo ""
echo "📚 자세한 사용법: README.md 참조"
echo "🆘 문제 발생 시: ./scripts/health-check.sh 실행"
echo ""
echo "🚀 시작하려면: ./scripts/start.sh"
