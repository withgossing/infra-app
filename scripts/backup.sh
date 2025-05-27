#!/bin/bash

# 인프라 서비스 백업 스크립트
# 사용법: ./scripts/backup.sh [--output-dir /path/to/backup] [--compress] [--exclude logs]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 기본값 설정
BACKUP_DIR="./backups"
COMPRESS=false
EXCLUDE_LOGS=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="infra-backup-$TIMESTAMP"

# 파라미터 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        --exclude-logs)
            EXCLUDE_LOGS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--output-dir /path/to/backup] [--compress] [--exclude-logs]"
            exit 1
            ;;
    esac
done

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌]${NC} $1"
}

# 백업 디렉토리 생성
create_backup_dir() {
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    
    log_info "Creating backup directory: $backup_path"
    mkdir -p "$backup_path"
    
    echo "$backup_path"
}

# 데이터베이스 백업 함수
backup_database() {
    local service_name=$1
    local container_name=$2
    local db_name=$3
    local db_user=$4
    local backup_path=$5
    
    log_info "Backing up $service_name database..."
    
    if docker ps --format "{{.Names}}" | grep -q "$container_name"; then
        local backup_file="$backup_path/${service_name}_db_${TIMESTAMP}.sql"
        
        if docker exec "$container_name" pg_dump -U "$db_user" -d "$db_name" > "$backup_file" 2>/dev/null; then
            log_success "$service_name database backed up to $backup_file"
        else
            log_error "Failed to backup $service_name database"
        fi
    else
        log_warning "$service_name database container not running, skipping backup"
    fi
}

# 볼륨 백업 함수
backup_volume() {
    local service_name=$1
    local volume_pattern=$2
    local backup_path=$3
    
    log_info "Backing up $service_name volumes..."
    
    local volumes=$(docker volume ls --format "{{.Name}}" | grep "$volume_pattern" || true)
    
    if [ -z "$volumes" ]; then
        log_warning "No volumes found for $service_name"
        return
    fi
    
    local volume_backup_dir="$backup_path/volumes/$service_name"
    mkdir -p "$volume_backup_dir"
    
    echo "$volumes" | while read volume; do
        if [ ! -z "$volume" ]; then
            log_info "Backing up volume: $volume"
            
            local volume_tar="$volume_backup_dir/${volume}_${TIMESTAMP}.tar"
            
            # 임시 컨테이너를 사용하여 볼륨 데이터 백업
            if docker run --rm \
                -v "$volume:/backup-source" \
                -v "$volume_backup_dir:/backup-dest" \
                alpine:latest \
                tar -cf "/backup-dest/$(basename $volume_tar)" -C /backup-source . 2>/dev/null; then
                log_success "Volume $volume backed up"
            else
                log_error "Failed to backup volume $volume"
            fi
        fi
    done
}

# 설정 파일 백업 함수
backup_configs() {
    local backup_path=$1
    
    log_info "Backing up configuration files..."
    
    local config_backup_dir="$backup_path/configs"
    mkdir -p "$config_backup_dir"
    
    # 각 서비스의 설정 파일 백업
    local services=("security" "gateway" "monitoring" "logging" "cache" "tracing" "service-discovery" "dns" "messaging" "registry")
    
    for service in "${services[@]}"; do
        if [ -d "$service/config" ]; then
            log_info "Backing up $service configurations..."
            cp -r "$service/config" "$config_backup_dir/$service" 2>/dev/null || log_warning "No config directory for $service"
        fi
        
        # docker-compose.yml 파일도 백업
        if [ -f "$service/docker-compose.yml" ]; then
            cp "$service/docker-compose.yml" "$config_backup_dir/${service}_docker-compose.yml" 2>/dev/null
        fi
    done
    
    # 루트 설정 파일들 백업
    for file in "rule.md" "README.md"; do
        if [ -f "../$file" ]; then
            cp "../$file" "$config_backup_dir/" 2>/dev/null
        fi
    done
    
    log_success "Configuration files backed up"
}

