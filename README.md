# 🍎 dotfiles

[![CI](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-26%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-vorbereitet-yellow?logo=linux)](https://kernel.org/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

**Dotfiles mit modernen CLI-Tools, einheitlichem Theme und integrierter Hilfe.**

> ⚠️ **Plattform-Status:** Auf **macOS** produktiv getestet. Linux-Bootstrap (Fedora, Debian, Arch) in Docker/Headless validiert – Desktop (Wayland) und echte Hardware noch ausstehend.

## ✨ Was du bekommst

| Vorher | Nachher | Vorteil |
| ------ | ------- | ------- |
| `cat` | `bat` | mit Syntax-Highlighting |
| `cd` | `zoxide` | lernt häufige Verzeichnisse |
| `find` | `fd` | schneller, intuitive Syntax |
| `grep` | `rg` | schneller, respektiert .gitignore |
| `ls` | `eza` | mit Icons und Git-Status |
| `neofetch` | `fastfetch` | schnellere System-Übersicht |
| `top, htop` | `btop` | moderner Ressourcen-Monitor |
| `unrar` | `7z` | 7-Zip als schnellerer Ersatz |

### Interaktive Workflows (fzf)

Alle Workflows nutzen [fzf](https://github.com/junegunn/fzf) mit bat-Preview, Keybindings und Catppuccin-Theming:

| Bereich | Funktionen |
| ------- | ---------- |
| Git | `git-log`, `git-branch`, `git-stage`, `git-stash` |
| GitHub | `gh-pr`, `gh-issue`, `gh-run`, `gh-repo`, `gh-gist` |
| System | `procs`, `help`, `cmds`, `vars` |
| Navigation | `jump`, `pick`, `zj` |
| Suche | `rg-live` |
| Pakete | `brew-add`, `brew-rm` |

### Media-Toolkit

| Tool | Funktionen |
| ---- | ---------- |
| ffmpeg | `v2mp3`, `vthumb`, `vcut`, `vcompress`, `v2gif`, `vinfo` |
| magick | `imgresize`, `towebp`, `imgmeta`, `imgsize`, `imgcrop` |
| poppler | `pdf2txt`, `pdf2img`, `pdfmeta`, `pdfpages` |
| resvg | `svg2png`, `svgscale` |

Dazu: **[Catppuccin Mocha](https://catppuccin.com/) Theme** überall, **Hilfe im Terminal** via `dothelp`, **fzf-Integration** für alles.

Alle installierten Pakete: [`setup/Brewfile`](setup/Brewfile)

## 🚀 Installation

```bash
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/install.sh
```

Bestehende Konfigurationen werden automatisch gesichert. Wiederherstellung: `./setup/restore.sh`

Danach **Terminal neu starten**. Fertig!

> 💡 **Tipp:** Gib `dothelp` ein – zeigt Keybindings, Aliase und Wartungsbefehle.
>
> ⚠️ **Probleme?** `dothealth` prüft die Installation.

### Voraussetzungen

#### macOS (getestet ✅)

- **Apple Silicon oder Intel Mac** (arm64/x86_64)
- **macOS 26+** (Tahoe)
- **Internetverbindung** & Admin-Rechte

#### Linux (vorbereitet 🔧)

- **Fedora / Debian / Arch** – Bootstrap + Plattform-Abstraktionen in Docker/Headless validiert (Desktop/Hardware ausstehend)
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
