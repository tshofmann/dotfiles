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

alias ll='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
EOF
```

### Stow aktualisieren

```zsh
cd ~/dotfiles
stow -R terminal
```

Die `.zshrc` lädt automatisch alle `*.alias` Dateien aus `~/.config/alias/`.

---

## Weiterführende Links

- [Starship Dokumentation](https://starship.rs/config/)
- [Starship Presets](https://starship.rs/presets/)
- [Architektur](architecture.md) – Wie das Setup funktioniert
- [Tools](tools.md) – Installierte CLI-Tools

---

[← Zurück zur Übersicht](../README.md)
