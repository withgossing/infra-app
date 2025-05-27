#!/bin/bash

# 전체 인프라 서비스 헬스체크 스크립트
# 사용법: ./scripts/health-check.sh [--detailed] [--json]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 옵션 파라미터
DETAILED=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed)
            DETAILED=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--detailed] [--json]"
            exit 1
            ;;
    esac
done

# 로그 함수
log_info() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${GREEN}[✅]${NC} $1"
    fi
}

log_warning() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${YELLOW}[⚠️]${NC} $1"
    fi
}

log_error() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${RED}[❌]${NC} $1"
    fi
}

# JSON 결과 저장 배열
declare -a json_results=()

# 헬스체크 함수
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    local timeout=${4:-10}
    local description=$5
    
    local status="UNKNOWN"
    local response_time="N/A"
    local error_message=""
    local start_time
    local end_time
    local response_code
    
    start_time=$(date +%s%N)
    
    # HTTP 헬스체크
    if response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time $timeout "$url" 2>/dev/null); then
        end_time=$(date +%s%N)
        response_time=$(( (end_time - start_time) / 1000000 ))  # 밀리초 변환
        
        if [ "$response_code" -eq "$expected_status" ]; then
            status="HEALTHY"
            log_success "$service_name: $description - ${response_time}ms"
        else
            status="UNHEALTHY"
            error_message="HTTP $response_code (expected $expected_status)"
            log_error "$service_name: $description - $error_message"
        fi
    else
        end_time=$(date +%s%N)
        response_time=$(( (end_time - start_time) / 1000000 ))
        status="UNHEALTHY"
        error_message="Connection failed or timeout"
        log_error "$service_name: $description - $error_message"
    fi
    
    # JSON 결과 추가
    if [ "$JSON_OUTPUT" = true ]; then
        json_results+=("$(printf '{"service":"%s","description":"%s","status":"%s","response_time_ms":%d,"error":"%s","url":"%s"}' \
            "$service_name" "$description" "$status" "$response_time" "$error_message" "$url")")
    fi
    
    return $([ "$status" = "HEALTHY" ] && echo 0 || echo 1)
}

# 포트 연결 체크 함수
check_port() {
    local service_name=$1
    local host=$2
    local port=$3
    local description=$4
    
    local status="UNKNOWN"
    local error_message=""
    
    if nc -z -w5 "$host" "$port" 2>/dev/null; then
        status="HEALTHY"
        log_success "$service_name: $description - Port $port accessible"
    else
        status="UNHEALTHY"
        error_message="Port $port not accessible"
        log_error "$service_name: $description - $error_message"
    fi
    
    # JSON 결과 추가
    if [ "$JSON_OUTPUT" = true ]; then
        json_results+=("$(printf '{"service":"%s","description":"%s","status":"%s","port":%d,"error":"%s"}' \
            "$service_name" "$description" "$status" "$port" "$error_message")")
    fi
    
    return $([ "$status" = "HEALTHY" ] && echo 0 || echo 1)
}

# Redis 헬스체크 함수
check_redis() {
    local status="UNKNOWN"
    local error_message=""
    
    if redis-cli -h localhost -p 10200 ping 2>/dev/null | grep -q "PONG"; then
        status="HEALTHY"
        log_success "Redis: Master node - PING successful"
    else
        status="UNHEALTHY"
        error_message="Redis PING failed"
        log_error "Redis: Master node - $error_message"
    fi
    
    # JSON 결과 추가
    if [ "$JSON_OUTPUT" = true ]; then
        json_results+=("$(printf '{"service":"Redis","description":"Master node PING","status":"%s","error":"%s"}' \
            "$status" "$error_message")")
    fi
    
    return $([ "$status" = "HEALTHY" ] && echo 0 || echo 1)
}

