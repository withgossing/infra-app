#!/bin/bash

# Vault 초기 설정 스크립트
set -e

echo "=== Vault 초기 설정 시작 ==="

# Vault 설정
VAULT_ADDR="http://vault:8200"
VAULT_TOKEN="vault-root-token"

# Vault가 준비될 때까지 대기
echo "Vault 서버 준비 대기 중..."
until vault status > /dev/null 2>&1; do
    echo "Vault 서버 대기 중..."
    sleep 5
done

echo "Vault 서버 준비 완료!"

# Vault 로그인
echo "Vault 로그인 중..."
vault auth -method=token token=${VAULT_TOKEN} > /dev/null

echo "✅ Vault 로그인 성공"

# Key-Value 시크릿 엔진 활성화
echo "KV 시크릿 엔진 활성화 중..."
vault secrets enable -version=2 -path=secret kv > /dev/null || echo "KV 엔진이 이미 활성화되어 있습니다."

echo "✅ KV 시크릿 엔진 활성화 완료"

# 데이터베이스 시크릿 엔진 활성화
echo "데이터베이스 시크릿 엔진 활성화 중..."
vault secrets enable -path=database database > /dev/null || echo "데이터베이스 엔진이 이미 활성화되어 있습니다."

echo "✅ 데이터베이스 시크릿 엔진 활성화 완료"

# PKI 시크릿 엔진 활성화
echo "PKI 시크릿 엔진 활성화 중..."
vault secrets enable -path=pki pki > /dev/null || echo "PKI 엔진이 이미 활성화되어 있습니다."

# PKI 최대 TTL 설정
vault secrets tune -max-lease-ttl=8760h pki > /dev/null

echo "✅ PKI 시크릿 엔진 활성화 완료"

# 루트 CA 인증서 생성
echo "루트 CA 인증서 생성 중..."
vault write -field=certificate pki/root/generate/internal \
    common_name="Development Root CA" \
    ttl=8760h > /tmp/root_ca.crt || echo "루트 CA가 이미 존재합니다."

echo "✅ 루트 CA 인증서 생성 완료"

# 애플리케이션별 시크릿 저장
echo "애플리케이션 시크릿 저장 중..."

# Bank App 시크릿
vault kv put secret/bank-app \
    db_password="bank_db_password_123" \
    api_key="bank_api_key_456" \
    jwt_secret="bank_jwt_secret_789" \
    encryption_key="bank_encryption_key_abc" > /dev/null

# Security App 시크릿
vault kv put secret/sec-app \
    db_password="sec_db_password_123" \
    api_key="sec_api_key_456" \
    audit_key="sec_audit_key_789" \
    signing_key="sec_signing_key_abc" > /dev/null

# 공통 인프라 시크릿
vault kv put secret/infra \
    redis_password="redis_password_123" \
    postgres_password="postgres_password_456" \
    kafka_password="kafka_password_789" \
    monitoring_token="monitoring_token_abc" > /dev/null

echo "✅ 애플리케이션 시크릿 저장 완료"

# 정책 생성
echo "Vault 정책 생성 중..."

# Bank App 정책
vault policy write bank-app-policy - <<EOF
# Bank App 전용 시크릿 접근
path "secret/data/bank-app/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/bank-app/*" {
  capabilities = ["list"]
}

# 공통 인프라 시크릿 읽기 전용
path "secret/data/infra" {
  capabilities = ["read"]
}

# PKI 인증서 발급
path "pki/issue/bank-app" {
  capabilities = ["create", "update"]
}
EOF

# Security App 정책
vault policy write sec-app-policy - <<EOF
# Security App 전용 시크릿 접근
path "secret/data/sec-app/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/sec-app/*" {
  capabilities = ["list"]
}

# 공통 인프라 시크릿 읽기 전용
path "secret/data/infra" {
  capabilities = ["read"]
}

# PKI 인증서 발급
path "pki/issue/sec-app" {
  capabilities = ["create", "update"]
}
EOF

# 개발자 정책
vault policy write developer-policy - <<EOF
# 모든 애플리케이션 시크릿 읽기
path "secret/data/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/*" {
  capabilities = ["list"]
}

# PKI 인증서 발급
path "pki/issue/*" {
  capabilities = ["create", "update"]
}
EOF

echo "✅ Vault 정책 생성 완료"

# 토큰 생성
echo "애플리케이션별 토큰 생성 중..."

# Bank App 토큰
BANK_TOKEN=$(vault token create \
    -policy=bank-app-policy \
    -display-name="bank-app-token" \
    -ttl=8760h \
    -renewable=true \
    -field=token)

# Security App 토큰
SEC_TOKEN=$(vault token create \
    -policy=sec-app-policy \
    -display-name="sec-app-token" \
    -ttl=8760h \
    -renewable=true \
    -field=token)

# 개발자 토큰
DEV_TOKEN=$(vault token create \
    -policy=developer-policy \
    -display-name="developer-token" \
    -ttl=24h \
    -renewable=true \
    -field=token)

echo "✅ 애플리케이션별 토큰 생성 완료"

# 감사 로그 활성화
echo "감사 로그 활성화 중..."
vault audit enable file file_path=/vault/logs/audit.log > /dev/null || echo "감사 로그가 이미 활성화되어 있습니다."

echo "✅ 감사 로그 활성화 완료"

echo "=== Vault 초기 설정 완료 ==="
echo ""
echo "📋 설정 정보:"
echo "  - Root Token: ${VAULT_TOKEN}"
echo "  - Bank App Token: ${BANK_TOKEN}"
echo "  - Security App Token: ${SEC_TOKEN}"
echo "  - Developer Token: ${DEV_TOKEN}"
echo "  - Vault URL: http://localhost:10902"
echo ""
echo "🔍 시크릿 조회 예제:"
echo "  vault kv get secret/bank-app"
echo "  vault kv get secret/sec-app"
echo "  vault kv get secret/infra"
echo ""
