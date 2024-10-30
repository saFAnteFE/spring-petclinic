### DOCKER SWARM
VM_IP?=192.168.1.80
DOCKER_HOST:="ssh://safantefe@${VM_IP}"

.PHONY: swarm-init
swarm-init:
	    DOCKER_HOST=${DOCKER_HOST} docker swarm init

.PHONY: swarm-deploy-stack
swarm-deploy-stack:
	    DOCKER_HOST=${DOCKER_HOST} docker stack deploy -c docker-swarm.yml petclinic-app

.PHONY: swarm-ls
swarm-ls:
	    DOCKER_HOST=${DOCKER_HOST} docker service ls

.PHONY: swarm-remove-stack
swarm-remove-stack:
	    DOCKER_HOST=${DOCKER_HOST} docker stack rm petclinic-app

.PHONY: create-secrets
create-secrets:
	    printf "petclinic" | DOCKER_HOST=${DOCKER_HOST} docker secret create postgres-passwd -
	    DOCKER_HOST=${DOCKER_HOST} docker secret create mysecrets ./secrets.yml

.PHONY: delete-secrets
delete-secrets:
	    DOCKER_HOST=${DOCKER_HOST} docker secret rm postgres-passwd mysecrets

.PHONY: list-secrets
list-secrets:
	    DOCKER_HOST=${DOCKER_HOST} docker secret ls

.PHONY: redeploy-all
redeploy-all:
	    -$(MAKE) swarm-remove-stack
	    -$(MAKE) delete-secrets
	    @sleep 3
	    -$(MAKE) create-secrets
	    -$(MAKE) swarm-deploy-stack
