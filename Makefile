SHELL := bash

SSH_HOST := $(shell docker inspect $(shell uname -n) 2>/dev/null | jq -er '.[0].NetworkSettings.Networks | to_entries[0].value.Gateway' 2>/dev/null || echo 127.0.0.1)

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
	docker-compose up -d --build --force-recreate
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

push pull prune prep:
	cd ki && env SSH_HOST=$(SSH_HOST) $(MAKE) $@

rebase:
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

shell:
	$(MAKE) shell-setup
	$(MAKE) shell-ssh

shell-setup:
	$(MAKE) prune
	docker rm -f port_shell 2>/dev/null || true
	docker run -d --name port_shell -p :22 --volumes-from data -v $(HOME)/.ssh/authorized_keys:/home/ubuntu/.ssh/authorized_keys -v /var/run/docker.sock:/var/run/docker.sock -ti imma/ubuntu /usr/sbin/sshd -D -o UseDNS=no -o UsePAM=yes -o PasswordAuthentication=no -o UsePrivilegeSeparation=sandbox
	$(MAKE) shell-inner

shell-inner:
	while true; do if ssh -l ubuntu -p "$(shell docker inspect port_shell | jq -r '.[0].NetworkSettings.Ports["22/tcp"][0].HostPort')" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(SSH_HOST) true; then break; fi; sleep 1; done
	ssh -A -l ubuntu -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$(shell docker inspect port_shell | jq -r '.[0].NetworkSettings.Ports["22/tcp"][0].HostPort')" $(SSH_HOST) block sync fast
	ssh -A -l ubuntu -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$(shell docker inspect port_shell | jq -r '.[0].NetworkSettings.Ports["22/tcp"][0].HostPort')" $(SSH_HOST) sudo chgrp docker /var/run/docker.sock

shell-ssh:
	ssh -A -l ubuntu -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$(shell docker inspect port_shell | jq -r '.[0].NetworkSettings.Ports["22/tcp"][0].HostPort')" $(SSH_HOST)

sync:
	cd && block sync fast

install:
	sudo apt-get -y install make jq docker-compose
