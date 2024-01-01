# Path to your oh-my-zsh installation.
MYCFG_FOLDER="$HOME/.myconfig"
export ZSH="$MYCFG_FOLDER/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
export STARSHIP_CONFIG="$MYCFG_FOLDER/starship.toml"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

### customzera

## workaround para o lerdao do wsl2
# checks to see if we are in a windows or linux dir
function isWinDir {
  case $PWD in
    /mnt/*) return $(true);;
    *) return $(false);;
  esac
}
# wrap the git command to either run windows git or linux
function git {
  if isWinDir
  then
    git.exe "$@"
  else
    /usr/bin/git "$@"
  fi
}

# Start Docker daemon automatically when logging in if not running.
RUNNING=`ps aux | grep dockerd | grep -v grep`
if [ -z "$RUNNING" ]; then
    (sudo dockerd > /dev/null 2>&1 &)
fi

alias py="python3"
alias k="kubectl"
export TZ=America/Fortaleza

eval "$(starship init zsh)"