# DNS 헬스체크 함수
check_dns() {
    local status="UNKNOWN"
    local error_message=""
    
    if nslookup google.com localhost -port=10600 >/dev/null 2>&1; then
        status="HEALTHY"
        log_success "CoreDNS: DNS resolution - External domain lookup successful"
    else
        status="UNHEALTHY"
        error_message="DNS resolution failed"
        log_error "CoreDNS: DNS resolution - $error_message"
    fi
    
    # JSON 결과 추가
    if [ "$JSON_OUTPUT" = true ]; then
        json_results+=("$(printf '{"service":"CoreDNS","description":"DNS resolution test","status":"%s","error":"%s"}' \
            "$status" "$error_message")")
    fi
    
    return $([ "$status" = "HEALTHY" ] && echo 0 || echo 1)
}

# 상세 서비스 정보 출력
show_detailed_info() {
    if [ "$DETAILED" = true ] && [ "$JSON_OUTPUT" = false ]; then
        echo ""
        log_info "📊 Detailed Service Information:"
        echo ""
        
        echo "🔐 Security Services:"
        echo "  • Keycloak Admin: http://localhost:10900/auth/admin/ (admin/admin123)"
        echo "  • Vault UI: http://localhost:10902/ui/ (Token: vault-root-token)"
        echo ""
        
        echo "🌐 Gateway & Networking:"
        echo "  • Kong Admin API: http://localhost:10301/"
        echo "  • Consul UI: http://localhost:10502/ui/"
        echo "  • CoreDNS: UDP/TCP port 10600"
        echo ""
        
        echo "📊 Monitoring & Observability:"
        echo "  • Prometheus: http://localhost:10000/"
        echo "  • Grafana: http://localhost:10001/ (admin/admin_password)"
        echo "  • Kibana: http://localhost:10102/"
        echo "  • Jaeger: http://localhost:10400/"
        echo ""
        
        echo "🚀 Data & Messaging:"
        echo "  • Redis: redis://localhost:10200"
        echo "  • Kafka UI: http://localhost:10703/"
        echo "  • Harbor: http://localhost:10800/ (admin/Harbor12345)"
        echo ""
    fi
}