# Vault 시크릿 백업 함수
backup_vault_secrets() {
    local backup_path=$1
    
    log_info "Backing up Vault secrets..."
    
    if ! command -v vault >/dev/null 2>&1; then
        log_warning "Vault CLI not found, skipping secrets backup"
        return
    fi
    
    # Vault가 실행 중인지 확인
    if ! docker ps --format "{{.Names}}" | grep -q "vault"; then
        log_warning "Vault container not running, skipping secrets backup"
        return
    fi
    
    local vault_backup_dir="$backup_path/vault"
    mkdir -p "$vault_backup_dir"
    
    # 환경 변수 설정
    export VAULT_ADDR="http://localhost:10902"
    export VAULT_TOKEN="vault-root-token"
    
    # 시크릿 백업
    local secrets=("secret/bank-app" "secret/sec-app" "secret/infra")
    
    for secret_path in "${secrets[@]}"; do
        local output_file="$vault_backup_dir/$(echo $secret_path | tr '/' '_').json"
        
        if vault kv get -format=json "$secret_path" > "$output_file" 2>/dev/null; then
            log_success "Vault secret $secret_path backed up"
        else
            log_warning "Failed to backup Vault secret $secret_path"
        fi
    done
    
    # Vault 정책 백업
    vault policy list > "$vault_backup_dir/policies.txt" 2>/dev/null || log_warning "Failed to list Vault policies"
    
    log_success "Vault secrets backed up"
}

# Keycloak 설정 백업 함수
backup_keycloak_config() {
    local backup_path=$1
    
    log_info "Backing up Keycloak configuration..."
    
    if ! docker ps --format "{{.Names}}" | grep -q "keycloak"; then
        log_warning "Keycloak container not running, skipping configuration backup"
        return
    fi
    
    local keycloak_backup_dir="$backup_path/keycloak"
    mkdir -p "$keycloak_backup_dir"
    
    # Keycloak Realm 백업 (REST API 사용)
    local admin_token
    admin_token=$(curl -s -d "client_id=admin-cli" \
        -d "username=admin" \
        -d "password=admin123" \
        -d "grant_type=password" \
        "http://localhost:10900/auth/realms/master/protocol/openid-connect/token" \
        | jq -r '.access_token' 2>/dev/null || echo "")
    
    if [ ! -z "$admin_token" ] && [ "$admin_token" != "null" ]; then
        # Realm 설정 백업
        curl -s -H "Authorization: Bearer $admin_token" \
            "http://localhost:10900/auth/admin/realms/development" \
            > "$keycloak_backup_dir/development-realm.json" 2>/dev/null
        
        # 클라이언트 설정 백업
        curl -s -H "Authorization: Bearer $admin_token" \
            "http://localhost:10900/auth/admin/realms/development/clients" \
            > "$keycloak_backup_dir/clients.json" 2>/dev/null
        
        # 사용자 설정 백업
        curl -s -H "Authorization: Bearer $admin_token" \
            "http://localhost:10900/auth/admin/realms/development/users" \
            > "$keycloak_backup_dir/users.json" 2>/dev/null
        
        log_success "Keycloak configuration backed up"
    else
        log_warning "Failed to obtain Keycloak admin token, skipping configuration backup"
    fi
}

# 백업 압축 함수
compress_backup() {
    local backup_path=$1
    
    if [ "$COMPRESS" = true ]; then
        log_info "Compressing backup..."
        
        local compressed_file="${backup_path}.tar.gz"
        
        if tar -czf "$compressed_file" -C "$(dirname $backup_path)" "$(basename $backup_path)"; then
            log_success "Backup compressed to $compressed_file"
            
            # 원본 디렉토리 삭제
            rm -rf "$backup_path"
            
            echo "$compressed_file"
        else
            log_error "Failed to compress backup"
            echo "$backup_path"
        fi
    else
        echo "$backup_path"
    fi
}

# 백업 정보 파일 생성
create_backup_info() {
    local backup_path=$1
    
    local info_file="$backup_path/backup_info.txt"
    
    cat > "$info_file" << EOF
Infrastructure Backup Information
==================================

Backup Date: $(date)
Backup Directory: $backup_path
Compressed: $COMPRESS
Exclude Logs: $EXCLUDE_LOGS
Created By: $(whoami)
Hostname: $(hostname)

Services Status at Backup Time:
EOF
    
    # 실행 중인 컨테이너 목록 추가
    echo "" >> "$info_file"
    echo "Running Containers:" >> "$info_file"
    docker ps --format "{{.Names}}\t{{.Status}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|coredns|kafka|elasticsearch|kibana|jaeger|harbor)" >> "$info_file" 2>/dev/null || echo "No infrastructure containers running" >> "$info_file"
    
    echo "" >> "$info_file"
    echo "Docker System Info:" >> "$info_file"
    docker system df >> "$info_file" 2>/dev/null
    
    log_success "Backup information saved to $info_file"
}

