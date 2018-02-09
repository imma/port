#!/usr/bin/env bash

set -exfu
umask 0022

function main {
  export BOARD_PATH="$HOME"

  cd "$BOARD_PATH"

  if [[ ! -d .git ]]; then
		ssh -o StrictHostKeyChecking=no github.com true 2>/dev/null || true
		git clone git@github.com:imma/ubuntu
		mv ubuntu/.git .
  fi

  git fetch
	git reset --hard
  git pull

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
