# 🍎 dotfiles

> macOS Setup für Apple Silicon (arm64) mit automatisierten Installation und Konfiguration.

## 📁 Struktur

```
dotfiles/
├── setup/
│   ├── terminal_macos.sh       # Automatisiertes Setup (Basis)
│   ├── Brewfile                # Homebrew Abhängigkeiten
│   └── tshofmann.terminal      # Terminal.app Profil
├── terminal/
│   ├── .zprofile               # Login-Shell
│   ├── .zshrc                  # Interactive Shell
│   └── .config/alias/
│       └── homebrew.alias      # Homebrew Aliase
└── .stowrc                      # Stow-Konfiguration (ignoriert macOS Dateimüll)
```

## 🚀 Installation

**Schritt 1: Setup ausführen**

```zsh
git clone https://github.com/tshofmann/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup/terminal_macos.sh
```

Das Skript:
- Prüft arm64 Architektur (Exit wenn Intel)
- Installiert/prüft Xcode CLI Tools
- Installiert/prüft Homebrew
- Installiert CLI-Tools via Brewfile (fzf, gh, stow, starship, zoxide)
- Installiert MesloLG Nerd Font
- Importiert & setzt Terminal.app Profil als Standard
- ✖ Exit bei kritischen Fehlern (Architektur, Xcode, Font)
- ⚠ Warnung bei Profil-Problemen (nicht blockierend)

**Schritt 2: Konfigurationsdateien verlinken**

```zsh
cd ~/dotfiles
stow --restow terminal
```

Das erstellt Symlinks ins Home-Verzeichnis:

| Symlink | Ziel |
|---------|------|
| `~/.zshrc` | `~/dotfiles/terminal/.zshrc` |
| `~/.zprofile` | `~/dotfiles/terminal/.zprofile` |
| `~/.config/alias/homebrew.alias` | `~/dotfiles/terminal/.config/alias/homebrew.alias` |

**`--restow`:** Wenn Dateien bereits existieren, werden sie durch Symlinks ersetzt. Stow garantiert, dass die Version aus dem Repository verwendet wird (nicht lokale Änderungen).

**macOS Dateien:** Projekt-spezifische `.stowrc` im Root ignoriert macOS-Dateimüll (`.DS_Store`, `._*`, `.localized`).

## ⚙️ Details

**Idempotenz:** Das Skript kann mehrfach hintereinander ausgeführt werden.

**Brewfile:** Deklarative Abhängigkeiten statt `brew install foo bar baz`.

```ruby
brew "fzf"
brew "gh"
brew "stow"
brew "starship"
brew "zoxide"
cask "font-meslo-lg-nerd-font"
```

## ⌨️ Aliase

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `brewup` | `brew update && brew upgrade && brew autoremove && brew cleanup` | System-Update |

## 📄 Lizenz

[MIT Lizenz](LICENSE)
