# ⚙️ Konfiguration

Diese Anleitung erklärt, wie du die dotfiles an deine Bedürfnisse anpassen kannst.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen direkt in den Config-Dateien vornehmen.

---

## Catppuccin Mocha Theme

Das gesamte Setup verwendet [Catppuccin Mocha](https://catppuccin.com/) als einheitliches Farbschema. Dies gewährleistet ein konsistentes Erscheinungsbild über alle Tools hinweg.

### Konfigurierte Tools

| Tool | Theme-Datei | Status |
|------|-------------|--------|
| **Terminal.app** | `setup/catppuccin-mocha.terminal` | Via Bootstrap importiert |
| **Starship** | catppuccin-powerline Preset | Via Bootstrap konfiguriert |
| **bat** | `terminal/.config/bat/themes/` | Via Stow verlinkt (+ Cache-Build) |
| **fzf** | `terminal/.config/fzf/config` | Farben in Config-Datei (via Stow) |
| **btop** | `terminal/.config/btop/themes/` | Via Stow verlinkt |
| **eza** | `terminal/.config/eza/theme.yml` | Via Stow verlinkt |
| **zsh-syntax-highlighting** | `terminal/.config/zsh/` | Via Stow verlinkt |


### Farbpalette (Referenz)

Die wichtigsten Farben der Catppuccin Mocha Palette:

| Farbe | Hex | Verwendung |
|-------|-----|------------|
| Base | `#1E1E2E` | Hintergrund |
| Text | `#CDD6F4` | Haupttext |
| Subtext0 | `#A6ADC8` | Beschreibungen |
| Surface0 | `#313244` | Selection Background |
| Surface1 | `#45475A` | Selected Background |
| Overlay0 | `#6C7086` | Borders |
| Red | `#F38BA8` | Fehler, Highlights |
| Green | `#A6E3A1` | Erfolg, Befehle |
| Yellow | `#F9E2AF` | Warnungen |
| Blue | `#89B4FA` | Info, Links |
| Mauve | `#CBA6F7` | Akzente, Prompt |

Vollständige Palette: [catppuccin.com/palette](https://catppuccin.com/palette)

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

<a name="schriftart-wechseln"></a>

## Schriftart wechseln

Das Terminal-Profil, der Nerd Font und das Starship-Preset sind eng gekoppelt. Wenn du die Schriftart ändern möchtest, musst du alle drei Komponenten berücksichtigen.

> **⚠️ Wichtig:** Die Datei `catppuccin-mocha.terminal` enthält binäre NSArchiver-Daten. **Niemals direkt editieren** – nur über die Terminal.app GUI ändern und neu exportieren.

### Voraussetzung

Bei Starship-Presets mit Powerline-Symbolen (wie `catppuccin-powerline`) muss die neue Schriftart ein **Nerd Font** sein. Siehe [Tools → Preset-Kompatibilität](tools.md#preset-kompatibilität) für Details.

### Schritt 1: Neuen Nerd Font installieren

```zsh
# Verfügbare Nerd Fonts suchen
brew search nerd-font

# Beispiel: FiraCode Nerd Font installieren
brew install --cask font-fira-code-nerd-font
```

### Schritt 2: Terminal.app Profil anpassen

1. Terminal.app öffnen
2. `Terminal → Einstellungen → Profile → catppuccin-mocha`
3. Tab "Text" → "Schrift" → "Ändern…"
4. Neuen Nerd Font auswählen (z.B. "FiraCode Nerd Font Mono")
5. Größe anpassen (empfohlen: 13-14pt)
6. Profil exportieren: `Einstellungen → Profile → Zahnrad → "...exportieren"`

### Schritt 3: Exportiertes Profil ins Repository

```zsh
# Altes Profil ersetzen
mv ~/Downloads/catppuccin-mocha.terminal ~/dotfiles/setup/

# Änderung committen
cd ~/dotfiles
git add setup/catppuccin-mocha.terminal
git commit -m "Terminal-Profil: FiraCode Nerd Font"
```

---

## Aliase anpassen

### Eigene Aliase hinzufügen

Erstelle eine neue Datei in `terminal/.config/alias/`:

```zsh
# terminal/.config/alias/custom.alias

# Guard: Diese Datei hat keine Tool-Abhängigkeit
# Wird immer geladen

# Meine Shortcuts
alias projects='cd ~/Projects'
alias dotfiles='cd ~/dotfiles'
```

### Bestehende Aliase überschreiben

Aliase werden in alphabetischer Reihenfolge geladen. Um einen bestehenden Alias zu überschreiben, erstelle eine Datei die **nach** der Original-Datei geladen wird:

```zsh
# terminal/.config/alias/zzz-overrides.alias

# ls ohne Icons (falls eza-Icons stören)
alias ls='eza --no-icons'
```

---

## fzf anpassen

### Globale Optionen

Die fzf-Konfiguration liegt in `terminal/.config/fzf/config`:

```zsh
# Catppuccin Mocha Farben (bereits konfiguriert)
--color=bg+:#313244,bg:#1e1e2e,...

# Layout
--height=~50%
--layout=reverse
--border=rounded
```

### Keybindings ändern

Shell-Keybindings für fzf werden in `terminal/.config/fzf/init.zsh` definiert:

```zsh
# Ctrl+X Prefix für dotfiles-Keybindings
bindkey '^X1' fzf-history-widget
bindkey '^X2' fzf-file-widget
bindkey '^X3' fzf-cd-widget
```

---

## Weitere Anpassungen

| Was | Wo | Format |
|-----|-----|--------|
| bat Theme | `~/.config/bat/config` | `--theme="..."` |
| fd Ignore-Patterns | `~/.config/fd/ignore` | Glob-Patterns |
| ripgrep Optionen | `~/.config/ripgrep/config` | CLI-Flags |
| lazygit Keybindings | `~/.config/lazygit/config.yml` | YAML |
| fastfetch Modules | `~/.config/fastfetch/config.jsonc` | JSONC |

# ⚙️ Konfiguration

Diese Anleitung erklärt, wie du die dotfiles an deine Bedürfnisse anpassen kannst.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen direkt in den Config-Dateien vornehmen.

---

## Catppuccin Mocha Theme

Das gesamte Setup verwendet [Catppuccin Mocha](https://catppuccin.com/) als einheitliches Farbschema. Dies gewährleistet ein konsistentes Erscheinungsbild über alle Tools hinweg.

### Konfigurierte Tools

| Tool | Theme-Datei | Status |
|------|-------------|--------|
| **Terminal.app** | `setup/catppuccin-mocha.terminal` | Via Bootstrap importiert |
| **Starship** | catppuccin-powerline Preset | Via Bootstrap konfiguriert |
| **bat** | `terminal/.config/bat/themes/` | Via Stow verlinkt (+ Cache-Build) |
| **fzf** | `terminal/.config/fzf/config` | Farben in Config-Datei (via Stow) |
| **btop** | `terminal/.config/btop/themes/` | Via Stow verlinkt |
| **eza** | `terminal/.config/eza/theme.yml` | Via Stow verlinkt |
| **zsh-syntax-highlighting** | `terminal/.config/zsh/` | Via Stow verlinkt |


### Farbpalette (Referenz)

Die wichtigsten Farben der Catppuccin Mocha Palette:

| Farbe | Hex | Verwendung |
|-------|-----|------------|
| Base | `#1E1E2E` | Hintergrund |
| Text | `#CDD6F4` | Haupttext |
| Subtext0 | `#A6ADC8` | Beschreibungen |
| Surface0 | `#313244` | Selection Background |
| Surface1 | `#45475A` | Selected Background |
| Overlay0 | `#6C7086` | Borders |
| Red | `#F38BA8` | Fehler, Highlights |
| Green | `#A6E3A1` | Erfolg, Befehle |
| Yellow | `#F9E2AF` | Warnungen |
| Blue | `#89B4FA` | Info, Links |
| Mauve | `#CBA6F7` | Akzente, Prompt |

Vollständige Palette: [catppuccin.com/palette](https://catppuccin.com/palette)

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

<a name="schriftart-wechseln"></a>

## Schriftart wechseln

Das Terminal-Profil, der Nerd Font und das Starship-Preset sind eng gekoppelt. Wenn du die Schriftart ändern möchtest, musst du alle drei Komponenten berücksichtigen.

> **⚠️ Wichtig:** Die Datei `catppuccin-mocha.terminal` enthält binäre NSArchiver-Daten. **Niemals direkt editieren** – nur über die Terminal.app GUI ändern und neu exportieren.

### Voraussetzung

Bei Starship-Presets mit Powerline-Symbolen (wie `catppuccin-powerline`) muss die neue Schriftart ein **Nerd Font** sein. Siehe [Tools → Preset-Kompatibilität](tools.md#preset-kompatibilität) für Details.

### Schritt 1: Neuen Nerd Font installieren

```zsh
# Verfügbare Nerd Fonts suchen
brew search nerd-font

# Beispiel: FiraCode Nerd Font installieren
brew install --cask font-fira-code-nerd-font
```

### Schritt 2: Terminal.app Profil anpassen

1. Terminal.app öffnen
2. `Terminal → Einstellungen → Profile → catppuccin-mocha`
3. Tab "Text" → "Schrift" → "Ändern…"
4. Neuen Nerd Font auswählen (z.B. "FiraCode Nerd Font Mono")
5. Größe anpassen (empfohlen: 13-14pt)
6. Profil exportieren: `Einstellungen → Profile → Zahnrad → "...exportieren"`

### Schritt 3: Exportiertes Profil ins Repository

```zsh
# Altes Profil ersetzen
mv ~/Downloads/catppuccin-mocha.terminal ~/dotfiles/setup/

# Änderung committen
cd ~/dotfiles
git add setup/catppuccin-mocha.terminal
git commit -m "Terminal-Profil: FiraCode Nerd Font"
```

---

## Aliase anpassen

### Eigene Aliase hinzufügen

Erstelle eine neue Datei in `terminal/.config/alias/`:

```zsh
# terminal/.config/alias/custom.alias

# Guard: Diese Datei hat keine Tool-Abhängigkeit
# Wird immer geladen

# Meine Shortcuts
alias projects='cd ~/Projects'
alias dotfiles='cd ~/dotfiles'
```

### Bestehende Aliase überschreiben

Aliase werden in alphabetischer Reihenfolge geladen. Um einen bestehenden Alias zu überschreiben, erstelle eine Datei die **nach** der Original-Datei geladen wird:

```zsh
# terminal/.config/alias/zzz-overrides.alias

# ls ohne Icons (falls eza-Icons stören)
alias ls='eza --no-icons'
```

---

## fzf anpassen

### Globale Optionen

Die fzf-Konfiguration liegt in `terminal/.config/fzf/config`:

```zsh
# Catppuccin Mocha Farben (bereits konfiguriert)
--color=bg+:#313244,bg:#1e1e2e,...

# Layout
--height=~50%
--layout=reverse
--border=rounded
```

### Keybindings ändern

Shell-Keybindings für fzf werden in `terminal/.config/fzf/init.zsh` definiert:

```zsh
# Ctrl+X Prefix für dotfiles-Keybindings
bindkey '^X1' fzf-history-widget
bindkey '^X2' fzf-file-widget
bindkey '^X3' fzf-cd-widget
```

---

## Weitere Anpassungen

| Was | Wo | Format |
|-----|-----|--------|
| bat Theme | `~/.config/bat/config` | `--theme="..."` |
| fd Ignore-Patterns | `~/.config/fd/ignore` | Glob-Patterns |
| ripgrep Optionen | `~/.config/ripgrep/config` | CLI-Flags |
| lazygit Keybindings | `~/.config/lazygit/config.yml` | YAML |
| fastfetch Modules | `~/.config/fastfetch/config.jsonc` | JSONC |
