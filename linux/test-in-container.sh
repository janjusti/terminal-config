#!/bin/sh

set -eu

repo_root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required to run the disposable test container." >&2
    exit 1
fi

docker run --rm -it \
    -e "TERM=${TERM:-xterm-256color}" \
    -v "$repo_root:/cfg:ro" \
    alpine:3.24 \
    sh -ec '
        apk add --no-cache sudo git
        adduser -D -h /home/cfgtest cfgtest
        mkdir -p /etc/sudoers.d
        printf "%s\n" "cfgtest ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cfgtest
        chmod 0440 /etc/sudoers.d/cfgtest
        sudo -u cfgtest -H git config --global --add safe.directory /cfg
        cd /cfg/linux
        sudo -u cfgtest -H sh apply-cfg-linux.sh
    '
