#!/bin/sh

[ $SHELL != "/usr/bin/bash" ] && 
(echo "Well... where is your bash? Try again while running bash instead of '$SHELL'..." && exit);

echo "Hello there! Welcome."

mycfg_folder="$HOME/.myconfig"
export XDG_CONFIG_HOME=$mycfg_folder

[ -f $HOME/.bashrc ] && (echo "##### Backing up config files..." && mv $HOME/.bashrc $HOME/.bashrc.old)
echo "##### Creating folder for config files..."
mkdir -p $mycfg_folder/bin
[ ! -f $mycfg_folder/bin/starship.exe ] && (echo "##### Installing starship..." && curl -sS https://starship.rs/install.sh | sh -s -- -b "$mycfg_folder/bin/" -f)
echo "##### Copying config files to '$mycfg_folder'..."
path_to_script_folder=$PWD/$(dirname "$0");
cp -r "$path_to_script_folder/cfg-files/." "$mycfg_folder/"
cp -r "$path_to_script_folder/../common/." "$mycfg_folder/"
echo "##### Creating new .bashrc file..."
echo "source $mycfg_folder/.bashrc" > $HOME/.bashrc
[ ! -f $HOME/.bash_history ] && (echo "Creating .bash_history file..." && echo > $HOME/.bash_history)
echo "##### Overwriting PowerShell cfg file..."
echo "Invoke-Expression (&starship init powershell)" > $(powershell -noprofile -command 'echo $PROFILE')
echo "SUCCESS! Restarting bash..." & 
source $HOME/.bashrc