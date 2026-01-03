# Stage 1: Extraction stage (using full JDK)
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

# Extract layers using Spring Boot's built-in layertools
# This separates dependencies, loader, and your application code
RUN java -Djarmode=layertools -jar app.jar extract

# Stage 2: Runtime stage (using slim JRE)
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Security: Run as a non-root user
RUN addgroup -S medicure && adduser -S medicure -G medicure
USER medicure

# Copy extracted layers from the builder stage
# We copy them in order of least-frequent to most-frequent changes
COPY --from=builder /app/dependencies/ ./
COPY --from=builder /app/spring-boot-loader/ ./
COPY --from=builder /app/snapshot-dependencies/ ./
COPY --from=builder /app/application/ ./

# Expose the specific Spring Boot port
EXPOSE 8080

# Use optimized JVM flags for container environments
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
