# terminal-config

Run the Linux installer (with `sudo` installed):
```sh
sh linux/apply-cfg-linux.sh
chsh -s <your-shell-option> <username>
```

You can specify the distribution when needed:
```sh
sh linux/apply-cfg-linux.sh --run-as-distro <distro>
```

### Automatic updates

When zsh starts, the config checks the `main` branch of this repository through
the GitHub API, at most once every 24 hours. If a newer version is available,
you can choose whether to install it. Answer `n` to postpone the update for
seven days; pressing Enter accepts it. Managed files are applied for the next
terminal session. `curl` and internet access are required; network failures do
not prevent the shell from starting.

The updater replaces repository-managed files in `~/.my-term-cfg` (`.zshrc`,
`starship.toml`, and `nano/nanorc`). For existing installations, run
`linux/apply-cfg-linux.sh` once to install the updater.

### Test in a disposable Alpine container

From the repository root, run:

```sh
sh linux/test-in-container.sh
```

The script mounts the repository read-only and starts zsh in an ephemeral
Alpine container. Type `exit` to remove it.
