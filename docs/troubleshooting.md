# 🔧 Troubleshooting

Lösungen für häufige Probleme bei der Installation und Nutzung der dotfiles.

---

## Font-Probleme

### Symptom

- Icons werden als Fragezeichen oder Kästchen angezeigt
- Terminal-Prompt sieht "kaputt" aus
- Powerline-Symbole fehlen

### Ursache

Dieses Problem entsteht durch die Abhängigkeitskette zwischen drei Komponenten:

1. **Starship-Preset** (`catppuccin-powerline`) verwendet Nerd Font-Glyphen wie ``, ``, `󰀵`
2. **Nerd Font** (MesloLG) muss installiert sein, um diese Glyphen darzustellen
3. **Terminal-Profil** muss den Nerd Font als Schriftart verwenden

Wenn eine dieser Komponenten fehlt oder falsch konfiguriert ist, werden Icons als □ oder ? angezeigt.

> 📖 Technische Details: [Architektur → Komponenten-Abhängigkeiten](architecture.md#komponenten-abhängigkeiten)

### Diagnose

```zsh
# Prüfen ob MesloLG Nerd Font installiert ist
ls ~/Library/Fonts/MesloLG*NerdFont*
```

**Erwartete Ausgabe:** Mehrere `.ttf` Dateien

### Lösung

```zsh
# Font neu installieren
brew reinstall font-meslo-lg-nerd-font

# Terminal.app neustarten
```

Falls das Problem weiterhin besteht:

1. Terminal.app → Einstellungen → Profile → `tshofmann`
2. Tab "Text" → Schrift ändern → "MesloLGLDZ Nerd Font" auswählen (oder andere installierte Nerd Font-Variante)

---

## Terminal-Profil nicht importiert

### Symptom

- Profil `tshofmann` erscheint nicht in Terminal.app
- Terminal hat weiterhin Standard-Erscheinung

### Diagnose

Terminal.app → Einstellungen → Profile → Liste prüfen

### Lösung

**Schritt 1:** Terminal.app komplett beenden

```zsh
osascript -e 'quit app "Terminal"'
```

**Schritt 2:** Profil manuell importieren

```zsh
open ~/dotfiles/setup/tshofmann.terminal
```

**Schritt 3:** Als Standard setzen

1. Terminal.app → Einstellungen → Profile
2. `tshofmann` auswählen
3. "Standard" Button klicken

---

## Symlinks funktionieren nicht

### Symptom

- Konfiguration wird nicht geladen
- `~/.zshrc` ist eine Datei statt Symlink
- Änderungen in `~/dotfiles/terminal/` haben keine Auswirkung

### Diagnose

```zsh
# Symlink-Status prüfen
ls -la ~/.zshrc ~/.zprofile

# Erwartete Ausgabe:
# lrwxr-xr-x  ... .zshrc -> dotfiles/terminal/.zshrc
```

Falls keine Symlinks (`->`) angezeigt werden, sind es normale Dateien.

### Lösung

```zsh
# Stow mit Verbose-Output wiederholen
cd ~/dotfiles
stow -vvR terminal
```

Bei Konflikten:

```zsh
# Existierende Dateien ins Repo übernehmen und Repository-Version wiederherstellen
stow --adopt -R terminal && git reset --hard HEAD
```

> ⚠️ **Achtung:** `git reset --hard` verwirft lokale Änderungen! Siehe [Installation](installation.md#eigene-änderungen-sichern).

---

## Homebrew-Probleme

### Symptom

- `brew` Befehl nicht gefunden
- Formulae installieren nicht korrekt
- Fehlermeldungen bei `brew bundle`

### Diagnose

```zsh
# Homebrew-Zustand prüfen
brew doctor
```

### Lösungen

**Problem:** `brew` nicht gefunden

```zsh
# Homebrew-Pfad manuell laden
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Problem:** Einzelne Formula defekt

```zsh
brew reinstall <formula>
```

**Problem:** Generelle Homebrew-Probleme

```zsh
# Vollständige Reparatur
brew update && brew upgrade && brew autoremove && brew cleanup
```

**Problem:** Brewfile-Installation schlägt fehl

```zsh
# Ohne Auto-Update installieren
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle

# Status prüfen
brew bundle check
```

> **Hinweis:** `brew bundle` verwendet automatisch `~/dotfiles/setup/Brewfile` durch die Umgebungsvariable `HOMEBREW_BUNDLE_FILE` (gesetzt in `.zprofile`).

---

## Starship startet nicht

### Symptom

- Prompt ist Standard-ZSH statt Starship
- Keine Icons im Prompt

### Diagnose

```zsh
# Prüfen ob Starship installiert ist
command -v starship

# Prüfen ob Starship in .zshrc initialisiert wird
grep starship ~/.zshrc
```

### Lösung

```zsh
# Starship neu installieren
brew reinstall starship

# Shell neu laden
source ~/.zshrc
```

Falls `starship.toml` fehlt oder defekt ist:

```zsh
# Neue Config generieren
starship preset catppuccin-powerline -o ~/.config/starship.toml
```

---

## Bootstrap-Skript bricht ab

### Symptom: "Dieses Setup unterstützt nur Apple Silicon"

**Ursache:** Du verwendest einen Intel-Mac.

**Lösung:** Dieses Repository ist nur für Apple Silicon (arm64) konzipiert. Für Intel-Macs müsste das Setup angepasst werden.

### Symptom: "Xcode CLI Tools Installation abgebrochen"

**Ursache:** Installation wurde im Dialog abgebrochen oder ist fehlgeschlagen.

**Lösung:**

```zsh
# Manuell installieren
xcode-select --install
```

### Symptom: "Font konnte nicht verifiziert werden"

**Ursache:** Font-Installation fehlgeschlagen.

**Lösung:**

```zsh
# Font manuell installieren
brew install --cask font-meslo-lg-nerd-font

# Prüfen
ls ~/Library/Fonts/MesloLG*
```

---

## Dotfiles deinstallieren

Falls du die dotfiles entfernen möchtest:

### Schritt 1: Symlinks entfernen

```zsh
cd ~/dotfiles
stow -D terminal
```

### Schritt 2: Eigene Konfigurationsdateien wiederherstellen (optional)

Nach dem Entfernen der Symlinks existieren `~/.zshrc` und `~/.zprofile` nicht mehr. Du kannst eigene Dateien anlegen oder das macOS-Standard-Setup nutzen.

### Schritt 3: Homebrew-Pakete entfernen (optional)

```zsh
brew uninstall fzf gh starship zoxide stow
brew uninstall --cask font-meslo-lg-nerd-font
```

### Schritt 4: Repository löschen (optional)

```zsh
rm -rf ~/dotfiles
```

> **Hinweis:** Homebrew selbst wird durch diese Schritte nicht entfernt. Falls gewünscht, siehe [Homebrew Uninstallation](https://github.com/Homebrew/install#uninstall-homebrew).

---

## Weitere Hilfe

Falls dein Problem hier nicht aufgeführt ist:

1. [Issue erstellen](https://github.com/tshofmann/dotfiles/issues/new)
2. Fehlermeldung und Ausgabe von `brew doctor` beifügen
3. macOS-Version und Chip (M1, M2, …) angeben

---

[← Zurück zur Übersicht](../README.md)
