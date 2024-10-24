FROM eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /build
COPY --chmod=0755 mvnw mvnw
COPY .mvn .mvn

RUN --mount=type=bind,source=pom.xml,target=pom.xml \
    --mount=type=cache,target=/root/.m2 ./mvnw dependency:go-offline -DskipTests

FROM builder AS package
WORKDIR /build
COPY ./src src/
RUN --mount=type=bind,source=pom.xml,target=pom.xml \
    --mount=type=cache,target=/root/.m2 \
    ./mvnw package -DskipTests && \
    mv target/$(./mvnw help:evaluate -Dexpression=project.artifactId -q -DforceStdout)-$(./mvnw help:evaluate -Dexpression=project.version -q -DforceStdout).jar target/petclinic.jar

FROM package AS extract
WORKDIR /build
RUN java -Djarmode=layertools -jar target/petclinic.jar extract --destination target/extracted

# FROM extract AS development
# WORKDIR /build
# RUN cp -r /build/target/extracted/dependencies/. ./
# RUN cp -r /build/target/extracted/spring-boot-loader/. ./
# RUN cp -r /build/target/extracted/snapshot-dependencies/. ./
# RUN cp -r /build/target/extracted/application/. ./
# ENV JAVA_TOOL_OPTIONS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000
# CMD [ "java", "-Dspring.profiles.active=postgres", "org.springframework.boot.loader.launch.JarLauncher" ]

FROM eclipse-temurin:17-jre-jammy AS final
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    java
USER java
COPY --from=extract build/target/extracted/dependencies/ ./
COPY --from=extract build/target/extracted/spring-boot-loader/ ./
COPY --from=extract build/target/extracted/snapshot-dependencies/ ./
COPY --from=extract build/target/extracted/application/ ./
EXPOSE 8080
ENTRYPOINT [ "java", "org.springframework.boot.loader.launch.JarLauncher" ]
