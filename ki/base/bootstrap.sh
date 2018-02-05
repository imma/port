#!/usr/bin/env bash

set -exfu
umask 0022

function main {
  local nm_branch="master"
  local nm_remote="origin"
  local url_remote="https://github.com/imma/ubuntu"

  if [[ "$(id -u ubuntu 2>/dev/null || true)" != 1000 ]]; then
    exec sudo env "PATH=/usr/sbin:$PATH" SSH_AUTH_SOCK="$SSH_AUTH_SOCK" bash -c 'set -x; userdel ubuntu; mv /home/ubuntu /home/ubuntu.old; groupadd -g 1000 ubuntu; useradd -u 1000 -g ubuntu -d /home/ubuntu -m -s /bin/bash -p "*" ubuntu; cp -r /home/ubuntu.old/. /home/ubuntu/.; chown -R ubuntu:ubuntu /home/ubuntu /tmp/kitchen; id -a ubuntu; sudo -u ubuntu env SSH_AUTH_SOCK="$SSH_AUTH_SOCK" "$0" "$@"' "$0" "$@"
    return 1
  fi

  export BOARD_PATH="$HOME"

  : ${DISTRIB_ID:=}

  if [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
  fi

  if [[ -z "${DISTRIB_ID}" ]]; then
    DISTRIB_ID="$(awk '{print $1}' /etc/system-release 2>/dev/null || true)"
  fi

  if [[ -z "${DISTRIB_ID}" ]]; then
    DISTRIB_ID="$(awk '{print $1}' /etc/redhat-release 2>/dev/null || true)"
  fi

  if [[ -z "$DISTRIB_ID" ]]; then
    DISTRIB_ID="$(uname -s)"
  fi

  export DISTRIB_ID

  case "$DISTRIB_ID" in
    Ubuntu)
      local loader='sudo env DEBIAN_FRONTEND=noninteractive'
      ;;
    *)
      local loader='sudo env'
      ;;
  esac

  export LANG=en_US.UTF-8

  if [[ ! -d .git ]]; then
    touch .bootstrapping
  fi
  
  if [[ -f .bootstrapping ]]; then
    touch .bootstrapping

    case "$DISTRIB_ID" in
      Ubuntu)
        tail -f /var/log/cloud-init-output.log || true &

        set +x
        while true; do
          case "$(systemctl is-active cloud-final.service)" in
            inactive|active|failed)
                pkill tail || true
                wait
                break
              ;;
            "")
              break
              ;;
          esac
          sleep 1
        done
        ;;
    esac

		ssh -o StrictHostKeyChecking=no github.com true 2>/dev/null || true

		git clone git@github.com:imma/ubuntu
		mv ubuntu/.git .

		rm -f .bootstrapping
  fi

  git fetch
	git reset --hard
  git pull

	script/setup
	script/bootstrap

	for a in {1..5}; do git clean -ffd || true; done
  sudo rm -f ~root/.ssh/authorized_keys
  (set +f; rm -f .ssh/authorized_keys .ssh/*id_rsa*)
  apt-get clean
  rm -rf "$WRKOBJDIR"
  rm -rf "$PKGSRCDIR"
}

case "$(id -u -n)" in
  root)
    umask 022

    cat > /etc/sudoers.d/90-cloud-init-users <<____EOF
    # Created by cloud-init v. 0.7.9 on Fri, 21 Jul 2017 08:42:58 +0000
    # User rules for ubuntu
    ubuntu ALL=(ALL) NOPASSWD:ALL
    vagrant ALL=(ALL) NOPASSWD:ALL
____EOF

    found_vagrant=
    if [[ "$(id -u vagrant 2>/dev/null)" == "1000" ]]; then
      userdel -f vagrant || true

      if ! id -u -n ubuntu; then
        groupadd -g 1000 ubuntu
        useradd -g ubuntu -u 1000 -d /home/ubuntu -m -s /bin/bash -p '*' ubuntu
      fi

      chown -R ubuntu:ubuntu ~ubuntu

      found_vagrant=1
    fi

    if [[ -f /tmp/home/.ssh/authorized_keys ]]; then
      mkdir -p ~ubuntu/.ssh
      cp -a /tmp/home/.ssh/authorized_keys ~ubuntu/.ssh/
      chown -R ubuntu:ubuntu ~ubuntu/.ssh
    fi

    install -d -o ubuntu -g ubuntu /data /data/cache /data/git

    if [[ -n "$found_vagrant" ]]; then
      useradd -s /bin/bash vagrant || true
      chown -R vagrant:vagrant ~vagrant /tmp/kitchen
    fi

    mkdir -p "/root/.ssh"
    chmod 700 "/root/.ssh"
    ssh-keygen -f "/root/.ssh/known_hosts" -R localhost || true
    ssh -A -o BatchMode=yes -o StrictHostKeyChecking=no ubuntu@localhost "$0"
    ssh-keygen -f "/root/.ssh/known_hosts" -R localhost || true
    sync
    ;;
  *)
    sudo groupadd -g 497 docker || true
    sudo usermod -G docker ubuntu || true
    main "$@"
    ;;
esac
