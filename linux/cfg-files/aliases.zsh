# Python
alias py='python3'

# Kubernetes
alias k='kubectl'

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
