#!/usr/bin/env bash

set -efu
umask 0022

function main {
  cd "$HOME"
  source .bash_profile

  ssh -o StrictHostKeyChecking=no git@github.com true 2>/dev/null || true

  sudo chgrp docker /var/run/docker.sock

  block sync fast
  make cache
}

if [[ "$(id -u -n)" == "root" ]]; then
  if [[ -r "$HOME/.ssh/ssh_auth_sock" ]]; then
    export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
  fi
  ssh -A -o BatchMode=yes -o StrictHostKeyChecking=no ubuntu@localhost "$0"
else
  main "$@"
fi
