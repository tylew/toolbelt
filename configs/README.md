# dotfiles

Personal shell config. Assumes Homebrew on macOS.

## Dependencies

- [eza](https://github.com/eza-community/eza) — modern `ls`
- [bat](https://github.com/sharkdp/bat) — modern `cat`
- [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter `cd`
- [yazi](https://github.com/sxyazi/yazi) — terminal file manager
- [fzf](https://github.com/junegunn/fzf) — fuzzy finder
- [starship](https://starship.rs) — prompt
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

## Install

```sh
cp .zshrc ~/.zshrc
cp .zshenv ~/.zshenv
```

## Secrets

`.zshenv` loads secrets from the macOS Keychain at shell startup (works for
scripts and non-interactive shells, not just terminals). `.zshrc` provides
`store-secret` / `get-secret` / `delete-secret` helpers to manage them. Edit the
`keychain_secrets` map in `.zshenv` to list your own vars. See
[`references/macos-keychain-secrets.md`](../references/macos-keychain-secrets.md).
