# =========================================================================
# FASHIONSHOP DOCKERFILE - MULTI-STAGE BUILD (JAVA 21)
# Hỗ trợ deploy độc lập lên Railway, Render, Fly.io hoặc Docker VPS
# =========================================================================

# Stage 1: Build file JAR bằng Gradle Wrapper
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# Copy gradle wrapper và cache dependencies trước
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# Copy toàn bộ mã nguồn
COPY src src

# Build Spring Boot executable JAR (bỏ qua chạy unit test khi đóng gói image)
RUN ./gradlew bootJar --no-daemon -x test && \
    cp $(ls build/libs/*.jar | grep -v 'plain' | head -n 1) app.jar

# Stage 2: Runtime image siêu nhẹ tối ưu bảo mật
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Tạo non-root user để chạy ứng dụng an toàn
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy file jar đã build
COPY --from=builder --chown=spring:spring /app/app.jar app.jar

# Biến môi trường mặc định (Render sử dụng port 10000 mặc định)
ENV PORT=10000
EXPOSE 10000

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
