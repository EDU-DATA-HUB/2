# syntax=docker/dockerfile:1
# Expects fat JAR already built on the host: ./mvnw -DskipTests package
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY target/*-SNAPSHOT.jar /app/app.jar
EXPOSE 8761
ENTRYPOINT ["java","-jar","/app/app.jar","--spring.profiles.active=docker"]
