# Path to your oh-my-zsh installation.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export MYCFG_FOLDER="${MYCFG_FOLDER:-$XDG_CONFIG_HOME/terminal-config}"
if [ "${TERMINAL_CONFIG_TEST:-0}" != "1" ] && [ -f "$MYCFG_FOLDER/update-config.sh" ]; then
  sh "$MYCFG_FOLDER/update-config.sh"
fi
export ZSH="$MYCFG_FOLDER/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$MYCFG_FOLDER/starship.toml}"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# Do not save commands that start with a space in shell history.
setopt HIST_IGNORE_SPACE

### customzera

# Start Docker daemon automatically when logging in if it is installed and not running.
if command -v dockerd >/dev/null 2>&1 && command -v ps >/dev/null 2>&1; then
    RUNNING=$(ps aux | grep '[d]ockerd' || true)
    if [ -z "$RUNNING" ]; then
        (sudo dockerd > /dev/null 2>&1 &)
    fi
fi

alias py="python3"
alias k="kubectl"
export TZ=America/Fortaleza

eval "$(starship init zsh)"
