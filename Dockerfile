# 构建阶段：使用 Maven 3.8 + JDK 8 环境编译打包
FROM maven:3.8.6-jdk-8 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# 运行阶段：使用 JDK 8 精简环境启动应用
FROM openjdk:8-jre-slim
WORKDIR /app
COPY --from=build /app/target/psychology-1.0-SNAPSHOT.jar app.jar
# 监听 Render 分配的端口
ENTRYPOINT ["java", "-jar", "app.jar", "--server.port=${PORT}"]