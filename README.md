# 🍎 dotfiles

[![CI](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-26%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-geplant-gray?logo=linux)](https://kernel.org/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

**Dotfiles mit modernen CLI-Tools, einheitlichem Theme und integrierter Hilfe.**

> ⚠️ **Plattform-Status:** Aktuell nur auf **macOS** getestet. Die Codebasis ist für Cross-Platform (Fedora, Debian) vorbereitet, aber die Portierung ist noch nicht abgeschlossen.

## ✨ Was du bekommst

| Vorher | Nachher | Vorteil |
| ------ | ------- | ------- |
| `cat` | `bat` | mit Syntax-Highlighting |
| `cd` | `zoxide` | lernt häufige Verzeichnisse |
| `find` | `fd` | schneller, intuitive Syntax |
| `grep` | `rg` | schneller, respektiert .gitignore |
| `ls` | `eza` | mit Icons und Git-Status |

Dazu: **[Catppuccin Mocha](https://catppuccin.com/) Theme** überall, **Hilfe im Terminal** via `dothelp`, **fzf-Integration** für alles.

Alle installierten Pakete: [`setup/Brewfile`](setup/Brewfile)

## 🚀 Installation

```zsh
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/bootstrap.sh
```

Danach **Terminal neu starten**. Fertig!

> 💡 **Tipp:** Gib `dothelp` ein – zeigt Keybindings, Aliase und Wartungsbefehle.

### Voraussetzungen

#### macOS (getestet ✅)

- **Apple Silicon Mac** (arm64)
- **macOS ${macos_min}+** (${macos_min_name})
- **Internetverbindung** & Admin-Rechte

#### Linux (in Entwicklung 🚧)

- **Fedora / Debian** – Portierung geplant
- macOS-spezifische Module werden automatisch übersprungen

## 📖 Dokumentation

| Befehl | Was es zeigt |
| ------ | ------------ |
| `dothelp` | Schnellreferenz: Keybindings, Tool-Ersetzungen, Wartung |
| `cmds` | Alle Aliase und Funktionen interaktiv durchsuchen |
| `tldr <tool>` | Vollständige Tool-Doku mit dotfiles-Erweiterungen |

Mehr: [Setup](docs/setup.md) · [Anpassung](docs/customization.md) · [Contributing](CONTRIBUTING.md)

## Lizenz

[MIT](LICENSE)