# 백업 검증 함수
verify_backup() {
    local backup_path=$1
    
    log_info "Verifying backup integrity..."
    
    local errors=0
    
    # 필수 디렉토리 확인
    local required_dirs=("configs" "volumes")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$backup_path/$dir" ]; then
            log_error "Missing directory: $dir"
            ((errors++))
        fi
    done
    
    # 백업 정보 파일 확인
    if [ ! -f "$backup_path/backup_info.txt" ]; then
        log_error "Missing backup_info.txt"
        ((errors++))
    fi
    
    # 파일 크기 확인 (너무 작으면 문제가 있을 수 있음)
    local total_size=$(du -sh "$backup_path" | cut -f1)
    log_info "Total backup size: $total_size"
    
    if [ $errors -eq 0 ]; then
        log_success "Backup verification completed successfully"
    else
        log_error "Backup verification failed with $errors errors"
    fi
    
    return $errors
}

# 정리 함수 (오래된 백업 삭제)
cleanup_old_backups() {
    local backup_dir=$1
    local keep_days=${2:-7}  # 기본 7일
    
    log_info "Cleaning up backups older than $keep_days days..."
    
    if [ -d "$backup_dir" ]; then
        find "$backup_dir" -name "infra-backup-*" -type d -mtime +$keep_days -exec rm -rf {} \; 2>/dev/null || true
        find "$backup_dir" -name "infra-backup-*.tar.gz" -type f -mtime +$keep_days -delete 2>/dev/null || true
        
        log_success "Old backups cleaned up"
    fi
}

# 메인 백업 함수
main() {
    log_info "🗄️ Infrastructure Backup Starting..."
    log_info "📁 Working directory: $(pwd)"
    log_info "🕐 Timestamp: $TIMESTAMP"
    echo ""
    
    # 현재 디렉토리가 infra-app인지 확인
    if [[ ! "$(basename $(pwd))" == "infra-app" ]]; then
        log_error "Please run this script from the infra-app directory"
        exit 1
    fi
    
    # 시작 시간 기록
    start_time=$(date +%s)
    
    # 백업 디렉토리 생성
    local backup_path
    backup_path=$(create_backup_dir)
    
    log_info "🚀 Starting backup process..."
    echo ""
    
    # 1. 설정 파일 백업
    backup_configs "$backup_path"
    
    # 2. 데이터베이스 백업
    backup_database "Keycloak" "keycloak-db" "keycloak" "keycloak" "$backup_path"
    backup_database "Kong" "kong-db" "kong" "kong" "$backup_path"
    backup_database "Harbor" "harbor-db" "registry" "postgres" "$backup_path"
    
    # 3. 볼륨 백업
    backup_volume "Security" "security" "$backup_path"
    backup_volume "Monitoring" "monitoring" "$backup_path"
    backup_volume "Logging" "logging" "$backup_path"
    backup_volume "Cache" "cache" "$backup_path"
    backup_volume "Messaging" "messaging" "$backup_path"
    backup_volume "Registry" "registry" "$backup_path"
    backup_volume "Tracing" "tracing" "$backup_path"
    
    # 4. Vault 시크릿 백업
    backup_vault_secrets "$backup_path"
    
    # 5. Keycloak 설정 백업
    backup_keycloak_config "$backup_path"
    
    # 6. 백업 정보 파일 생성
    create_backup_info "$backup_path"
    
    # 7. 백업 검증
    verify_backup "$backup_path"
    
    # 8. 압축 (옵션)
    local final_backup_path
    final_backup_path=$(compress_backup "$backup_path")
    
    # 9. 오래된 백업 정리
    cleanup_old_backups "$BACKUP_DIR" 7
    
    # 완료 시간 계산
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    minutes=$((duration / 60))
    seconds=$((duration % 60))
    
    echo ""
    log_success "🎉 Backup completed successfully!"
    log_info "📦 Backup location: $final_backup_path"
    log_info "⏱️  Total backup time: ${minutes}m ${seconds}s"
    
    # 백업 크기 정보
    if [ -f "$final_backup_path.tar.gz" ]; then
        local size=$(du -sh "$final_backup_path.tar.gz" | cut -f1)
        log_info "📊 Backup size: $size"
    elif [ -d "$final_backup_path" ]; then
        local size=$(du -sh "$final_backup_path" | cut -f1)
        log_info "📊 Backup size: $size"
    fi
    
    echo ""
    log_info "💡 Restore instructions:"
    echo "  1. Stop all services: ./scripts/stop-all.sh --force"
    echo "  2. Extract backup: tar -xzf backup-file.tar.gz"
    echo "  3. Restore volumes: docker run --rm -v volume:/data -v backup:/backup alpine cp -r /backup/* /data/"
    echo "  4. Start services: ./scripts/start-all.sh"
    echo ""
}

# 인터럽트 시그널 처리
trap 'log_error "Backup interrupted by user"; exit 1' INT

# 메인 함수 실행
main "$@"
