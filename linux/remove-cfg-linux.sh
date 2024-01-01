#!/bin/sh

mycfg_folder="$HOME/.my-term-cfg"

distro=$(awk -F'=' '/^ID=/ { print tolower($2) }' /etc/*-release | tr -d '"')
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
rm -rf $mycfg_folder $HOME/.cache/starship;
rm -f $HOME/.zshrc;
[ -f $HOME/.zshrc.old ] && (echo "Restoring .zshrc file..." && mv $HOME/.zshrc.old $HOME/.zshrc);
# echo "Uninstalling apps..."
# $uninstall_cmd git zsh curl;
# [ -f /usr/local/bin/starship ] && (echo "Uninstalling starship..." && rm -f /usr/local/bin/starship);
echo "Done. You are now free to use your own terminal config. :)"