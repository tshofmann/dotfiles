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
└── .stowrc                     # Stow-Konfiguration (ignoriert macOS Dateimüll)
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
- Konfiguriert Starship-Theme (catppuccin-powerline)
- ✖ Exit bei kritischen Fehlern (Architektur, Xcode, Font)
- ⚠ Warnung bei Profil-Problemen (nicht blockierend)

**Schritt 2: Konfigurationsdateien verlinken**

```zsh
cd ~/dotfiles && stow --no-folding --adopt --restow terminal && git reset --hard HEAD
```

Der Befehl:
- Verhindert Tree-Folding und belässt `~/.config` als echten Ordner (`--no-folding`)
- Übernimmt existierende Dateien ins Repository (`--adopt`)
- Aktualisiert bestehende Symlinks (`--restow`)
- Stellt die Repository-Version wieder her (`git reset`)

| Symlink | Ziel |
|---------|------|
| `~/.zshrc` | `~/dotfiles/terminal/.zshrc` |
| `~/.zprofile` | `~/dotfiles/terminal/.zprofile` |
| `~/.config/alias/homebrew.alias` | `~/dotfiles/terminal/.config/alias/homebrew.alias` |

## ⚙️ Details

**Idempotenz:** Das Skript kann mehrfach hintereinander ausgeführt werden.

**Brewfile:** Deklarative Abhängigkeiten statt `brew install foo bar baz`.

> **Hinweis:** Das Setup verwendet `brew bundle --no-upgrade`. Bestehende, aber defekte Homebrew-Installationen werden dadurch nicht automatisch repariert. Für frische Setups ist dieses Verhalten beabsichtigt. Falls es zu Problemen durch bestehende, aber defekte Formulae kommt:
> - **Option 1:** Homebrew-Zustand prüfen: `brew doctor`
> - **Option 2:** Einzelne Formula reparieren: `brew reinstall <formula>`
> - **Option 3:** Vollständige Reparatur: `brew update && brew upgrade && brew autoremove && brew cleanup`

```ruby
brew "fzf"
brew "gh"
brew "stow"
brew "starship"
brew "zoxide"
cask "font-meslo-lg-nerd-font"
```

**Starship-Theme:** Das Setup generiert automatisch `~/.config/starship.toml` mit dem `catppuccin-powerline` Preset. Die Datei wird standardmäßig nicht versioniert (`.gitignore` + `.stowrc`).

> **Eigene Starship-Konfiguration versionieren:**
> 1. Datei nach `terminal/.config/starship.toml` kopieren
> 2. Eintrag `terminal/.config/starship.toml` aus `.gitignore` entfernen
> 3. Eintrag `--ignore=starship\.toml` aus `.stowrc` entfernen
> 4. Mit `stow --restow terminal` verlinken

## ⌨️ Aliase

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `brewup` | `brew update && brew upgrade && brew autoremove && brew cleanup` | System-Update |

## 📄 Lizenz

[MIT Lizenz](LICENSE)
