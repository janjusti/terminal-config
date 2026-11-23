# Shared helpers for connecting terminal-config to the user's zsh startup file.

tc_install_zshrc_hook() {
    cfg_folder=$1
    legacy_folder=$2
    zshrc="$HOME/.zshrc"
    if [ -L "$zshrc" ]; then
        zshrc=$(realpath "$zshrc") || return 1
    fi
    original_zshrc=$zshrc
    legacy_source="source $legacy_folder/.zshrc"
    current_source="source $cfg_folder/.zshrc"
    marker_start='# >>> terminal-config managed block >>>'
    marker_end='# <<< terminal-config managed block <<<'

    # Recover the pre-terminal-config zshrc when the active file is only the
    # wrapper written by older installers and its backup still has that wrapper.
    if [ -f "$zshrc" ] && [ -f "$HOME/.zshrc.old" ] &&
       [ "$(wc -l < "$zshrc")" -eq 1 ] &&
       grep -Fqx "$legacy_source" "$zshrc" &&
       grep -Fqx "$legacy_source" "$HOME/.zshrc.old"; then
        original_zshrc="$HOME/.zshrc.old"
        echo "##### Restoring the previous .zshrc customizations..."
    fi

    hook_tmp=$(mktemp "$HOME/.zshrc.terminal-config.XXXXXX") || return 1
    if [ -f "$original_zshrc" ]; then
        cp -p "$original_zshrc" "$hook_tmp" || {
            rm -f "$hook_tmp"
            return 1
        }
    fi

    if grep -Fqx "$marker_start" "$hook_tmp" 2>/dev/null &&
       grep -Fqx "$marker_end" "$hook_tmp" 2>/dev/null; then
        transformed_tmp=$(mktemp "$HOME/.zshrc.terminal-config.XXXXXX") || {
            rm -f "$hook_tmp"
            return 1
        }
        cp -p "$hook_tmp" "$transformed_tmp" || {
            rm -f "$hook_tmp" "$transformed_tmp"
            return 1
        }
        awk \
            -v start="$marker_start" \
            -v finish="$marker_end" \
            '
                $0 == start {
                    print
                    print "export MYCFG_FOLDER=\"${MYCFG_FOLDER:-${XDG_CONFIG_HOME:-$HOME/.config}/terminal-config}\""
                    print "if [ -r \"$MYCFG_FOLDER/.zshrc\" ]; then source \"$MYCFG_FOLDER/.zshrc\"; fi"
                    inside = 1
                    next
                }
                $0 == finish {
                    if (inside) {
                        print
                        inside = 0
                        next
                    }
                }
                inside { next }
                { print }
            ' "$hook_tmp" > "$transformed_tmp"
        mv "$transformed_tmp" "$hook_tmp"
    elif ! grep -Fqx "$marker_start" "$hook_tmp" 2>/dev/null; then
        if grep -Fqx "$legacy_source" "$hook_tmp" 2>/dev/null ||
           grep -Fqx "$current_source" "$hook_tmp" 2>/dev/null; then
            transformed_tmp=$(mktemp "$HOME/.zshrc.terminal-config.XXXXXX") || {
                rm -f "$hook_tmp"
                return 1
            }
            cp -p "$hook_tmp" "$transformed_tmp" || {
                rm -f "$hook_tmp" "$transformed_tmp"
                return 1
            }
            awk \
                -v legacy="$legacy_source" \
                -v current="$current_source" \
                -v start="$marker_start" \
                -v finish="$marker_end" \
                '
                    $0 == legacy || $0 == current {
                        if (!inserted) {
                            print start
                            print "export MYCFG_FOLDER=\"${MYCFG_FOLDER:-${XDG_CONFIG_HOME:-$HOME/.config}/terminal-config}\""
                            print "if [ -r \"$MYCFG_FOLDER/.zshrc\" ]; then source \"$MYCFG_FOLDER/.zshrc\"; fi"
                            print finish
                            inserted = 1
                        }
                        next
                    }
                    { print }
                ' "$hook_tmp" > "$transformed_tmp"
            mv "$transformed_tmp" "$hook_tmp"
        else
            transformed_tmp=$(mktemp "$HOME/.zshrc.terminal-config.XXXXXX") || {
                rm -f "$hook_tmp"
                return 1
            }
            cp -p "$hook_tmp" "$transformed_tmp" || {
                rm -f "$hook_tmp" "$transformed_tmp"
                return 1
            }
            {
                printf '\n%s\n' "$marker_start"
                printf '%s\n' 'export MYCFG_FOLDER="${MYCFG_FOLDER:-${XDG_CONFIG_HOME:-$HOME/.config}/terminal-config}"'
                printf '%s\n' 'if [ -r "$MYCFG_FOLDER/.zshrc" ]; then source "$MYCFG_FOLDER/.zshrc"; fi'
                printf '%s\n' "$marker_end"
                printf '\n'
                cat "$hook_tmp"
            } > "$transformed_tmp"
            mv "$transformed_tmp" "$hook_tmp"
        fi
    fi

    if [ ! -f "$zshrc" ] || ! cmp -s "$zshrc" "$hook_tmp"; then
        mv "$hook_tmp" "$zshrc"
    else
        rm -f "$hook_tmp"
    fi
}

tc_remove_zshrc_hook() {
    cfg_folder=$1
    legacy_folder=$2
    zshrc="$HOME/.zshrc"
    if [ -L "$zshrc" ]; then
        zshrc=$(realpath "$zshrc") || return 1
    fi
    [ -f "$zshrc" ] || return 0

    original_zshrc=$zshrc
    legacy_source="source $legacy_folder/.zshrc"
    current_source="source $cfg_folder/.zshrc"
    marker_start='# >>> terminal-config managed block >>>'
    marker_end='# <<< terminal-config managed block <<<'

    if [ -f "$HOME/.zshrc.old" ] &&
       [ "$(wc -l < "$zshrc")" -eq 1 ] &&
       grep -Fqx "$legacy_source" "$zshrc" &&
       grep -Fqx "$legacy_source" "$HOME/.zshrc.old"; then
        original_zshrc="$HOME/.zshrc.old"
    fi

    hook_tmp=$(mktemp "$HOME/.zshrc.terminal-config.XXXXXX") || return 1
    cp -p "$original_zshrc" "$hook_tmp" || {
        rm -f "$hook_tmp"
        return 1
    }

    awk \
        -v legacy="$legacy_source" \
        -v current="$current_source" \
        -v start="$marker_start" \
        -v finish="$marker_end" \
        '
            $0 == start { inside = 1; next }
            $0 == finish { inside = 0; next }
            inside { next }
            $0 == legacy || $0 == current { next }
            { print }
        ' "$original_zshrc" > "$hook_tmp"
    mv "$hook_tmp" "$zshrc"
}
