#!/bin/bash

# Docker Compose 파일들의 version 속성을 제거하는 스크립트

echo "🔧 Docker Compose 파일들의 version 속성을 제거합니다..."
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# infra-app 디렉토리로 이동
cd /Users/gossing/WorkPlace/infra-app

# 모든 docker-compose.yml 파일 찾기
files=$(find . -name "docker-compose.yml" -type f)

for file in $files; do
    echo -e "${YELLOW}처리 중:${NC} $file"
    
    # version 라인이 있는지 확인
    if grep -q "^version:" "$file"; then
        # version 라인 제거 (macOS에서 작동하도록 수정)
        sed -i '' '/^version:/d' "$file"
        echo -e "${GREEN}✓${NC} version 속성 제거됨"
    else
        echo "  - version 속성이 없습니다"
    fi
    
    echo ""
done

echo "✅ 모든 Docker Compose 파일 처리 완료!"