# 메인 헬스체크 로직
main() {
    if [ "$JSON_OUTPUT" = false ]; then
        log_info "🏥 Infrastructure Health Check Starting..."
        log_info "📁 Working directory: $(pwd)"
        echo ""
    fi
    
    # 현재 디렉토리가 infra-app인지 확인
    if [[ ! "$(basename $(pwd))" == "infra-app" ]] && [ "$JSON_OUTPUT" = false ]; then
        log_warning "Not in infra-app directory, but continuing health check..."
    fi
    
    local healthy_count=0
    local total_count=0
    
    # 시작 시간 기록
    start_time=$(date +%s)
    
    if [ "$JSON_OUTPUT" = false ]; then
        log_info "🔍 Checking all infrastructure services..."
        echo ""
    fi
    
    # Security Services
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${CYAN}🔐 Security Services:${NC}"
    fi
    check_service "Keycloak" "http://localhost:10900/auth/health" 200 10 "Authentication Server" && ((healthy_count++))
    check_service "Vault" "http://localhost:10902/v1/sys/health" 200 10 "Secret Management" && ((healthy_count++))
    ((total_count+=2))
    
    # Gateway & Networking
    if [ "$JSON_OUTPUT" = false ]; then
        echo ""
        echo -e "${CYAN}🌐 Gateway & Networking:${NC}"
    fi
    check_service "Kong" "http://localhost:10301/status" 200 10 "API Gateway" && ((healthy_count++))
    check_service "Consul" "http://localhost:10502/v1/status/leader" 200 10 "Service Discovery" && ((healthy_count++))
    check_port "CoreDNS" "localhost" 10600 "DNS Server" && ((healthy_count++))
    if command -v nslookup >/dev/null 2>&1; then
        check_dns && ((healthy_count++))
        ((total_count++))
    fi
    ((total_count+=4))
    
    # Monitoring & Observability
    if [ "$JSON_OUTPUT" = false ]; then
        echo ""
        echo -e "${CYAN}📊 Monitoring & Observability:${NC}"
    fi
    check_service "Prometheus" "http://localhost:10000/-/healthy" 200 10 "Metrics Collection" && ((healthy_count++))
    check_service "Grafana" "http://localhost:10001/api/health" 200 10 "Metrics Visualization" && ((healthy_count++))
    check_service "Kibana" "http://localhost:10102/api/status" 200 10 "Log Visualization" && ((healthy_count++))
    check_service "Jaeger" "http://localhost:10400/api/services" 200 10 "Distributed Tracing" && ((healthy_count++))
    ((total_count+=4))
    
    # Data & Messaging
    if [ "$JSON_OUTPUT" = false ]; then
        echo ""
        echo -e "${CYAN}🚀 Data & Messaging:${NC}"
    fi
    if command -v redis-cli >/dev/null 2>&1; then
        check_redis && ((healthy_count++))
        ((total_count++))
    else
        check_port "Redis" "localhost" 10200 "Cache Server" && ((healthy_count++))
        ((total_count++))
    fi
    check_service "Kafka-UI" "http://localhost:10703/" 200 10 "Message Queue UI" && ((healthy_count++))
    check_service "Harbor" "http://localhost:10800/api/v2.0/health" 200 10 "Container Registry" && ((healthy_count++))
    ((total_count+=2))
    
    # Additional port checks
    if [ "$JSON_OUTPUT" = false ]; then
        echo ""
        echo -e "${CYAN}🔌 Additional Port Checks:${NC}"
    fi
    check_port "Elasticsearch" "localhost" 10100 "Search Engine" && ((healthy_count++))
    check_port "Logstash" "localhost" 10101 "Log Processing" && ((healthy_count++))
    ((total_count+=2))
    
    # 완료 시간 계산
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # 결과 출력
    if [ "$JSON_OUTPUT" = true ]; then
        # JSON 출력
        printf '{"timestamp":"%s","total_checks":%d,"healthy_services":%d,"unhealthy_services":%d,"health_percentage":%.1f,"duration_seconds":%d,"services":[%s]}\n' \
            "$(date -Iseconds)" \
            "$total_count" \
            "$healthy_count" \
            "$((total_count - healthy_count))" \
            "$(echo "scale=1; $healthy_count * 100 / $total_count" | bc -l)" \
            "$duration" \
            "$(IFS=','; echo "${json_results[*]}")"
    else
        echo ""
        echo "=================================================================="
        
        local health_percentage=$(echo "scale=1; $healthy_count * 100 / $total_count" | bc -l)
        
        if [ "$healthy_count" -eq "$total_count" ]; then
            log_success "🎉 All services are healthy! ($healthy_count/$total_count)"
            log_info "🏥 Overall Health: ${health_percentage}% - EXCELLENT"
        elif [ "$healthy_count" -gt $((total_count * 3 / 4)) ]; then
            log_warning "⚠️  Most services are healthy ($healthy_count/$total_count)"
            log_info "🏥 Overall Health: ${health_percentage}% - GOOD"
        elif [ "$healthy_count" -gt $((total_count / 2)) ]; then
            log_warning "⚠️  Some services need attention ($healthy_count/$total_count)"
            log_info "🏥 Overall Health: ${health_percentage}% - FAIR"
        else
            log_error "❌ Many services are unhealthy ($healthy_count/$total_count)"
            log_info "🏥 Overall Health: ${health_percentage}% - POOR"
        fi
        
        echo ""
        log_info "⏱️  Health check completed in ${duration}s"
        
        # 상세 정보 출력
        show_detailed_info
        
        # 문제 해결 팁
        if [ "$healthy_count" -lt "$total_count" ]; then
            echo ""
            log_info "🛠️  Troubleshooting Tips:"
            echo "  • Check if all services are started: ./scripts/status.sh"
            echo "  • View service logs: docker-compose logs -f [service-name]"
            echo "  • Restart failed services: cd [service-dir] && docker-compose restart"
            echo "  • Full restart: ./scripts/stop-all.sh && ./scripts/start-all.sh"
        fi
        
        echo ""
    fi
    
    # 종료 코드 설정
    if [ "$healthy_count" -eq "$total_count" ]; then
        exit 0
    else
        exit 1
    fi
}

# 인터럽트 시그널 처리
trap 'log_error "Health check interrupted by user"; exit 1' INT

# 메인 함수 실행
main "$@"
