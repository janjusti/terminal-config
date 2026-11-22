#!/bin/sh

set -e

if ! command -v sudo >/dev/null 2>&1; then
    echo "Install sudo and create your user first. :)" >&2
    exit 1
fi

echo "Hello there! Welcome."

path_to_script_folder=$(dirname "$(realpath "$0")")
. "$path_to_script_folder/zshrc-hook.sh"

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
export XDG_CONFIG_HOME="$config_home"
mycfg_folder="$config_home/terminal-config"
legacy_cfg_folder="$HOME/.my-term-cfg"
export MYCFG_FOLDER="$mycfg_folder"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --run-as-distro)
            distro="${2:-}"
            shift 2
            ;;
        --run-as-distro=*)
            distro="${1#*=}"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$distro" ]; then
    distro=$(sed -n 's/^ID=//p' /etc/os-release 2>/dev/null | tr -d '"')
fi
echo "##### Hmmmmm... seems like you are using '$distro'..."
case $distro in
    alpine|ubuntu|debian|linuxmint|rhel) ;;
    *) 
        echo "##### Unsupported distribution '$distro'. Update this script with the correct package manager." >&2
        exit 1
        ;;
esac

packages_to_install=""
for package in curl zsh git; do
    if ! command -v "$package" >/dev/null 2>&1; then
        packages_to_install="$packages_to_install $package"
    fi
done

if [ -n "$packages_to_install" ]; then
    set -- $packages_to_install
    case $distro in
        alpine)
            sudo apk add --no-cache "$@"
            ;;
        ubuntu|debian|linuxmint)
            sudo apt-get update
            sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
            ;;
        rhel)
            sudo dnf install -y "$@"
            ;;
    esac
fi

echo "##### Creating folder for config files..."
mkdir -p "$config_home"
if [ -d "$legacy_cfg_folder" ] && [ ! -e "$mycfg_folder" ]; then
    echo "##### Migrating config files from '$legacy_cfg_folder'..."
    cp -a "$legacy_cfg_folder" "$mycfg_folder"
    echo "##### Keeping '$legacy_cfg_folder' as a rollback copy."
elif [ -d "$legacy_cfg_folder" ] && [ -e "$mycfg_folder" ]; then
    echo "##### Keeping the existing config in '$mycfg_folder'; legacy files remain in '$legacy_cfg_folder'."
fi
mkdir -p "$mycfg_folder"

install_tmp=$(mktemp -d "${TMPDIR:-/tmp}/terminal-config-install.XXXXXX")
trap 'rm -rf "$install_tmp"' EXIT HUP INT TERM

if ! command -v starship >/dev/null 2>&1; then
    echo "##### Installing starship..."
    curl -fsSL https://starship.rs/install.sh -o "$install_tmp/starship-install.sh"
    sh "$install_tmp/starship-install.sh" -f
fi

if [ ! -d "$mycfg_folder/.oh-my-zsh" ]; then
    echo "##### Installing oh-my-zsh..."
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$install_tmp/oh-my-zsh-install.sh"
    env ZSH="$mycfg_folder/.oh-my-zsh" sh "$install_tmp/oh-my-zsh-install.sh" --unattended
fi

echo "##### Copying config files to '$mycfg_folder'..."
cp -r "$path_to_script_folder/cfg-files/." "$mycfg_folder/"
cp -r "$path_to_script_folder/../common/." "$mycfg_folder/"
cp "$path_to_script_folder/update-config.sh" "$mycfg_folder/update-config.sh"
local_cfg_revision=$(git -C "$path_to_script_folder/.." rev-parse HEAD 2>/dev/null || true)
if [ -n "$local_cfg_revision" ]; then
    printf '%s\n' "$local_cfg_revision" > "$mycfg_folder/.update-state"
fi
echo "##### Connecting terminal-config to the existing .zshrc..."
tc_install_zshrc_hook "$mycfg_folder" "$legacy_cfg_folder"

plugins_folder="$mycfg_folder/.oh-my-zsh/custom/plugins"
if [ ! -d "$plugins_folder/zsh-autosuggestions" ]; then
    echo "##### Installing zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_folder/zsh-autosuggestions"
fi

echo "SUCCESS! Starting zsh..."
echo "If needed, run 'chsh' to set '/bin/zsh' as your default shell: chsh -s /usr/bin/zsh <username>"
zsh
