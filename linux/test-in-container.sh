#!/bin/sh

set -eu

repo_root=$(CDPATH= cd "$(dirname "$0")/.." && pwd -P)
container_name=${TERMINAL_CONFIG_TEST_CONTAINER:-terminal-config-dev}
image=${TERMINAL_CONFIG_TEST_IMAGE:-alpine:3.24}
term=${TERM:-xterm-256color}
action=${1:-shell}

usage() {
    cat <<EOF
Usage: $0 [start|shell [hostname]|stop|reset|once]

  start          Create or start the reusable test container and prepare it once.
  shell [host]   Refresh managed files from the mounted repo and open zsh.
                 Optional host overrides the hostname shown by Starship for testing.
  stop           Stop the reusable container without deleting it.
  reset          Remove the reusable container. The next start prepares it again.
  once           Run the original disposable test flow, then remove its container.

The reusable container mounts this repository at /cfg (read-only). Host edits
are visible inside it immediately. Override the name or image with
TERMINAL_CONFIG_TEST_CONTAINER or TERMINAL_CONFIG_TEST_IMAGE.
EOF
}

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required to run the test container." >&2
    exit 1
fi

container_exists() {
    docker inspect --type container "$container_name" >/dev/null 2>&1
}

ensure_container() {
    if container_exists; then
        mounted_repo=$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/cfg"}}{{.Source}}{{end}}{{end}}' "$container_name")
        if [ "$mounted_repo" != "$repo_root" ]; then
            echo "Container '$container_name' has /cfg mounted from '$mounted_repo', expected '$repo_root'." >&2
            echo "Run '$0 reset' before using this repository." >&2
            exit 1
        fi
        running=$(docker inspect --format '{{.State.Running}}' "$container_name")
        if [ "$running" != true ]; then
            docker start "$container_name" >/dev/null
        fi
    else
        docker run -d \
            --name "$container_name" \
            --hostname terminal-config-dev \
            -e "TERM=$term" \
            -v "$repo_root:/cfg:ro" \
            "$image" \
            sh -c 'while :; do sleep 3600; done' >/dev/null
    fi
}

prepare_container() {
    docker exec "$container_name" sh -ec '
        marker=/var/lib/terminal-config-test/prepared
        if [ -f "$marker" ]; then
            exit 0
        fi

        echo "Preparing reusable Alpine test container..."
        apk add --no-cache sudo git curl zsh

        if ! id cfgtest >/dev/null 2>&1; then
            adduser -D -h /home/cfgtest cfgtest
        fi
        mkdir -p /etc/sudoers.d /var/lib/terminal-config-test
        printf "%s\n" "cfgtest ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cfgtest
        chmod 0440 /etc/sudoers.d/cfgtest

        sudo -u cfgtest -H git config --global --add safe.directory /cfg
        cd /cfg/linux
        sudo -u cfgtest -H sh apply-cfg-linux.sh

        touch "$marker"
    '
}

start_reusable() {
    ensure_container
    prepare_container
    echo "Reusable test container '$container_name' is ready."
}

open_shell() {
    hostname_override=${1:-}
    start_reusable

    if [ -n "$hostname_override" ]; then
        docker exec -it \
            --user cfgtest \
            -e HOME=/home/cfgtest \
            -e "TERM=$term" \
            -e TERMINAL_CONFIG_TEST=1 \
            -e STARSHIP_CONFIG=/cfg/common/starship.toml \
            -e "STARSHIP_TEST_HOSTNAME=$hostname_override" \
            "$container_name" \
            sh /cfg/linux/apply-cfg-linux.sh
    else
        docker exec -it \
            --user cfgtest \
            -e HOME=/home/cfgtest \
            -e "TERM=$term" \
            -e TERMINAL_CONFIG_TEST=1 \
            -e STARSHIP_CONFIG=/cfg/common/starship.toml \
            "$container_name" \
            sh /cfg/linux/apply-cfg-linux.sh
    fi
}

run_once() {
    docker run --rm -it \
        -e "TERM=$term" \
        -v "$repo_root:/cfg:ro" \
        "$image" \
        sh -ec '
            apk add --no-cache sudo git curl zsh
            adduser -D -h /home/cfgtest cfgtest
            mkdir -p /etc/sudoers.d
            printf "%s\n" "cfgtest ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cfgtest
            chmod 0440 /etc/sudoers.d/cfgtest
            sudo -u cfgtest -H git config --global --add safe.directory /cfg
            cd /cfg/linux
            sudo -u cfgtest -H sh apply-cfg-linux.sh
        '
}

case "$action" in
    start)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        start_reusable
        ;;
    shell)
        [ "$#" -le 2 ] || { usage >&2; exit 2; }
        open_shell "${2:-}"
        ;;
    stop)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        if container_exists; then
            running=$(docker inspect --format '{{.State.Running}}' "$container_name")
            if [ "$running" = true ]; then
                docker stop "$container_name" >/dev/null
            fi
            echo "Stopped '$container_name'. It is still available with '$0 start'."
        else
            echo "Container '$container_name' does not exist." >&2
            exit 1
        fi
        ;;
    reset)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        if container_exists; then
            docker rm -f "$container_name" >/dev/null
            echo "Removed '$container_name'. The next start will prepare a fresh container."
        else
            echo "Container '$container_name' does not exist."
        fi
        ;;
    once)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        run_once
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
