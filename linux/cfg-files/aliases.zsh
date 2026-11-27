# Python
alias py='python3'

# Stage the worktree and commit with the supplied message. Quote multiline messages.
gac() {
  if (( $# == 0 )); then
    print -u2 -- 'Uso: gac "mensagem do commit"'
    return 2
  fi

  command git add . && command git commit -m "$*"
}

# Kubernetes
alias k='kubectl'

# Recreate the current Compose project with down -t 0 and up -d.
# dcr                         # entire project, in the background
# dcr tests web               # selected services (and their dependencies)
# dcr -f tests                # run up in the foreground
# dcr --build tests           # build images before starting
# dcr --profile dev -f        # use a Compose profile
# dcr --file compose.dev.yml  # use an alternative Compose file
# ENABLE_MOCK=0 dcr -f        # set an environment variable for both commands
# --file and --profile can be repeated; -- ends option parsing.
# Up runs only if down succeeds. Named volumes are not removed.
dcr() {
  local foreground=0 build=0
  local -a compose_options services up_options

  while (( $# )); do
    case "$1" in
      -f|--foreground) foreground=1 ;;
      -b|--build) build=1 ;;
      --file|--profile)
        if (( $# < 2 )) || [[ -z "$2" || "$2" == -* ]]; then
          print -u2 -- "dcr: $1 requires a value"
          return 2
        fi
        compose_options+=("$1" "$2")
        shift
        ;;
      --file=*|--profile=*)
        if [[ -z "${1#*=}" ]]; then
          print -u2 -- "dcr: ${1%%=*} requires a value"
          return 2
        fi
        compose_options+=("$1")
        ;;
      --)
        shift
        services+=("$@")
        break
        ;;
      -*)
        print -u2 -- "dcr: unknown option: $1"
        return 2
        ;;
      *) services+=("$1") ;;
    esac
    shift
  done

  (( foreground )) || up_options+=(-d)
  (( build )) && up_options+=(--build)
  command docker compose "${compose_options[@]}" down -t 0 "${services[@]}" &&
    command docker compose "${compose_options[@]}" up "${up_options[@]}" "${services[@]}"
}

# Run NVM-managed tools on demand without adding Node/npm to the startup PATH.
nvmrun() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  local node_path

  if [[ -z "${_TC_NVM_DEFAULT_BIN:-}" ]]; then
    if [[ ! -s "$nvm_dir/nvm.sh" ]]; then
      print -u2 -- "nvmrun: NVM was not found at $nvm_dir"
      return 127
    fi

    if (( ! $+functions[nvm] )); then
      source "$nvm_dir/nvm.sh" --no-use
    fi

    node_path=$(nvm which default) || return $?
    _TC_NVM_DEFAULT_BIN="${node_path:h}"
  fi

  local -x PATH="$_TC_NVM_DEFAULT_BIN:$PATH"
  command "$@"
}

openspec() { nvmrun openspec "$@" }
npx() { nvmrun npx "$@" }

# Discard unstaged changes and remove untracked files/directories in this repo.
# Staged changes and ignored files are preserved. Requires typing "y".
git_discard_worktree() {
  local repo_root confirmation

  repo_root=$(command git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 -- 'gdiscard: not inside a Git repository.'
    return 1
  }

  print -n -- "Descartar alterações não staged e remover arquivos não rastreados em $repo_root? Alterações staged e arquivos ignorados serão mantidos. Digite 'y' para continuar: "
  read -r confirmation || return 1
  if [[ "$confirmation" != 'y' ]]; then
    print -- 'Operação cancelada.'
    return 1
  fi

  command git -C "$repo_root" restore . &&
    command git -C "$repo_root" clean -fd
}
alias gdiscard='git_discard_worktree'
