mycfg_folder="$HOME/.myconfig"
export PATH=$PATH:"$mycfg_folder/bin"
export STARSHIP_CONFIG="$mycfg_folder/starship.toml"
export LC_CTYPE=en_US.UTF-8

bind 'set completion-ignore-case on'

### using pyreadline3 instead...
# maybe make sure that pyreadline3 is alive?
#export PYTHONSTARTUP="$GITBASH_CFG/.pythonrc"
#alias py='winpty py'
alias k="kubectl"

PROMPT_COMMAND='history -a'

# source "$GITBASH_CFG/bash_completion.d/git"

eval "$(starship init bash)"