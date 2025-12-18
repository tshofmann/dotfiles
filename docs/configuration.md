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
