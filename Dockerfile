
# -------- Stage 1: Build jar bằng Maven --------
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# copy file cấu hình trước để cache dependency
COPY pom.xml . 
RUN mvn -B dependency:go-offline

# copy source code và build
COPY src ./src
RUN mvn -B -DskipTests package

# -------- Stage 2: Runtime image gọn nhẹ --------
FROM eclipse-temurin:17-jre

WORKDIR /app

# tên jar theo pom: Hello-0.0.1-SNAPSHOT.jar
COPY --from=build /app/target/Hello-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
