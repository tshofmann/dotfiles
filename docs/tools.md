# 🛠️ Tools

Übersicht aller installierten CLI-Tools und verfügbaren Aliase.

---

## Installierte CLI-Tools

Diese Tools werden via Brewfile installiert:

| Tool | Beschreibung | Dokumentation |
|------|--------------|---------------|
| **fzf** | Fuzzy Finder für Kommandozeile und Dateien | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| **gh** | GitHub CLI – Issues, PRs, Repos von der Kommandozeile | [cli.github.com](https://cli.github.com/) |
| **stow** | GNU Stow – Symlink-Manager für Dotfiles | [gnu.org/software/stow](https://www.gnu.org/software/stow/) |
| **starship** | Schneller, anpassbarer Shell-Prompt | [starship.rs](https://starship.rs/) |
| **zoxide** | Smarter `cd`-Ersatz – merkt sich häufige Verzeichnisse | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |

---

## Aliase

Verfügbare Aliase aus `~/.config/alias/`:

### homebrew.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `brewup` | `brew update && brew upgrade && brew autoremove && brew cleanup` | Vollständiges Homebrew-Update |

### Verwendung

```zsh
# System aktualisieren
brewup

# Was wird aktualisiert? (Vorschau)
brew outdated
```

---

## Tool-Nutzung

### fzf – Fuzzy Finder

```zsh
# Datei suchen und öffnen
vim $(fzf)

# History durchsuchen (Ctrl+R)
# Verzeichnis wechseln (Ctrl+T in manchen Setups)

# In Pipe verwenden
cat file.txt | fzf
```

### gh – GitHub CLI

```zsh
# Authentifizieren (einmalig)
gh auth login

# Repository klonen
gh repo clone owner/repo

# Issue erstellen
gh issue create

# Pull Request erstellen
gh pr create

# Status prüfen
gh pr status
```

### zoxide – Smarter cd

```zsh
# Verzeichnis wechseln (lernt mit der Zeit)
z dotfiles         # Springt zu ~/dotfiles
z doc              # Springt zu häufig besuchtem Verzeichnis mit "doc"

# Interaktive Auswahl
zi                 # Zeigt Liste der bekannten Verzeichnisse
```

### starship – Shell Prompt

Starship läuft automatisch. Konfiguration erfolgt über `~/.config/starship.toml`.

```zsh
# Preset wechseln
starship preset tokyo-night -o ~/.config/starship.toml

# Verfügbare Presets
starship preset --list

# Config editieren
$EDITOR ~/.config/starship.toml
```

---

## Font

### MesloLGS Nerd Font

| Eigenschaft | Wert |
|-------------|------|
| **Name** | MesloLGS Nerd Font |
| **Installiert via** | `brew install --cask font-meslo-lg-nerd-font` |
| **Speicherort** | `~/Library/Fonts/` |
| **Zweck** | Icons und Powerline-Symbole im Terminal |

### Warum Nerd Fonts?

Nerd Fonts sind gepatchte Schriftarten mit zusätzlichen Glyphen:

- **Powerline-Symbole** – für Prompt-Segmente
- **Devicons** – Sprach- und Framework-Icons
- **Font Awesome** – Allgemeine Icons
- **Octicons** – GitHub-Icons

Diese werden von Starship und anderen modernen CLI-Tools verwendet.

### Alternative Fonts

Falls MesloLG nicht gefällt, andere Nerd Fonts installieren:

```zsh
# Suche verfügbare Nerd Fonts
brew search nerd-font

# Beispiele
brew install --cask font-fira-code-nerd-font
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-hack-nerd-font
```

> **Hinweis:** Nach Font-Änderung muss das Terminal-Profil angepasst werden:
> Terminal.app → Einstellungen → Profile → Text → Schrift ändern

---

## Eigene Tools hinzufügen

### Brewfile erweitern

```zsh
# Brewfile editieren
$EDITOR ~/dotfiles/setup/Brewfile

# Beispiel: bat (besseres cat) hinzufügen
echo 'brew "bat"' >> ~/dotfiles/setup/Brewfile

# Installieren
brew bundle --file=~/dotfiles/setup/Brewfile
```

### Eigene Aliase

Siehe [Konfiguration → Aliase erweitern](configuration.md#aliase-erweitern).

---

## Weiterführende Links

- [Homebrew Formulae](https://formulae.brew.sh/)
- [Nerd Fonts](https://www.nerdfonts.com/)
- [Starship Presets](https://starship.rs/presets/)

---

[← Zurück zur Übersicht](../README.md)
