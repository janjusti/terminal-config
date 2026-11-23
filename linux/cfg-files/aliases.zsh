# Python
alias py='python3'

# Kubernetes
alias k='kubectl'

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
