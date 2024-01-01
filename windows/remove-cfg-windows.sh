#!/bin/sh

echo "Removing config files..."
rm -rf $HOME/.myconfig/ $HOME/.cache/starship;
rm -f $HOME/.bashrc;
[ -f $HOME/.bashrc.old ] && (echo "Restoring .bashrc file..." && mv $HOME/.bashrc.old $HOME/.bashrc)
[ ! -f $HOME/.bash_history ] && (echo "Creating .bash_history file..." && echo > $HOME/.bash_history)
echo "Done. You are now free to use your own terminal config. :)"
source $HOME/.bashrc