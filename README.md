# 🍎 dotfiles

> Meine persönlichen **Konfigurationsdateien** für ein macOS Setup auf einem MacBook Pro mit Apple Silicon.

## 📋 Übersicht

Dieses Repository enthält Konfigurationsdateien und Setup-Skripte für eine konsistente Entwicklungsumgebung auf macOS.

## 📁 Struktur

```
dotfiles/
├── setup/                      # Installations- und Setup-Skripte
│   ├── terminal_macos.sh       # Terminal.app Setup (Font + Profil)
│   └── tshofmann.terminal      # Terminal.app Profil-Export
│
└── terminal/                   # Terminal-Konfigurationsdateien
    ├── .zprofile               # Login-Shell Umgebungsvariablen
    ├── .zshrc                  # Interaktive Shell-Konfiguration
    └── .config/
        └── alias/
            └── homebrew.alias  # Homebrew Aliase
```

## �️ Voraussetzungen

Die Konfiguration basiert auf folgenden Tools:

| Tool | Beschreibung |
|------|-------------|
| [Homebrew](https://brew.sh) | Paketmanager für macOS |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy Finder |
| [gh](https://cli.github.com) | GitHub CLI |
| [GNU Stow](https://www.gnu.org/software/stow/) | Symlink-Manager für Dotfiles |
| [Starship](https://starship.rs) | Anpassbarer Shell-Prompt |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smartes `cd` mit Frecency |

## 🚀 Installation

### 1. Terminal Setup

Das Terminal-Setup installiert den Font und das Terminal-Profil:

```zsh
./setup/terminal_macos.sh
```

Dieses Skript:
- Installiert **Homebrew** (falls nicht vorhanden)
- Installiert **CLI-Tools**: fzf, gh, stow, starship, zoxide
- Installiert **MesloLG Nerd Font** für Symbole und Icons
- Importiert das **Terminal.app Profil** mit vorkonfiguriertem Theme

### 2. Konfigurationsdateien verlinken

Die Konfigurationsdateien werden mit [GNU Stow](https://www.gnu.org/software/stow/) ins Home-Verzeichnis verlinkt:

```zsh
cd ~/dotfiles
stow terminal
```

#### Wie funktioniert Stow?

Stow erstellt Symlinks vom Home-Verzeichnis (`~`) zu den Dateien im Repository. Der Befehl `stow terminal` erzeugt folgende Verlinkungen:

| Symlink | Ziel |
|---------|------|
| `~/.zshrc` | `~/dotfiles/terminal/.zshrc` |
| `~/.zprofile` | `~/dotfiles/terminal/.zprofile` |
| `~/.config/alias/` | `~/dotfiles/terminal/.config/alias/` |

So kannst du alle Konfigurationen zentral in einem Git-Repository verwalten, während macOS sie an den erwarteten Orten findet.

## ⌨️ Aliase

### Homebrew

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `brewup` | `brew update && brew upgrade; brew autoremove; brew cleanup` | Vollständiges System-Update |

## 📄 Lizenz

Dieses Projekt steht unter der [MIT Lizenz](LICENSE).

---

*Made with ☕ on macOS*