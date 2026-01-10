#!/usr/bin/env zsh
# ============================================================
# customization.sh - Generator für docs/customization.md
# ============================================================
# Zweck   : Generiert Anpassungs-Dokumentation aus Config-Dateien
# Pfad    : scripts/generators/customization.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Extraktionsfunktionen (Single Source of Truth)
# ------------------------------------------------------------

# Extrahiert Farbpalette aus theme-colors und generiert Markdown-Tabelle
# Konvertiert RGB zu Hex und gruppiert nach Kategorie
generate_color_palette_table() {
    local colors_file="$DOTFILES_DIR/terminal/.config/theme-colors"
    [[ -f "$colors_file" ]] || return 1
    
    echo "| Farbe | Hex | Variable |"
    echo "| ----- | --- | -------- |"
    
    # Regex: typeset -gx C_NAME=$'\033[38;2;R;G;Bm'  # #HEX
    while IFS= read -r line; do
        # Nur Farbdefinitionen mit RGB-Werten (keine Aliase)
        [[ "$line" =~ ^typeset.*C_([A-Z0-9]+).*38\;2\;([0-9]+)\;([0-9]+)\;([0-9]+) ]] || continue
        
        local name="${match[1]}"
        local r="${match[2]}"
        local g="${match[3]}"
        local b="${match[4]}"
        
        # RGB zu Hex
        local hex=$(printf "#%02X%02X%02X" "$r" "$g" "$b")
        
        # Name formatieren (SUBTEXT1 → Subtext1)
        local display_name="${(C)name:l}"
        
        echo "| $display_name | \`$hex\` | \`C_$name\` |"
    done < "$colors_file"
}

# Extrahiert fzf-Farben aus der echten Config
# Zeigt alle --color Zeilen + die wichtigsten Layout-Optionen als Beispiel
extract_fzf_colors() {
    local config="$DOTFILES_DIR/terminal/.config/fzf/config"
    [[ -f "$config" ]] || { echo '```zsh'; echo '# Config nicht gefunden'; echo '```'; return 1; }
    
    echo '```zsh'
    echo '# Catppuccin Mocha Farben (bereits konfiguriert)'
    grep '^--color=' "$config"
    echo ''
    echo '# Layout (Auszug)'
    grep -E '^--(height|layout|border)=' "$config" | head -3
    echo '```'
}

# Extrahiert fzf-Keybindings aus init.zsh
extract_fzf_keybindings() {
    local init="$DOTFILES_DIR/terminal/.config/fzf/init.zsh"
    [[ -f "$init" ]] || { echo '```zsh'; echo '# Config nicht gefunden'; echo '```'; return 1; }
    
    echo '```zsh'
    echo '# Ctrl+X Prefix für dotfiles-Keybindings'
    grep "^bindkey '\^X" "$init"
    echo '```'
}

# Extrahiert den Terminal-Profilnamen aus der .terminal-Datei im setup/
# Gibt Dateinamen ohne Endung zurück (z.B. "catppuccin-mocha")
extract_terminal_profile_name() {
    local terminal_file
    terminal_file=$(find "$DOTFILES_DIR/setup" -maxdepth 1 -name "*.terminal" | sort | head -1)
    [[ -f "$terminal_file" ]] || return 1
    
    # Dateiname ohne Pfad und ohne .terminal-Endung
    echo "${${terminal_file:t}%.terminal}"
}

# Extrahiert den installierten Nerd Font aus Brewfile
# Hinweis: Bei mehreren Nerd Fonts wird nur der erste als Beispiel verwendet
extract_installed_nerd_font() {
    local brewfile="$DOTFILES_DIR/setup/Brewfile"
    [[ -f "$brewfile" ]] || return 1
    
    # Findet: cask "font-xyz-nerd-font" (erster Treffer)
    grep -o 'cask "font-[^"]*-nerd-font"' "$brewfile" | head -1 | sed 's/cask "\(.*\)"/\1/'
}

# Generiert Font-Anzeigename aus Cask-Name
# Eingabe:  font-meslo-lg-nerd-font (Brew Cask-Name)
# Ausgabe:  MesloLG Nerd Font Mono (Anzeigename in Font-Auswahl)
# Bekannte Fonts sind explizit gemappt, Fallback kapitalisiert und entfernt Bindestriche
font_display_name() {
    local cask="$1"
    [[ -z "$cask" ]] && { echo "Nerd Font"; return; }
    
    # Entferne "font-" Prefix und "-nerd-font" Suffix
    local base="${cask#font-}"
    base="${base%-nerd-font}"
    
    # Mapping bekannter Fonts (markenspezifische Schreibweisen)
    case "$base" in
        meslo-lg)       echo "MesloLG Nerd Font Mono" ;;
        jetbrains-mono) echo "JetBrainsMono Nerd Font Mono" ;;
        fira-code)      echo "FiraCode Nerd Font Mono" ;;
        *)              echo "${${(C)base}//-/} Nerd Font Mono" ;;  # Fallback: Capitalize + Bindestriche entfernen
    esac
}

