#!/bin/sh

set -e

path_to_script_folder=$(dirname "$(realpath "$0")")
. "$path_to_script_folder/zshrc-hook.sh"

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
mycfg_folder="$config_home/terminal-config"
legacy_cfg_folder="$HOME/.my-term-cfg"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --run-as-distro)
            distro="$2"
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
    distro=$(awk -F'=' '/^ID=/ { print tolower($2) }' /etc/*-release | tr -d '"')
fi
echo "##### Hmmmmm... seems like you are using '$distro'..."
case $distro in
    alpine) 
        uninstall_cmd="apk del -q" 
        ;;
    ubuntu|debian) 
        uninstall_cmd="apt-get remove -qy"; 
        export DEBIAN_FRONTEND="noninteractive" 
        ;;
    *) 
        echo "##### Oops, I don't know if I can continue... try to fix this shell script with your distro's info :)"; 
        exit
        ;;
esac

echo "Removing config files..."
tc_remove_zshrc_hook "$mycfg_folder" "$legacy_cfg_folder"
rm -rf "$mycfg_folder" "$legacy_cfg_folder" "$HOME/.cache/starship"
# echo "Uninstalling apps..."
# $uninstall_cmd git zsh curl;
# [ -f /usr/local/bin/starship ] && (echo "Uninstalling starship..." && rm -f /usr/local/bin/starship);
echo "Done. You are now free to use your own terminal config. :)"
