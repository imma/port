SHELL := bash
SSH_HOST := $(shell docker inspect $(shell uname -n) 2>/dev/null | jq -er '.[0].NetworkSettings.Networks | to_entries[0].value.Gateway' 2>/dev/null || echo 127.0.0.1)
KI := conv
DATA ?= /data
REPO ?= imma/ubuntu
TAG ?= latest
DOCKER_COMPOSE := env COMPOSE_PROJECT_NAME=build docker-compose

rebase:
	$(MAKE) prune
	$(MAKE) update

base:
	echo $(shell date +%s) >> .meh
	$(MAKE) ubuntu_base
	docker tag $(REPO):ubuntu $(REPO):start
	docker tag $(REPO):ubuntu $(REPO):start2
	$(DOCKER_COMPOSE) up -d --build --force-recreate
	while true; do if nc -z $(SSH_HOST) 2222; then break; fi; sleep 1; done
	while true; do if ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) true; then break; fi; sleep 1; done
	$(MAKE) continue
	$(MAKE) finish
	docker tag $(REPO):latest $(REPO):start

ubuntu_base: .kitchen/docker_id_rsa
	mkdir -p .ssh
	rsync -ia ~/.ssh/authorized_keys .ssh/
	ln -nfs Dockerfile.base Dockerfile
	docker build -t $(REPO):ubuntu .

update:
	$(MAKE) prep
	mkdir -p .ssh
	rsync -ia ~/.ssh/authorized_keys .ssh/
	ln -nfs Dockerfile.update Dockerfile
	echo $(shell date +%s) >> .meh
	docker build -t $(REPO):start2 .
	$(DOCKER_COMPOSE) up -d --build --force-recreate
	while true; do if nc -z $(SSH_HOST) 2222; then break; fi; sleep 1; done
	while true; do if ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) true; then break; fi; sleep 1; done
	$(MAKE) continue
	$(MAKE) finish

continue:
	ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) /tmp/cache/script/bootstrap
	echo FINISHED: ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) /tmp/cache/script/bootstrap

finish:
	$(DOCKER_COMPOSE) ps -q
	docker commit $(shell $(DOCKER_COMPOSE) ps -q | head -1) $(REPO):latest
	$(DOCKER_COMPOSE) down || $(DOCKER_COMPOSE) down

dind:
	$(MAKE) SSH_HOST=$(shell echo "$(shell docker network inspect bridge | jq -r '.[0].IPAM.Config[0].Subnet' | cut -d. -f1-3).1")

.kitchen/docker_id_rsa:
	mkdir -p .kitchen
	ssh-keygen -f .kitchen/docker_id_rsa -P ''

docker-listen:
	docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 2375:2375 bobrik/socat TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock

push:
	ecs push "$(REPO):$(TAG)"

pull:
	ecs pull "$(REPO):$(TAG)"
	docker tag "$(shell aws ecr describe-repositories --repository-name $(REPO) | jq -r '.repositories[].repositoryUri'):$(TAG)" "$(REPO):$(TAG)"

docker:
	ki $(KI) docker-ubuntu

virtualbox:
	ki $(KI) virtualbox-ubuntu

virtualbox-docker:
	ki exec virtualbox-ubuntu -c 'ssh -A -o StrictHostKeyChecking=no ubuntu@localhost ki $(KI) docker-ubuntu'

prune:
	docker system prune -f
	docker system df
	docker create --name data -v data:/data alpine true

prep: .kitchen/docker_id_rsa
	if ! docker inspect "$(REPO):start" > /dev/null; then docker tag $(REPO):latest $(REPO):start; fi

ps:
	$(DOCKER_COMPOSE) ps
