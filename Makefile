SHELL := bash
SSH_HOST := $(shell docker inspect $(shell uname -n) 2>/dev/null | jq -er '.[0].NetworkSettings.Networks | to_entries[0].value.Gateway' 2>/dev/null || echo 127.0.0.1)
REPO ?= imma/ubuntu
TAG ?= latest
DOCKER_COMPOSE := env COMPOSE_PROJECT_NAME=build docker-compose

.PHONY: base

base:
	$(MAKE) prep
	ln -nfs Dockerfile.base Dockerfile
	docker build -t $(REPO):ubuntu .
	docker tag $(REPO):ubuntu $(REPO):start
	docker tag $(REPO):ubuntu $(REPO):start2
	$(MAKE) finish
	docker tag $(REPO):latest $(REPO):start

rebase:
	$(MAKE) prep
	ln -nfs Dockerfile.update Dockerfile
	docker build -t $(REPO):start2 .
	$(MAKE) finish

finish:
	$(DOCKER_COMPOSE) up -d --build --force-recreate
	while true; do if nc -z $(SSH_HOST) 2222; then break; fi; sleep 1; done
	while true; do if ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) true; then break; fi; sleep 1; done
	ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) /tmp/cache/libexec/bootstrap
	docker commit $(shell $(DOCKER_COMPOSE) ps -q shell) $(REPO):latest
	$(DOCKER_COMPOSE) down

prep: .kitchen/docker_id_rsa
	echo $(shell date +%s) >> .meh
	mkdir -p .ssh
	rsync -ia ~/.ssh/authorized_keys .ssh/
	docker create --name data -v data:/data alpine true 2>/dev/null || true
	docker run -v data:/data alpine chown 1000:1000 /data

.kitchen/docker_id_rsa:
	mkdir -p .kitchen
	ssh-keygen -f .kitchen/docker_id_rsa -P ''

push:
	ecs push "$(REPO):$(TAG)"

pull:
	ecs pull "$(REPO):$(TAG)"
	docker tag "$(shell aws ecr describe-repositories --repository-name $(REPO) | jq -r '.repositories[].repositoryUri'):$(TAG)" "$(REPO):$(TAG)"
