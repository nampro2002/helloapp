# 🏗 STAGE 1: Build ứng dụng
FROM maven:3.8.6-eclipse-temurin-17 AS builder
WORKDIR /app

COPY pom.xml .
COPY src ./src

# Cài đặt dependencies và build ứng dụng
RUN mvn clean package -DskipTests

# 🏗 STAGE 2: Chạy ứng dụng
FROM eclipse-temurin:17-jdk
WORKDIR /app

# Copy JAR từ STAGE 1
COPY --from=builder /app/target/*.jar app.jar

# Expose cổng mới (8081)
EXPOSE 8081

# 🔹 HEALTHCHECK cập nhật với cổng mới
HEALTHCHECK --interval=3s --timeout=2s --start-period=5s --retries=1 CMD curl -f http://localhost:8081/health || exit 1

# Chạy ứng dụng trên cổng 8081
ENTRYPOINT ["java", "-jar", "app.jar", "--server.port=8081"]
