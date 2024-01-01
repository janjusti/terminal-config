#!/bin/sh

[ "$(which sudo)" = '' ] && echo "Install sudo and create your user first. :)" && exit

echo "Hello there! Welcome."

mycfg_folder="$HOME/.myconfig"
export XDG_CONFIG_HOME=$mycfg_folder

distro=$(awk -F'=' '/^ID=/ { print tolower($2) }' /etc/*-release | tr -d '"')
echo "##### Hmmmmm... seems like you are using '$distro'..."
case $distro in
    alpine) 
        install_cmd="sudo apk add -q";
        ;;
    ubuntu|debian) 
        install_cmd="sudo apt-get install -qy";
        export DEBIAN_FRONTEND="noninteractive";
        ;;
    rhel)
        install_cmd="sudo dnf install -qy";
        ;;
    *) 
        echo "##### Oops, I don't know if I can continue... try to fix this shell script with your distro's info :)"; 
        exit
        ;;
esac

[ -f $HOME/.zshrc ] && (echo "##### Backing up config files..." && mv $HOME/.zshrc $HOME/.zshrc.old)
[ ! -f /usr/bin/curl ] && 
(
    case $distro in
    alpine) 
        sudo apk update;
        ;;
    ubuntu|debian) 
        sudo apt-get update; 
        $install_cmd apt-utils;
        ;;
    rhel)
        sudo dnf update;
        ;;
    esac
) && (echo "##### Installing curl..." && $($install_cmd curl))
[ ! -f /bin/zsh ] && (echo "##### Installing zsh..." && $($install_cmd zsh))
[ ! -f /usr/bin/git ] && (echo "##### Installing git..." && $($install_cmd git))

echo "##### Creating folder for config files..."
mkdir -p $mycfg_folder

[ ! -f /usr/local/bin/starship ] && (echo "##### Installing starship..." && curl -sS https://starship.rs/install.sh | sh -s -- -f)
[ ! -d $mycfg_folder/.oh-my-zsh ] && (
    echo "##### Installing oh-my-zsh..."
    export ZSH=$mycfg_folder/.oh-my-zsh;
    curl -sS https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s
)

echo "##### Copying config files to '$mycfg_folder'..."
path_to_script_folder=$PWD/$(dirname "$0");
cp -r "$path_to_script_folder/cfg-files/." "$mycfg_folder/"
cp -r "$path_to_script_folder/../common/." "$mycfg_folder/"
echo "##### Creating new .zshrc file..."
echo "source $mycfg_folder/.zshrc" > $HOME/.zshrc

plugins_folder=$mycfg_folder/.oh-my-zsh/custom/plugins
[ ! -d $plugins_folder/zsh-autosuggestions ] && (
    echo "##### Installing zsh plugins..." && 
    git clone https://github.com/zsh-users/zsh-autosuggestions $plugins_folder/zsh-autosuggestions
)

echo "SUCCESS! Starting zsh..."
echo "If needed, run 'chsh' to set '/bin/zsh' as your default shell: chsh -s /usr/bin/zsh <username>"
case $distro in
    ubuntu|debian) 
        export DEBIAN_FRONTEND=
        ;;
esac
zsh