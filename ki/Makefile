KI := conv
DATA ?= /data
SSH_HOST ?= 127.0.0.1
REPO ?= imma/ubuntu
TAG ?= latest
PREFIX := fehfeh$(shell hostname | perl -pe 's{[\.-]}{}g')

all:
	echo $(shell date +%s) >> .meh
	$(MAKE) base
	docker tag $(REPO):ubuntu $(REPO):start
	docker tag $(REPO):ubuntu $(REPO):start2
	env COMPOSE_PROJECT_NAME=$(PREFIX) docker-compose up -d --force-recreate
	while true; do if nc -z $(SSH_HOST) 2222; then break; fi; sleep 1; done
	while true; do if ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) true; then break; fi; sleep 1; done
	$(MAKE) continue
	$(MAKE) finish
	docker tag $(REPO):latest $(REPO):start

base: .kitchen/docker_id_rsa
	$(MAKE) prune || true
	mkdir -p .ssh
	rsync -ia ~/.ssh/authorized_keys .ssh/
	ln -nfs Dockerfile.base Dockerfile
	docker build -t $(REPO):ubuntu .

update:
	$(MAKE) prep
	$(MAKE) prune || true
	mkdir -p .ssh
	rsync -ia ~/.ssh/authorized_keys .ssh/
	ln -nfs Dockerfile.update Dockerfile
	echo $(shell date +%s) >> .meh
	docker build -t $(REPO):start2 .
	env COMPOSE_PROJECT_NAME=$(PREFIX) docker-compose up -d --force-recreate
	while true; do if nc -z $(SSH_HOST) 2222; then break; fi; sleep 1; done
	while true; do if ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) true; then break; fi; sleep 1; done
	$(MAKE) continue
	$(MAKE) finish

continue:
	ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) /tmp/cache/script/bootstrap
	echo FINISHED: ssh -A -p 2222 -o IdentityFile=$(shell pwd)/.kitchen/docker_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$(SSH_HOST) /tmp/cache/script/bootstrap

finish:
	docker commit $(PREFIX)_$(shell echo $(REPO) | cut -d/ -f1)_latest_1 $(REPO):latest
	env COMPOSE_PROJECT_NAME=$(PREFIX) docker-compose down || env COMPOSE_PROJECT_NAME=$(PREFIX) docker-compose down
	$(MAKE) prune || true

dind:
	$(MAKE) SSH_HOST=172.17.0.1

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
	docker system prune -f --volumes
	docker system df

prep: .kitchen/docker_id_rsa
	if ! docker inspect "$(REPO):start" > /dev/null; then docker tag $(REPO):latest $(REPO):start; fi
