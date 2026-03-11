FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /build

# 1. Dependency Layering (Optimization)
# Copy only the pom.xml first and download dependencies.
# This layer is cached unless you change your pom.xml.
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 2. Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests


# ---------- Stage 2: Runtime ----------
# Use JRE (Java Runtime) instead of JDK for a smaller, more secure footprint
FROM eclipse-temurin:17-jre-alpine

# Security: Create a non-root user to run the app
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

WORKDIR /app

# Copy the built jar from the builder stage
COPY --from=builder /build/target/*.jar app.jar

# Standard practice: Use ENTRYPOINT for the executable and CMD for arguments
ENTRYPOINT ["java", "-jar", "app.jar"]
