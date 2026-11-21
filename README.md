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

To check for updates immediately, bypassing the daily interval and any snooze:

```sh
sh "$HOME/.my-term-cfg/update-config.sh" --force
```

The updater still asks before installing a newer revision and does nothing if
the installed revision is already current.

### Test in an Alpine container

From the repository root, run:

```sh
sh linux/test-in-container.sh
```

The default `shell` action creates or reuses a named Alpine container and opens
zsh in it. The repository is mounted read-only at `/cfg`, so edits on the host
are immediately visible. The Starship test shell reads
`/cfg/common/starship.toml` directly, and refreshes the other managed files
from the mount each time it opens. Package and tool installation happens only
when the container is first prepared.

```sh
sh linux/test-in-container.sh start       # prepare without opening zsh
sh linux/test-in-container.sh shell       # open zsh and use the host's hostname
sh linux/test-in-container.sh shell host-a # preview with a chosen hostname
sh linux/test-in-container.sh stop        # stop but keep the container
sh linux/test-in-container.sh reset       # remove it; next start is fresh
sh linux/test-in-container.sh once        # one disposable run, as before
```

The test shell skips the automatic updater so it cannot replace the mounted
worktree with a downloaded revision. The optional hostname is passed through
`STARSHIP_TEST_HOSTNAME` and affects only that test session.
