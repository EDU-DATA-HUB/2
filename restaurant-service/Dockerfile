# syntax=docker/dockerfile:1
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN mkdir -p /app/uploads
COPY target/*-SNAPSHOT.jar /app/app.jar
EXPOSE 8082
ENTRYPOINT ["java","-jar","/app/app.jar","--spring.profiles.active=docker"]
