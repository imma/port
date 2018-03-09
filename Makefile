SHELL := bash
REPO ?= imma/ubuntu
TAG ?= latest

CONTAINER_HOST := $(shell docker-compose ps -q imma_start2 2>/dev/null).docker

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
	docker-compose up -d --build --force-recreate
	$(MAKE) finish_

finish_:
	while true; do if ssh -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa $(CONTAINER_HOST) true; then break; fi; sleep 1; done
	ssh -A -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa $(CONTAINER_HOST) /tmp/cache/libexec/bootstrap
	docker commit $(shell basename $(CONTAINER_HOST) .docker) $(REPO):latest
	docker-compose down

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
