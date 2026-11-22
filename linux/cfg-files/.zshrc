# Path to your oh-my-zsh installation.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export MYCFG_FOLDER="${MYCFG_FOLDER:-$XDG_CONFIG_HOME/terminal-config}"
if [ "${TERMINAL_CONFIG_TEST:-0}" != "1" ] && [ -f "$MYCFG_FOLDER/update-config.sh" ]; then
  sh "$MYCFG_FOLDER/update-config.sh"
fi
export ZSH="$MYCFG_FOLDER/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
starship_source=${STARSHIP_CONFIG:-$MYCFG_FOLDER/starship.toml}
export STARSHIP_CONFIG="$starship_source"
if [ -f "$starship_source" ] && grep -q '# HOST_COLOR' "$starship_source"; then
    host_for_color=${STARSHIP_TEST_HOSTNAME:-$(hostname 2>/dev/null || true)}
    host_for_color=${host_for_color%%.*}
    [ -n "$host_for_color" ] || host_for_color=unknown
    host_checksum=$(printf '%s' "$host_for_color" | cksum 2>/dev/null) || host_checksum=0
    host_checksum=${host_checksum%% *}
    case "$host_checksum" in
        ''|*[!0-9]*) host_checksum=0 ;;
    esac
    host_color=$((16 + 36 * (1 + host_checksum % 5) + 6 * (1 + (host_checksum / 5) % 5) + (1 + (host_checksum / 25) % 5)))
    starship_rendered="$MYCFG_FOLDER/starship.generated.toml"
    starship_rendered_tmp="$starship_rendered.tmp.$$"
    if sed "s/fg:[0-9][0-9]*' # HOST_COLOR/fg:$host_color' # HOST_COLOR/" "$starship_source" > "$starship_rendered_tmp" &&
       grep -q "fg:$host_color' # HOST_COLOR" "$starship_rendered_tmp" &&
       mv "$starship_rendered_tmp" "$starship_rendered"; then
        export STARSHIP_CONFIG="$starship_rendered"
    else
        rm -f "$starship_rendered_tmp"
    fi
fi

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
