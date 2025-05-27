#!/bin/bash

# Keycloak 초기 설정 스크립트
set -e

echo "=== Keycloak 초기 설정 시작 ==="

# Keycloak CLI 도구 준비
KEYCLOAK_URL="http://keycloak:8080"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin123"

# Keycloak가 준비될 때까지 대기
echo "Keycloak 서버 준비 대기 중..."
until curl -f ${KEYCLOAK_URL}/auth/realms/master > /dev/null 2>&1; do
    echo "Keycloak 서버 대기 중..."
    sleep 5
done

echo "Keycloak 서버 준비 완료!"

# 관리자 토큰 획득
echo "관리자 토큰 획득 중..."
ADMIN_TOKEN=$(curl -s \
    -d "client_id=admin-cli" \
    -d "username=${ADMIN_USERNAME}" \
    -d "password=${ADMIN_PASSWORD}" \
    -d "grant_type=password" \
    "${KEYCLOAK_URL}/auth/realms/master/protocol/openid-connect/token" \
    | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ 관리자 토큰 획득 실패"
    exit 1
fi

echo "✅ 관리자 토큰 획득 성공"

# 개발용 Realm 생성
echo "개발용 Realm 생성 중..."
REALM_CONFIG='{
    "realm": "development",
    "enabled": true,
    "displayName": "Development Environment",
    "displayNameHtml": "<strong>Development</strong> Environment",
    "loginTheme": "keycloak",
    "adminTheme": "keycloak",
    "accountTheme": "keycloak",
    "emailTheme": "keycloak",
    "sslRequired": "none",
    "registrationAllowed": true,
    "passwordPolicy": "length(8)",
    "duplicateEmailsAllowed": false,
    "rememberMe": true,
    "verifyEmail": false,
    "resetPasswordAllowed": true,
    "editUsernameAllowed": true,
    "internationalizationEnabled": true,
    "supportedLocales": ["ko", "en"],
    "defaultLocale": "ko"
}'

curl -s -X POST \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${REALM_CONFIG}" \
    "${KEYCLOAK_URL}/auth/admin/realms" > /dev/null

echo "✅ 개발용 Realm 생성 완료"

# 클라이언트 생성
echo "API 클라이언트 생성 중..."
CLIENT_CONFIG='{
    "clientId": "api-client",
    "name": "API Client",
    "description": "API 접근용 클라이언트",
    "enabled": true,
    "publicClient": false,
    "serviceAccountsEnabled": true,
    "authorizationServicesEnabled": true,
    "directAccessGrantsEnabled": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "clientAuthenticatorType": "client-secret",
    "secret": "api-client-secret",
    "redirectUris": ["http://localhost:*"],
    "webOrigins": ["http://localhost:*"],
    "protocol": "openid-connect",
    "attributes": {
        "access.token.lifespan": "1800",
        "client.session.idle.timeout": "1800",
        "client.session.max.lifespan": "86400"
    }
}'

curl -s -X POST \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${CLIENT_CONFIG}" \
    "${KEYCLOAK_URL}/auth/admin/realms/development/clients" > /dev/null

echo "✅ API 클라이언트 생성 완료"

# 웹 애플리케이션 클라이언트 생성
echo "웹 애플리케이션 클라이언트 생성 중..."
WEB_CLIENT_CONFIG='{
    "clientId": "web-app",
    "name": "Web Application",
    "description": "웹 애플리케이션용 클라이언트",
    "enabled": true,
    "publicClient": true,
    "directAccessGrantsEnabled": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "redirectUris": ["http://localhost:*"],
    "webOrigins": ["http://localhost:*"],
    "protocol": "openid-connect"
}'

curl -s -X POST \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${WEB_CLIENT_CONFIG}" \
    "${KEYCLOAK_URL}/auth/admin/realms/development/clients" > /dev/null

echo "✅ 웹 애플리케이션 클라이언트 생성 완료"

# 테스트 사용자 생성
echo "테스트 사용자 생성 중..."
USER_CONFIG='{
    "username": "testuser",
    "email": "test@example.com",
    "firstName": "테스트",
    "lastName": "사용자",
    "enabled": true,
    "emailVerified": true,
    "credentials": [
        {
            "type": "password",
            "value": "test123",
            "temporary": false
        }
    ]
}'

curl -s -X POST \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${USER_CONFIG}" \
    "${KEYCLOAK_URL}/auth/admin/realms/development/users" > /dev/null

echo "✅ 테스트 사용자 생성 완료"

echo "=== Keycloak 초기 설정 완료 ==="
echo ""
echo "📋 설정 정보:"
echo "  - Realm: development"
echo "  - API Client ID: api-client"
echo "  - API Client Secret: api-client-secret"
echo "  - Web Client ID: web-app"
echo "  - Test User: testuser / test123"
echo "  - Keycloak URL: http://localhost:10900"
echo ""
