FROM maven:3.8.5-openjdk-17 AS builder

WORKDIR /src/usr/app

COPY . .
# using cache avoid redundant dependencies download without previous mvn dependency  
# processing
RUN --mount=type=cache,target=/root/.m2 mvn clean package

FROM openjdk:17-ea-29-slim AS runner
RUN groupadd --gid 1000 java \
  && useradd --uid 1000 --gid java --shell /bin/bash --create-home java
USER java

WORKDIR /app
COPY --from=builder --chown=java:java /src/usr/app/target/spring-petclinic-3.3.0-SNAPSHOT.jar \
 /app/spring-petclinic-3.3.0-SNAPSHOT.jar

EXPOSE 8080
 
ENTRYPOINT ["java","-jar","spring-petclinic-3.3.0-SNAPSHOT.jar"]
