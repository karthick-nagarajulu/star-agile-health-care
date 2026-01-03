FROM openjdk:21-jdk-slim
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
# Use this entrypoint to run the jar directly, avoiding the JarLauncher error
ENTRYPOINT ["java", "-jar", "/app.jar"]
