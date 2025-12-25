# ⚙️ Konfiguration

Diese Anleitung erklärt, wie du die dotfiles an deine Bedürfnisse anpassen kannst.

---

## Starship-Prompt

Das Setup konfiguriert automatisch [Starship](https://starship.rs/) mit dem `catppuccin-powerline` Preset.

### Standard-Verhalten

| Situation | Verhalten |
|-----------|-----------|
| Keine `starship.toml` vorhanden | Wird mit `catppuccin-powerline` erstellt |
| `starship.toml` bereits vorhanden | Bleibt unverändert |
| `STARSHIP_PRESET` Variable gesetzt | Wird mit diesem Preset erstellt/überschrieben |

### Preset ändern

Du kannst das Preset bei der Installation ändern:

```zsh
# Einmalig mit anderem Preset
STARSHIP_PRESET="tokyo-night" ./setup/bootstrap.sh

# Persistent für mehrere Runs
export STARSHIP_PRESET="pure-preset"
./setup/bootstrap.sh
```

### Verfügbare Presets

```zsh
# Nach Installation lokal auflisten
starship preset --list
```

Oder online: [starship.rs/presets](https://starship.rs/presets/)

### Fallback bei ungültigem Preset

Bei einem ungültigen Preset-Namen zeigt das Skript eine Warnung und verwendet `catppuccin-powerline` als Fallback.

---

## Schriftart wechseln

Das Terminal-Profil, der Nerd Font und das Starship-Preset sind eng gekoppelt. Wenn du die Schriftart ändern möchtest, musst du alle drei Komponenten berücksichtigen.

> **⚠️ Wichtig:** Die Datei `tshofmann.terminal` enthält binäre NSArchiver-Daten. **Niemals direkt editieren** – nur über die Terminal.app GUI ändern und neu exportieren.

### Voraussetzung

Bei Starship-Presets mit Powerline-Symbolen (wie `catppuccin-powerline`) muss die neue Schriftart ein **Nerd Font** sein. Siehe [Tools → Preset-Kompatibilität](tools.md#preset-kompatibilität) für Details.

### Schritt 1: Neuen Nerd Font installieren

```zsh
# Verfügbare Nerd Fonts suchen
brew search nerd-font

# Beispiel: JetBrains Mono installieren
brew install --cask font-jetbrains-mono-nerd-font
```

### Schritt 2: Font in Terminal.app ändern

1. Terminal.app → Einstellungen → Profile → `tshofmann`
2. Tab "Text" → Schrift → "Ändern…"
3. Neuen Nerd Font auswählen (z.B. "JetBrainsMono Nerd Font")
4. Größe anpassen falls nötig

### Schritt 3: Profil exportieren

1. Terminal.app → Einstellungen → Profile → `tshofmann`
2. Rechtsklick auf das Profil → "Exportieren…"
3. Speichern als `~/dotfiles/setup/tshofmann.terminal` (überschreiben)

```zsh
# Änderung committen
cd ~/dotfiles
git add setup/tshofmann.terminal
git commit -m "feat: Terminal-Font auf JetBrains Mono geändert"
```

### Alternative: Preset ohne Nerd Font

Falls du keinen Nerd Font verwenden möchtest:

```zsh
# Preset ohne Nerd Font-Anforderung setzen
starship preset no-nerd-font -o ~/.config/starship.toml
```

Dann kann jede beliebige Monospace-Schriftart verwendet werden.

> 📖 Technische Details: [Architektur → Komponenten-Abhängigkeiten](architecture.md#komponenten-abhängigkeiten)

---

## Eigene Starship-Konfiguration versionieren

Standardmäßig wird `~/.config/starship.toml` **nicht versioniert** (`.gitignore` + `.stowrc`).

Falls du deine eigene Konfiguration im Repository speichern möchtest:

### Schritt 1: Datei kopieren

```zsh
cp ~/.config/starship.toml ~/dotfiles/terminal/.config/starship.toml
```

### Schritt 2: `.gitignore` anpassen

Entferne diese Zeile aus `.gitignore`:

```
terminal/.config/starship.toml
```

### Schritt 3: `.stowrc` anpassen

Entferne diese Zeile aus `.stowrc`:

```
--ignore=starship\.toml
```

### Schritt 4: Stow aktualisieren

```zsh
cd ~/dotfiles
stow -R terminal
git add terminal/.config/starship.toml
git commit -m "feat: eigene Starship-Konfiguration"
```

---

## Aliase erweitern

Eigene Aliase kannst du in `terminal/.config/alias/` hinzufügen.

---

## Tool-Konfigurationen anpassen

Einige Tools nutzen native Konfigurationsdateien für globale Einstellungen:

| Tool | Config-Datei | Beschreibung |
|------|--------------|--------------|
| **fzf** | `~/.config/fzf/config` | Layout, Borders, globale Keybindings |
| **bat** | `~/.config/bat/config` | Theme, Style, Syntax-Mappings |
| **ripgrep** | `~/.config/ripgrep/config` | Smart-case, Zeilennummern, Custom-Types |

### Config-Dateien bearbeiten

```zsh
# Alle Config-Dateien sind verlinkt aus dem dotfiles Repo
bat ~/.config/fzf/config      # fzf-Optionen anzeigen
bat ~/.config/bat/config      # bat-Optionen anzeigen
bat ~/.config/ripgrep/config  # ripgrep-Optionen anzeigen

# Bearbeiten (im Repo)
$EDITOR ~/dotfiles/terminal/.config/fzf/config
```

> 📖 Technische Details: [Architektur → Tool-Konfiguration](architecture.md#tool-konfiguration)

---

### Verfügbare Alias-Dateien

| Datei | Beschreibung | Dokumentation |
|-------|--------------|---------------|
| `homebrew.alias` | Homebrew-Wartungsbefehle | [Tools → Aliase](tools.md#homebrewalias) |
| `eza.alias` | Moderne ls-Ersetzungen mit Icons | [Tools → Aliase](tools.md#ezaalias) |
| `bat.alias` | cat mit Syntax-Highlighting | [Tools → Aliase](tools.md#batalias) |
| `ripgrep.alias` | Schnelle Textsuche | [Tools → Aliase](tools.md#ripgrepalias) |
| `fd.alias` | Dateisuche | [Tools → Aliase](tools.md#fdalias) |
| `fzf.alias` | Tool-Kombinationen (20+ Funktionen) | [Tools → Aliase](tools.md#fzfalias--tool-kombinationen) |
| `btop.alias` | Prozess-Monitor | [Tools → Aliase](tools.md#btopalias) |

### Neue Alias-Datei erstellen

```zsh
# Datei erstellen
cat > ~/dotfiles/terminal/.config/alias/custom.alias << 'EOF'
# ============================================================
# custom.alias - Eigene Aliase
# ============================================================
# Zweck   : Persönliche Aliase
# Pfad    : ~/.config/alias/custom.alias
# Docs    : https://github.com/tshofmann/dotfiles
# ============================================================

alias ..='cd ..'
alias ...='cd ../..'
EOF
```

> **Hinweis:** Der frühere `ll`-Alias wird jetzt durch `eza.alias` bereitgestellt (`ll='eza -l --icons=auto --group-directories-first --header'`).

### Stow aktualisieren

```zsh
cd ~/dotfiles
stow -R terminal
```

Die `.zshrc` lädt automatisch alle `*.alias` Dateien aus `~/.config/alias/`.

---

## Shell-History

Die History-Konfiguration in `.zshrc` speichert Kommandos dauerhaft und intelligent.

### macOS zsh_sessions deaktiviert

macOS Terminal.app speichert standardmäßig eine separate History pro Tab/Fenster in `~/.zsh_sessions/`. Dies wird durch die Umgebungsvariable `SHELL_SESSIONS_DISABLE=1` in `~/.zshenv` deaktiviert.

**Warum `.zshenv`?**

Die Variable muss in `.zshenv` gesetzt werden, da macOS `/etc/zshrc_Apple_Terminal` **vor** `.zprofile` und `.zshrc` lädt. Nur `.zshenv` wird früh genug gelesen.

> **Hinweis:** Eine leere Datei `~/.zsh_sessions_disable` hat **keine Wirkung** – das ist ein verbreiteter Irrtum.

**Gründe für die Deaktivierung:**
- Konsistenz: Eine zentrale `~/.zsh_history` statt fragmentierter Session-Dateien
- Kompatibilität: Bessere Integration mit `fzf` History-Suche (`Ctrl+R`)
- Wartbarkeit: History-Optionen in `.zshrc` wirken auf alle Befehle

> **Hinweis:** Bestehende Dateien in `~/.zsh_sessions/` können manuell gelöscht werden: `rm -rf ~/.zsh_sessions/`

### Einstellungen

| Variable | Wert | Beschreibung |
|----------|------|--------------|
| `HISTFILE` | `~/.zsh_history` | Speicherort der History-Datei |
| `HISTSIZE` | 25000 | Einträge im Speicher |
| `SAVEHIST` | 25000 | Einträge in Datei |

### Optionen

| Option | Beschreibung |
|--------|--------------|
| `EXTENDED_HISTORY` | Speichert Timestamp und Dauer |
| `INC_APPEND_HISTORY` | Sofort schreiben (nicht erst bei Exit) |
| `HIST_IGNORE_SPACE` | Befehle mit führendem Leerzeichen ignorieren |
| `HIST_IGNORE_DUPS` | Aufeinanderfolgende Duplikate ignorieren |
| `HIST_REDUCE_BLANKS` | Überflüssige Leerzeichen entfernen |
| `HIST_SAVE_NO_DUPS` | Keine Duplikate in Datei speichern |

### Privacy-Tipp

Befehle mit sensiblen Daten (Passwörter, Tokens) kannst du von der History ausschließen:

```zsh
# Leerzeichen am Anfang = wird nicht gespeichert
 export API_KEY="geheim"
```

### History durchsuchen

| Methode | Tastenkombination |
|---------|-------------------|
| fzf Fuzzy Search | `Ctrl+R` |
| Zsh-Suche rückwärts | `Ctrl+R` (ohne fzf) |
| Zsh-Suche vorwärts | `Ctrl+S` |

---

## Weiterführende Links

- [Starship Dokumentation](https://starship.rs/config/)
- [Starship Presets](https://starship.rs/presets/)
- [Architektur](architecture.md) – Wie das Setup funktioniert
- [Tools](tools.md) – Installierte CLI-Tools

---

[← Zurück zur Übersicht](../README.md)
