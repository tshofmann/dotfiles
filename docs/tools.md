# 🛠️ Tools

Übersicht aller installierten CLI-Tools und verfügbaren Aliase.

---

## Installierte CLI-Tools

Diese Tools werden via Brewfile installiert:

| Tool | Beschreibung | Dokumentation |
|------|--------------|---------------|
| **bat** | `cat` mit Syntax-Highlighting und Git-Integration | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| **eza** | Moderner `ls`-Ersatz mit Icons und Git-Status | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| **fzf** | Fuzzy Finder für Kommandozeile und Dateien | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| **gh** | GitHub CLI – Issues, PRs, Repos von der Kommandozeile | [cli.github.com](https://cli.github.com/) |
| **ripgrep** | Ultraschneller `grep`-Ersatz (respektiert `.gitignore`) | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **starship** | Schneller, anpassbarer Shell-Prompt | [starship.rs](https://starship.rs/) |
| **stow** | GNU Stow – Symlink-Manager für Dotfiles | [gnu.org/software/stow](https://www.gnu.org/software/stow/) |
| **zoxide** | Smarter `cd`-Ersatz – merkt sich häufige Verzeichnisse | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |

---

## Aliase

Verfügbare Aliase aus `~/.config/alias/`:

### homebrew.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `brewup` | `brew update && brew upgrade && brew autoremove && brew cleanup` | Vollständiges Homebrew-Update |

### eza.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ls` | `eza --icons` | ls-Ersatz mit Icons |
| `ll` | `eza -la --icons --git` | Ausführliche Auflistung mit Git-Status |
| `ld` | `eza -lD --icons` | Nur Verzeichnisse anzeigen |
| `lt` | `eza --tree --level=2 --icons` | Baumansicht (2 Ebenen) |
| `lt3` | `eza --tree --level=3 --icons` | Baumansicht (3 Ebenen) |
| `lm` | `eza -la --icons --sort=modified` | Sortiert nach Änderungsdatum |
| `lS` | `eza -la --icons --sort=size --reverse` | Sortiert nach Größe |

> **Hinweis:** eza erfordert eine Nerd Font für korrekte Icon-Darstellung.

### bat.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `cat` | `bat` | cat-Ersatz mit Syntax-Highlighting |
| `catp` | `bat --plain` | Ohne Zeilennummern/Header (für Pipes) |
| `catn` | `bat --style=numbers` | Nur Zeilennummern |
| `catd` | `bat --diff` | Mit Git-Diff-Highlighting |
| `bat-themes` | `bat --list-themes` | Verfügbare Themes auflisten |
| `bat-langs` | `bat --list-languages` | Verfügbare Sprachen auflisten |

### ripgrep.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `rgc` | `rg -C 3` | Suche mit Kontext (3 Zeilen) |
| `rgf` | `rg --files \| rg` | Suche nur Dateinamen |
| `rga` | `rg --no-ignore --hidden` | Suche alle Dateien |
| `rgi` | `rg -i` | Case-insensitive Suche |
| `rgn` | `rg -n` | Suche mit Zeilennummern |
| `rgts` | `rg --type ts --type js` | Nur TypeScript/JavaScript |
| `rgpy` | `rg --type py` | Nur Python |
| `rgmd` | `rg --type md` | Nur Markdown |
| `rgsh` | `rg --type sh` | Nur Shell-Skripte |

### Verwendung

```zsh
# System aktualisieren
brewup

# Was wird aktualisiert? (Vorschau)
brew outdated
```

---

## Tool-Nutzung

### eza – Moderner ls-Ersatz

```zsh
# Dateien mit Icons und Details auflisten
eza -la --icons

# Baumstruktur anzeigen (2 Ebenen)
eza --tree --level=2 --icons

# Git-Status der Dateien anzeigen
eza --git --long

# Mit Aliassen (nach Installation):
ll                 # Ausführliche Liste mit Git-Status
lt                 # Baumansicht
```

> **Hinweis:** Erfordert eine Nerd Font für korrekte Icon-Darstellung.

---

### bat – cat mit Syntax-Highlighting

```zsh
# Datei mit Syntax-Highlighting anzeigen
bat README.md

# Nur Plain-Text ausgeben (für Pipes)
bat --plain file.txt

# Git-Diff hervorheben
git diff | bat

# Theme temporär wechseln
bat --theme="Dracula" file.py
```

---

### ripgrep (rg) – Schnelle Textsuche

```zsh
# Text rekursiv suchen
rg "TODO"

# Nur in bestimmten Dateitypen suchen
rg "function" --type ts

# Mit Kontext (3 Zeilen vor/nach Treffer)
rg "error" -C 3

# Alle Dateien durchsuchen (ignoriert .gitignore nicht)
rg --no-ignore --hidden "password"
```

---

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

### Preset-Kompatibilität

| Preset | Nerd Font erforderlich? | Beschreibung |
|--------|------------------------|---------------|
| `catppuccin-powerline` | ✅ Ja | Standard-Preset dieses Setups |
| `gruvbox-rainbow` | ✅ Ja | Retro-Farbschema mit Icons |
| `tokyo-night` | ✅ Ja | Dunkles Theme mit Powerline |
| `no-nerd-font` | ❌ Nein | Für Terminals ohne Nerd Font |
| `plain-text-symbols` | ❌ Nein | ASCII-only, keine Spezialzeichen |

> 📖 Vollständige Liste: [starship.rs/presets](https://starship.rs/presets/)
>
> ⚠️ Bei Presets mit Nerd Font-Anforderung müssen Font und Terminal-Profil korrekt konfiguriert sein. Siehe [Architektur → Komponenten-Abhängigkeiten](architecture.md#komponenten-abhängigkeiten).

---

## Font

### MesloLG Nerd Font

| Eigenschaft | Wert |
|-------------|------|
| **Name** | MesloLGLDZ Nerd Font (Dotted Zero Variante) |
| **Installiert via** | `brew install --cask font-meslo-lg-nerd-font` |
| **Speicherort** | `~/Library/Fonts/` |
| **Zweck** | Icons und Powerline-Symbole im Terminal |

> **Hinweis:** MesloLG gibt es in mehreren Varianten: `NFM` (Mono), `NF`, `NFP` (Propo). Das Terminal-Profil verwendet die `LDZNF`-Variante (L = Large, DZ = Dotted Zero).

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

# Installieren (HOMEBREW_BUNDLE_FILE ist in .zprofile gesetzt)
brew bundle
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
