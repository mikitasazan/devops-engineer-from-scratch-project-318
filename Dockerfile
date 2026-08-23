FROM node:20-alpine AS frontend-build

WORKDIR /workspace/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM gradle:9.2.1-jdk21 AS backend-build

WORKDIR /workspace
COPY . .
COPY --from=frontend-build /workspace/frontend/dist ./src/main/resources/static
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:21-jre

WORKDIR /app
COPY --from=backend-build /workspace/build/libs/*.jar /app/app.jar

EXPOSE 8080 9090
ENV JAVA_OPTS=""
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
