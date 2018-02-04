SHELL := bash

SSH_HOST := $(shell docker inspect $(shell uname -n) 2>/dev/null | jq -er '.[0].NetworkSettings.Networks | to_entries[0].value.Gateway' || echo 127.0.0.1)

restart:
	ps -o pgid "$(shell echo $$PPID)" | tail -1  | awk '{print $1}' > .pgroup
	$(MAKE) up
	$(MAKE) connect

screen:
	screen -X -S imma quit || true
	if [[ -f .pgroup ]]; then sudo pkill -g "$(shell cat .pgroup)" || true; sleep 5; sudo pkill -9 -g "$(shell cat .pgroup)" || true; fi
	rm -f .pgroup
	screen -S imma -m $(MAKE) restart

up:
	$(MAKE) ssh-config
	docker-compose build
	docker-compose up -d --force-recreate
	while ! docker run --volumes-from openvpn_data alpine ls /etc/openvpn/docker.ovpn 2>/dev/null; do sleep 1; done

connect:
	mkdir -p config
	docker run --volumes-from openvpn_data alpine cat /etc/openvpn/docker.ovpn > config/docker.ovpn
	block openvpn script/server default --script-security 2 --config "$(shell pwd)/config/docker.ovpn"

ssh_host := $(shell docker inspect port_latest_1 2>/dev/null | jq -r '.[0].NetworkSettings.Networks.port_default.IPAddress')

ssh:
	$(MAKE) ssh-config
	ssh-keyscan $(ssh_host) > latest/.ssh/known_hosts
	ssh -A -o StrictHostKeyChecking=yes -o UserKnownHostsFile=latest/.ssh/known_hosts $(ssh_host) $(opt)

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
	rsync -ia ~/.ssh/authorized_keys latest/.ssh/

update push pull prune prep:
	cd ki && env SSH_HOST=$(SSH_HOST) $(MAKE) $@

seed:
	docker volume create data
	docker volume create openvpn_data

data-upload:
	docker run -v data:/data -v $(DATA):/data2 -ti ubuntu bash -c "apt-get update; apt-get install -y rsync; rsync -ia /data2/. /data/. --delete"

data-download:
	docker run -v data:/data  -v $(DATA):/data2 -ti ubuntu rsync -ia /data/. /data2/.

logs:
	docker-compose logs -f
