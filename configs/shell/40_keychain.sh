# keychain.sh - meant to be sourced in .bash_profile/.zshrc

if [[ `uname` == 'Linux' ]] && [[ -f ~/.ssh/id_ed25519 ]]; then
    eval $(keychain --eval --quiet --agents ssh id_ed25519)
elif [[ `uname` == 'Darwin' ]]; then
    # SSH Agent Configuration (via keychain & 1Password)
    if command -v op &> /dev/null; then
        # Set SSH_ASKPASS to use the 1Password helper script for passphrase prompts.
        export SSH_ASKPASS="$HOME/.ssh/askpass-1password.sh"

        # Ensure ssh-add uses SSH_ASKPASS even in non-graphical/terminal sessions.
        export SSH_ASKPASS_REQUIRE="prefer"
    fi

    # Execute keychain:
    # --eval: Output shell commands (export SSH_AUTH_SOCK=...; export SSH_AGENT_PID=...)
    # --quiet: Suppress informational messages.
    # --agents ssh: Ensure ssh-agent is used (default, but explicit).
    # --inherit any-once: Reuse an existing agent managed by keychain if possible (local or forwarded).
    # id_ed25519: The specific key to load into the agent (will use SSH_ASKPASS).
    # The 'eval $(...)' executes the commands output by keychain in the current shell context.
    eval $(keychain --eval --quiet --agents ssh --inherit any-once id_ed25519)

    # Clean up the temporary ASKPASS variables; they are only needed when adding keys.
    unset SSH_ASKPASS
    unset SSH_ASKPASS_REQUIRE

    # Or use 1Password SSH agent (https://developer.1password.com/docs/ssh/get-started/)
    # export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
fi
