# ---------- Stage 1 Build ----------
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /build

COPY . .

RUN mvn clean package -DskipTests


# ---------- Stage 2 Runtime ----------
FROM eclipse-temurin:17-jdk-alpine

ENV APP_HOME=/usr/src/app

WORKDIR $APP_HOME

COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8080

CMD ["java","-jar","app.jar"]
