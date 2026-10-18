# syntax=docker/dockerfile:1
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY target/*-SNAPSHOT.jar /app/app.jar
EXPOSE 9000
ENTRYPOINT ["java","-jar","/app/app.jar","--spring.profiles.active=docker"]
