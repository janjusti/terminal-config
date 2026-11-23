#!/bin/sh

# Check for a new config revision at most once per day, then update the
# Linux config files installed under ${XDG_CONFIG_HOME:-~/.config}/terminal-config.

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
cfg_folder=${MYCFG_FOLDER:-"$config_home/terminal-config"}
state_file="$cfg_folder/.update-state"
check_interval=86400
snooze_interval=604800
repo="janjusti/terminal-config"
branch="main"
force_update=0

case "$#:${1:-}" in
    0:)
        ;;
    1:--force)
        force_update=1
        ;;
    *)
        printf 'Usage: %s [--force]\n' "$0" >&2
        exit 2
        ;;
esac

save_state() {
    saved_sha=$1
    [ "$now" -gt 0 ] || return 0
    { printf '%s\n' "$saved_sha" "$now"; } > "$state_file.tmp" &&
        mv "$state_file.tmp" "$state_file"
}

defer_update() {
    [ "$now" -gt 0 ] || return 0
    deferred_until=$((now + snooze_interval))
    {
        printf '%s\n' "$local_sha" "$now" "$remote_sha" "$deferred_until"
    } > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
}

fail_update() {
    printf 'terminal-config update failed: %s\n' "${failure_reason:-unknown error}" >&2
    save_state "$local_sha"
    exit 1
}

command -v curl >/dev/null 2>&1 || exit 0
command -v tar >/dev/null 2>&1 || exit 0
[ -t 0 ] && [ -t 1 ] || exit 0

mkdir -p "$cfg_folder" || exit 0

now=$(date +%s 2>/dev/null)
case "$now" in
    ''|*[!0-9]*) now=0 ;;
esac
last_checked=$(sed -n '2p' "$state_file" 2>/dev/null)
deferred_until=$(sed -n '4p' "$state_file" 2>/dev/null)
case "$last_checked" in
    ''|*[!0-9]*) last_checked=0 ;;
esac
case "$deferred_until" in
    ''|*[!0-9]*) deferred_until=0 ;;
esac

if [ "$force_update" -eq 0 ]; then
    if [ "$now" -gt 0 ] && [ "$deferred_until" -gt "$now" ]; then
        exit 0
    fi

    if [ "$now" -gt 0 ] && [ "$last_checked" -gt 0 ] &&
       [ "$now" -ge "$last_checked" ] &&
       [ "$((now - last_checked))" -lt "$check_interval" ]; then
        exit 0
    fi
fi

api_url="https://api.github.com/repos/$repo/commits/$branch"
remote_sha=$(curl -fsSL --connect-timeout 2 --max-time 5 \
    -H 'Accept: application/vnd.github+json' \
    -H 'User-Agent: terminal-config-updater' \
    "$api_url" 2>/dev/null |
    tr -d '\n' |
    sed -n 's/^{[[:space:]]*"sha"[[:space:]]*:[[:space:]]*"\([0-9a-f][0-9a-f]*\)".*/\1/p')

local_sha=$(sed -n '1p' "$state_file" 2>/dev/null)
case "$remote_sha" in
    ''|*[!0-9a-f]*) save_state "$local_sha"; exit 0 ;;
esac

if [ "$remote_sha" = "$local_sha" ]; then
    save_state "$remote_sha"
    exit 0
fi

printf '\nA new terminal-config version is available.\nUpdate now? [Y/n] '
IFS= read -r answer || answer=''
printf '\n'
case "$answer" in
    ''|[Yy]|[Yy][Ee][Ss]) ;;
    *)
        defer_update
        printf 'Update postponed for 7 days.\n'
        exit 0
        ;;
esac

printf 'Downloading terminal-config update %s...\n' "$remote_sha"
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/terminal-config-update.XXXXXX" 2>/dev/null) || {
    failure_reason='could not create a temporary directory'
    fail_update
}
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

archive="$tmp_dir/repo.tar.gz"
archive_url="https://codeload.github.com/$repo/tar.gz/$remote_sha"
if ! curl -fsSL --connect-timeout 2 --max-time 20 "$archive_url" -o "$archive" 2>/dev/null; then
    failure_reason='could not download the GitHub archive'
    fail_update
fi
if ! tar -xzf "$archive" -C "$tmp_dir" 2>/dev/null; then
    failure_reason='could not extract the GitHub archive'
    fail_update
fi

repo_dir="$tmp_dir/terminal-config-$remote_sha"
files='linux/cfg-files/.zshrc linux/cfg-files/aliases.zsh'

# Stage every managed file before replacing any installed config.
mkdir -p "$tmp_dir/next/common/nano" || {
    failure_reason='could not create the staging directory'
    fail_update
}
for relative_path in $files common/starship.toml common/nano/nanorc linux/update-config.sh; do
    if [ ! -f "$repo_dir/$relative_path" ]; then
        failure_reason="the GitHub archive is missing $relative_path"
        fail_update
    fi
    mkdir -p "$tmp_dir/next/$(dirname "$relative_path")" || {
        failure_reason="could not stage $relative_path"
        fail_update
    }
    cp "$repo_dir/$relative_path" "$tmp_dir/next/$relative_path" || {
        failure_reason="could not stage $relative_path"
        fail_update
    }
done

for relative_path in $files common/starship.toml common/nano/nanorc linux/update-config.sh; do
    destination="$cfg_folder/${relative_path#*/cfg-files/}"
    case "$relative_path" in
        linux/cfg-files/*)
            destination="$cfg_folder/$(basename "$relative_path")"
            ;;
        linux/update-config.sh)
            destination="$cfg_folder/update-config.sh"
            ;;
        common/*)
            destination="$cfg_folder/${relative_path#common/}"
            ;;
    esac
    mkdir -p "$(dirname "$destination")" || {
        failure_reason="could not prepare $destination"
        fail_update
    }
    mv "$tmp_dir/next/$relative_path" "$destination" || {
        failure_reason="could not replace $destination"
        fail_update
    }
done

if [ "$now" -gt 0 ]; then
    save_state "$remote_sha"
else
    printf '%s\n' "$remote_sha" > "$state_file.tmp" &&
        mv "$state_file.tmp" "$state_file"
fi

printf 'Configuration updated to %s. Open a new terminal to load it.\n' "$remote_sha"
