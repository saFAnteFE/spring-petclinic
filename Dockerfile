FROM maven:3.8.5-openjdk-17 AS builder

WORKDIR /src/usr/app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY . .
RUN mvn clean install

FROM openjdk:17-ea-29-slim AS runner
RUN groupadd --gid 1000 java \
  && useradd --uid 1000 --gid java --shell /bin/bash --create-home java
USER java

WORKDIR /app
COPY --from=builder --chown=java:java /src/usr/app/target/spring-petclinic-3.3.0-SNAPSHOT.jar \
 /app/spring-petclinic-3.3.0-SNAPSHOT.jar

CMD ["java","-jar","spring-petclinic-3.3.0-SNAPSHOT.jar"]
