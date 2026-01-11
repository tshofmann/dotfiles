# 🍎 dotfiles

[![CI](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-26%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

> Automatisiertes Dotfile-Setup mit modernen CLI-Ersetzungen.

## Quickstart

```zsh
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/bootstrap.sh
```

Nach Terminal-Neustart:

```zsh
cd ~/dotfiles && stow --adopt -R terminal editor && git reset --hard HEAD && bat cache --build && tldr --update
```

> ⚠️ **Achtung:** `git reset --hard` verwirft lokale Änderungen. Siehe [Setup](docs/setup.md) für Details.

## Voraussetzungen

- **Apple Silicon Mac** (arm64)
- **macOS 26+** (Tahoe) – getestet auf macOS 26 (Tahoe)
- **Internetverbindung** & Admin-Rechte

## Hilfe & Dokumentation

| Thema | Beschreibung |
| ----- | ------------ |
| `dothelp` | Hilfe/Dokumentation im Terminal: Aliase, Keybindings, fzf-Shortcuts, Tool-Ersetzungen |
| [Setup](docs/setup.md) | Schritt-für-Schritt Anleitung |
| [Anpassung](docs/customization.md) | Starship, Aliase, ZSH anpassen |
| [Contributing](CONTRIBUTING.md) | Für Entwickler: Architektur, Hooks, Workflow |

## Lizenz

[MIT](LICENSE)
