# Build stage
FROM maven:3.8.1-openjdk-8 AS builder

WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:8-jre-alpine

WORKDIR /app

# Copy the jar file from builder stage
COPY --from=builder /app/target/users-api-0.0.1-SNAPSHOT.jar app.jar

# Create non-root user for security
RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001

# Change ownership of the app directory
RUN chown -R spring:spring /app
USER spring

# Expose port
EXPOSE 8083

# Run the application with optimized memory settings
CMD ["java", "-Xmx200m", "-Xms100m", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=60.0", "-XX:+UseSerialGC", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"] 