# ------------------------------------------------------------
# Theme-Konfigurationen sammeln
# ------------------------------------------------------------
# Durchsucht bekannte Konfigurationspfade nach Theme-Einstellungen
collect_theme_configs() {
    local output=""
    
    # Terminal-Profil und Xcode-Theme dynamisch ermitteln (alphabetisch erste)
    local terminal_file
    terminal_file=$(find "$DOTFILES_DIR/setup" -maxdepth 1 -name "*.terminal" | sort | head -1)
    
    local xcode_file
    xcode_file=$(find "$DOTFILES_DIR/setup" -maxdepth 1 -name "*.xccolortheme" | sort | head -1)
    
    # Bekannte Theme-Dateien
    local -A theme_files=(
        ["Terminal.app"]="$terminal_file|Via Bootstrap importiert + als Standard gesetzt"
        ["Starship"]="catppuccin-powerline Preset|Via Bootstrap konfiguriert"
        ["bat"]="$DOTFILES_DIR/terminal/.config/bat/themes/|Via Stow verlinkt (+ Cache-Build)"
        ["fzf"]="$DOTFILES_DIR/terminal/.config/fzf/config|Farben in Config-Datei (via Stow)"
        ["btop"]="$DOTFILES_DIR/terminal/.config/btop/themes/|Via Stow verlinkt"
        ["eza"]="$DOTFILES_DIR/terminal/.config/eza/theme.yml|Via Stow verlinkt"
        ["zsh-syntax-highlighting"]="$DOTFILES_DIR/terminal/.config/zsh/|Via Stow verlinkt"
        ["Xcode"]="$xcode_file|Via Bootstrap kopiert (manuelle Aktivierung)"
    )
    
    output+="| Tool | Theme-Datei | Status |\n"
    output+="| ---- | ----------- | ------ |\n"
    
    for tool in "Terminal.app" "Starship" "bat" "fzf" "btop" "eza" "zsh-syntax-highlighting" "Xcode"; do
        local info="${theme_files[$tool]}"
        local file="${info%%|*}"
        local stat="${info##*|}"
        
        # Überspringen wenn Datei leer (optionale Themes: Terminal.app, Xcode)
        [[ -z "$file" && ( "$tool" == "Xcode" || "$tool" == "Terminal.app" ) ]] && continue
        
        # Datei/Verzeichnis kürzen für Anzeige
        local display_file="$file"
        if [[ "$file" == "$DOTFILES_DIR"* ]]; then
            display_file="${file#$DOTFILES_DIR/}"
            display_file="\`$display_file\`"
        fi
        
        output+="| **$tool** | $display_file | $stat |\n"
    done
    
    echo "$output"
}

