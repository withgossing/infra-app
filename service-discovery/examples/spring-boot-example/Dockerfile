# 멀티 스테이지 빌드로 최적화된 Spring Boot 이미지

# 빌드 스테이지
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# 의존성 캐시 최적화를 위해 pom.xml 먼저 복사
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 소스 코드 복사 및 빌드
COPY src ./src
RUN mvn clean package -DskipTests -B

# 런타임 스테이지
FROM eclipse-temurin:17-jre-alpine

# 보안을 위한 non-root 사용자 생성
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 필요한 패키지 설치
RUN apk add --no-cache curl tzdata

# 타임존 설정
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 애플리케이션 디렉토리 생성
WORKDIR /app

# 빌드된 JAR 파일 복사
COPY --from=builder /app/target/*.jar app.jar

# 파일 소유권 변경
RUN chown -R appuser:appgroup /app

# non-root 사용자로 전환
USER appuser

# JVM 옵션 설정
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:+UseContainerSupport"

# 포트 노출
EXPOSE 8080

# 헬스체크 설정
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# 애플리케이션 실행
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
