# homebrew-tumpa-cli

Homebrew tap for [tumpa-cli](https://github.com/tumpaproject/tumpa-cli) —
OpenPGP CLI and SSH agent backed by the tumpa keystore.

## Install

```
brew tap tumpaproject/tumpa-cli
brew install tumpa-cli
```

## Start the agent on login

```
brew services start tumpa-cli
```

Add to your `~/.zshrc`:

```bash
export SSH_AUTH_SOCK="$HOME/.tumpa/tcli-ssh.sock"
```

## What's included

- `tcli` — GPG replacement for git signing, encryption, key management
- `tpass` — drop-in replacement for `pass` (password-store)
- Shell completions for bash, zsh, and fish
- Launch Agent for auto-starting `tcli agent --ssh` on login

## More info

- [Usage Guide](https://github.com/tumpaproject/tumpa-cli/blob/main/docs/usage.md)
- [tumpa.rocks](https://tumpa.rocks)
