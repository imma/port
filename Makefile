SHELL := bash

SSH_HOST := $(shell docker inspect $(shell uname -n) 2>/dev/null | jq -er '.[0].NetworkSettings.Networks | to_entries[0].value.Gateway' 2>/dev/null || echo 127.0.0.1)

restart:
	$(MAKE) ssh-config
	ps -o pgid "$(shell echo $$PPID)" | tail -1  | awk '{print $1}' > .pgroup
	$(MAKE) up

screen:
	screen -X -S imma quit || true
	if [[ -f .pgroup ]]; then sudo pkill -g "$(shell cat .pgroup)" || true; sleep 5; sudo pkill -9 -g "$(shell cat .pgroup)" || true; fi
	rm -f .pgroup
	screen -S imma -m $(MAKE) restart

up:
	$(MAKE) ssh-config
	docker-compose up -d --build
	while ! docker run --volumes-from openvpn_data alpine ls /etc/openvpn/docker.ovpn 2>/dev/null; do sleep 1; done

connect:
	mkdir -p config
	docker run --volumes-from openvpn_data alpine cat /etc/openvpn/docker.ovpn > config/docker.ovpn
	block openvpn script/server default --script-security 2 --config "$(shell pwd)/config/docker.ovpn"

ssh_host := $(shell docker inspect port_latest_1 2>/dev/null | jq -r '.[0].NetworkSettings.Networks.bridge.IPAddress')

ssh:
	$(MAKE) ssh-config
	ssh-keyscan $(ssh_host) > latest/.ssh/known_hosts
	ssh -A -l ubuntu -o StrictHostKeyChecking=yes -o UserKnownHostsFile=latest/.ssh/known_hosts $(ssh_host) $(opt)

init:
	while ! $(MAKE) ssh opt="-o ConnectTimeout=1 true"; do sleep 1; done
	tx init $(ssh_host) -o StrictHostKeyChecking=yes -o UserKnownHostsFile=latest/.ssh/known_hosts $(opt)
	@echo '======================================================='
	@echo '=============== one-time init finished   =============='
	@echo '======================================================='

attach:
	$(MAKE) ssh opt=true
	tx $(ssh_host) -o StrictHostKeyChecking=yes -o UserKnownHostsFile=latest/.ssh/known_hosts $(opt)

ssh-config:
	mkdir -p latest/.ssh
	mkdir -p .ssh
	rsync -ia ~/.ssh/authorized_keys latest/.ssh/
	rsync -ia ~/.ssh/authorized_keys .ssh/

push pull prune prep:
	cd ki && env SSH_HOST=$(SSH_HOST) $(MAKE) $@

rebase:
	$(MAKE) prune
	cd ki && env SSH_HOST=$(SSH_HOST) $(MAKE) update

base:
	cd ki && env SSH_HOST=$(SSH_HOST) $(MAKE)

seed:
	docker volume create data
	docker volume create openvpn_data

data-upload:
	docker build -t imma/rsync rsync
	docker run -v data:/data -v $(DATA):/data2 -ti imma/rsync rsync -ia /data2/. /data/. --delete
	docker run -v data:/data -v $(DATA):/data2 -ti imma/rsync chown -R 1000:1000 /data

data-download:
	docker build -t imma/rsync rsync
	docker run -v data:/data -v $(DATA):/data2 -ti imma/rsync rsync -ia /data/. /data2/.

logs:
	docker-compose logs -f

sync:
	git pull
	cd && block sync fast

install:
	sudo apt-get -y install make jq docker-compose