# ------------------------------------------------------------
# Haupt-Generator für customization.md
# ------------------------------------------------------------
generate_customization_md() {
    cat << 'HEADER'
# ⚙️ Konfiguration

Diese Anleitung erklärt, wie du die dotfiles an deine Bedürfnisse anpassen kannst.

---

## Catppuccin Mocha Theme

Das gesamte Setup verwendet [Catppuccin Mocha](https://catppuccin.com/) als einheitliches Farbschema. Dies gewährleistet ein konsistentes Erscheinungsbild über alle Tools hinweg.

### Konfigurierte Tools

HEADER

    # Theme-Tabelle
    collect_theme_configs
    
    # Xcode-Sektion nur wenn .xccolortheme existiert
    local xcode_theme
    xcode_theme=$(find "$DOTFILES_DIR/setup" -maxdepth 1 -name "*.xccolortheme" | sort | head -1)
    if [[ -n "$xcode_theme" ]]; then
        local xcode_name="${xcode_theme:t}"  # Dateiname mit Endung
        cat << XCODE_SECTION
### Xcode Theme aktivieren

Das Catppuccin Mocha Theme für Xcode wird automatisch vom Bootstrap-Skript nach \`~/Library/Developer/Xcode/UserData/FontAndColorThemes/\` kopiert, muss aber einmalig manuell aktiviert werden:

1. **Xcode** öffnen
2. **Xcode** → **Settings** (⌘,)
3. Tab **Themes** auswählen
4. **Catppuccin Mocha** anklicken

> **Hinweis:** Änderungen am Original in \`setup/$xcode_name\` werden bei erneutem Bootstrap-Lauf übernommen.
XCODE_SECTION
    fi

    cat << 'FONT_SECTION'

### Farbpalette (Catppuccin Mocha)

Alle verfügbaren Shell-Farbvariablen aus `~/.config/theme-colors`:

FONT_SECTION

    # Dynamisch aus theme-colors generieren
    generate_color_palette_table
    
    cat << 'AFTER_COLORS'

> **Verwendung in Skripten:**

```zsh
source ~/.config/theme-colors
echo "${C_GREEN}Erfolg${C_RESET}"
```

Vollständige Palette: [catppuccin.com/palette](https://catppuccin.com/palette)

---

## Starship-Prompt

Das Setup konfiguriert automatisch [Starship](https://starship.rs/) mit dem `catppuccin-powerline` Preset.

### Standard-Verhalten

| Situation | Verhalten |
| --------- | --------- |
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
AFTER_COLORS

    # Terminal-Profilname für die Warnung dynamisch ermitteln
    local profile_for_warning
    profile_for_warning=$(extract_terminal_profile_name)
    [[ -z "$profile_for_warning" ]] && profile_for_warning="<profilname>"

    cat << FONT_WARNING
> **⚠️ Wichtig:** Die Datei \`$profile_for_warning.terminal\` enthält binäre NSArchiver-Daten. **Niemals direkt editieren** – nur über die Terminal.app GUI ändern und neu exportieren.

### Voraussetzung

Bei Starship-Presets mit Powerline-Symbolen (wie \`catppuccin-powerline\`) muss die neue Schriftart ein **Nerd Font** sein. Nerd Fonts enthalten zusätzliche Icons und Symbole, die für Powerline-Prompts benötigt werden.

### Schritt 1: Neuen Nerd Font installieren

FONT_WARNING

    # Font-Beispiel dynamisch generieren
    # Fallback: Generischer Platzhalter statt konkretem Font (ehrlicher bei fehlendem Brewfile)
    local installed_font
    installed_font=$(extract_installed_nerd_font)
    [[ -z "$installed_font" ]] && installed_font="font-<name>-nerd-font"
    local display_name
    display_name=$(font_display_name "$installed_font")
    
    # Terminal-Profilname dynamisch aus .terminal-Datei
    local profile_name
    profile_name=$(extract_terminal_profile_name)
    [[ -z "$profile_name" ]] && profile_name="<profilname>"
    
    cat << FONT_EXAMPLE
\`\`\`zsh
# Verfügbare Nerd Fonts suchen
brew search nerd-font

# Beispiel: Nerd Font installieren (z.B. $installed_font)
brew install --cask $installed_font
\`\`\`

### Schritt 2: Terminal.app Profil anpassen

1. Terminal.app öffnen
2. **Terminal** → **Einstellungen** → **Profile** → **$profile_name**
3. Tab **Text** → **Schrift** → **Ändern…**
4. Neuen Nerd Font auswählen (z.B. "$display_name")
5. Größe anpassen (empfohlen: 13-14pt)
6. Profil exportieren: **Einstellungen** → **Profile** → **Zahnrad** → **"...exportieren"**

### Schritt 3: Exportiertes Profil ins Repository

\`\`\`zsh
# Optional: Altes Profil sichern
mv ~/dotfiles/setup/*.terminal ~/dotfiles/setup/old-profile.terminal.bak

# Neues Profil verschieben
mv ~/Downloads/<profilname>.terminal ~/dotfiles/setup/

# Backup entfernen (wenn nicht mehr benötigt)
rm ~/dotfiles/setup/*.bak

# Änderung committen
cd ~/dotfiles
git add setup/*.terminal
git commit -m "Terminal-Profil: <Neuer Font Name>"
\`\`\`

> **Hinweis:** Der Dateiname ist frei wählbar – bootstrap.sh findet automatisch die alphabetisch erste \`.terminal\`-Datei in \`setup/\`. Bei mehreren Dateien erscheint eine Warnung.

FONT_EXAMPLE

    cat << 'ALIASES_SECTION'
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

ALIASES_SECTION

    # fzf-Farben dynamisch extrahieren
    extract_fzf_colors

    cat << 'FZF_KEYBINDINGS'

### Keybindings ändern

Shell-Keybindings für fzf werden in `terminal/.config/fzf/init.zsh` definiert:

FZF_KEYBINDINGS

    # fzf-Keybindings dynamisch extrahieren
    extract_fzf_keybindings

    cat << 'FOOTER'

---

## Weitere Anpassungen

| Was | Wo | Format |
| --- | -- | ------ |
| bat Theme | `~/.config/bat/config` | `--theme="..."` |
| fd Ignore-Patterns | `~/.config/fd/ignore` | Glob-Patterns |
| ripgrep Optionen | `~/.config/ripgrep/config` | CLI-Flags |
| lazygit Keybindings | `~/.config/lazygit/config.yml` | YAML |
| fastfetch Modules | `~/.config/fastfetch/config.jsonc` | JSONC |

FOOTER
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_customization_md || true
