artifact=spring-petclinic-3.3.0-SNAPSHOT.jar 
.PHONY: build
build:
	@echo ---------------------------
	@echo Starting postgres container
	@echo ---------------------------
	-DOCKER_BUILDKIT=1 docker build \
		-t petclinic:2.0 \
		.

.PHONY: petclinic
petclinic:
	@echo ----------------------------
	@echo Starting petclinic container
	@echo ----------------------------
	-docker run -itd \
        --name petclinic \
		-p 8080:8080 \
		petclinic:2.0

.PHONY: postgres
postgres:
	@echo ---------------------------
	@echo Starting postgres container
	@echo ---------------------------
	-docker container stop db
	-docker container rm db
	-docker run -itd \
		--name db \
		-e POSTGRES_USER=petclinic \
		-e POSTGRES_PASSWORD=petclinic \
		-e POSTGRES_DB=petclinic \
		-p 5432:5432 \
		--restart unless-stopped \
		postgres:17.0

.PHONY: mysql
mysql:
	@echo ------------------------
	@echo Starting mysql container
	@echo ------------------------
	-docker container stop db
	-docker container rm db
	-docker run -itd \
        --name db \
		-e MYSQL_ROOT_PASSWORD= \
		-e MYSQL_ALLOW_EMPTY_PASSWORD=true \
		-e MYSQL_USER=petclinic \
		-e MYSQL_PASSWORD=petclinic \
		-e MYSQL_DATABASE=petclinic \
		-v ./conf.d:/etc/mysql/conf.d:ro \
		-p 3306:3306 \
		mysql:9.0

.PHONY: net
net:
	@echo --------------
	@echo create network
	@echo --------------
	-docker network create netclinic

.PHONY: up
up:
	@echo ---------------------------
	@echo start petclinic application
	@echo ---------------------------

	$(MAKE) down

	$(MAKE) net

	@echo ---------
	@echo create db
	@echo ---------
	docker run -d \
		--name db \
	    --net netclinic \
	    -p 5432:5432 \
	    -v db-data:/var/lib/postgresql/data \
	    -e POSTGRES_PASSWORD=petclinic \
	    -e POSTGRES_USER=petclinic \
	    -e POSTGRES_DB=petclinic \
	    --health-cmd CMD,pg_isready,-U,petclinic \
	    --health-interval 10s \
	    --health-retries 5 \
	    --health-timeout 5s \
	    postgres:17.0

	@echo ----------------
	@echo create petclinic
	@echo ----------------
	docker run -d \
		--name petclinic \
	    --net netclinic \
	    --init \
	    -e POSTGRES_URL=jdbc:postgresql://db:5432/petclinic \
	    -e JAVA_TOOL_OPTIONS=-Dspring.profiles.active=postgres \
	    -p 8080:8080 \
	    petclinic:2.0
        
.PHONY: docker-stop
docker-stop:
	@echo -----------------------------
	@echo Stop all petclinic containers
	@echo -----------------------------
	-docker stop db 
	-docker stop petclinic

.PHONY: docker-rm
docker-rm:
	@echo -------------------------------
	@echo Remove all petclinic containers
	@echo -------------------------------
	-docker container rm --force db
	-docker container rm --force petclinic
	-docker network rm --force netclinic

.PHONY: down
down:
	$(MAKE) docker-stop
	$(MAKE) docker-rm

