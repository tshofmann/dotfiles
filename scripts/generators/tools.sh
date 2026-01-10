#!/usr/bin/env zsh
# ============================================================
# tools.sh - Generator für docs/tools.md
# ============================================================
# Zweck   : Generiert Tool-Dokumentation aus .alias-Dateien
# Pfad    : scripts/generators/tools.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Tool-Nutzung aus Alias-Dateien generieren
# ------------------------------------------------------------
# Generiert Sektion mit Codeblocks für jedes Tool
generate_tool_usage_section() {
    local output=""
    
    # Nur für Tools mit mehr als 3 Aliasen
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local tool_name=$(basename "$alias_file" .alias)
        local alias_count=0
        alias_count=$(grep -c "^alias " "$alias_file" 2>/dev/null) || alias_count=0
        
        # Mindestens 3 Aliase für eine Nutzungs-Sektion
        [[ "$alias_count" -lt 3 ]] && continue
        
        local usage=$(extract_usage_codeblock "$alias_file")
        [[ -z "${usage// /}" ]] && continue
        
        # Tool-Titel aus Header extrahieren
        local title=$(parse_header_field "$alias_file" "Zweck")
        [[ -z "$title" ]] && title="Aliase für $tool_name"
        
        local hinweis=$(parse_header_field "$alias_file" "Hinweis")
        
        output+="### $tool_name – ${title#Aliase für }\n\n"
        output+="\`\`\`zsh\n"
        output+="${usage%\\n}"  # Trailing newline entfernen falls vorhanden
        output+="\n\`\`\`\n\n"
        
        if [[ -n "$hinweis" ]]; then
            output+="> **Hinweis:** $hinweis\n\n"
        fi
        
        output+="---\n\n"
    done
    
    echo "$output"
}

# ------------------------------------------------------------
# ZSH-Plugins Bedienung aus .zshrc extrahieren
# ------------------------------------------------------------
# Parst die ZSH-Plugins Sektion in ~/.zshrc:
#   # Autosuggestions: Zeigt Vorschläge aus History
#   #   →        Vorschlag komplett übernehmen
#   #   Alt+→    Wort für Wort übernehmen
#   # Syntax-Highlighting: Farben zeigen Befehlsgültigkeit
#   #   Grün          Gültiger Befehl
generate_zsh_plugins_usage() {
    local output=""
    local current_plugin=""
    local -A plugin_entries  # plugin_name -> "key|value\nkey|value"
    local zshrc="$DOTFILES_DIR/terminal/.zshrc"
    
    [[ -f "$zshrc" ]] || return 1
    
    while IFS= read -r line; do
        # Plugin-Block erkennen: "# Autosuggestions:" oder "# Syntax-Highlighting:"
        if [[ "$line" == "# Autosuggestions:"* ]]; then
            current_plugin="zsh-autosuggestions"
            continue
        fi
        if [[ "$line" == "# Syntax-Highlighting:"* ]]; then
            current_plugin="zsh-syntax-highlighting"
            continue
        fi
        
        # Key-Value Paar: "#   key    value" (3 Leerzeichen nach #)
        if [[ -n "$current_plugin" && "$line" == "#   "* ]]; then
            local stripped="${line#\#   }"
            # Trenne bei mehreren Leerzeichen
            local key="${stripped%%  *}"
            local rest="${stripped#*  }"
            # Entferne führende Leerzeichen vom Value
            local value="${rest#"${rest%%[![:space:]]*}"}"
            
            if [[ -n "$key" && -n "$value" ]]; then
                plugin_entries[$current_plugin]+="${key}|${value}"$'\n'
            fi
            continue
        fi
        
        # Block endet bei nicht-Kommentar oder source-Zeile
        if [[ -n "$current_plugin" && ( "$line" != "#"* || "$line" == "[["* ) ]]; then
            current_plugin=""
        fi
    done < "$zshrc"
    
    # Ausgabe für zsh-autosuggestions
    if [[ -n "${plugin_entries[zsh-autosuggestions]}" ]]; then
        output+="### zsh-autosuggestions\n\n"
        output+="Zeigt Befehlsvorschläge basierend auf der History beim Tippen an.\n\n"
        output+="| Taste | Aktion |\n"
        output+="| ----- | ------ |\n"
        
        local entries="${plugin_entries[zsh-autosuggestions]}"
        while IFS='|' read -r key value; do
            [[ -z "$key" ]] && continue
            key="${key%"${key##*[![:space:]]}"}"
            value="${value%"${value##*[![:space:]]}"}"
            output+="| \`$key\` | $value |\n"
        done <<< "$entries"
        output+="\n"
    fi
    
    # Ausgabe für zsh-syntax-highlighting
    if [[ -n "${plugin_entries[zsh-syntax-highlighting]}" ]]; then
        output+="### zsh-syntax-highlighting\n\n"
        output+="Färbt Kommandos während der Eingabe ein:\n\n"
        output+="| Farbe | Bedeutung |\n"
        output+="| ----- | ------ |\n"
        
        local entries="${plugin_entries[zsh-syntax-highlighting]}"
        while IFS='|' read -r key value; do
            [[ -z "$key" ]] && continue
            key="${key%"${key##*[![:space:]]}"}"
            value="${value%"${value##*[![:space:]]}"}"
            output+="| **$key** | $value |\n"
        done <<< "$entries"
        output+="\n"
    fi
    
    echo "$output"
}

# ------------------------------------------------------------
# Font-Sektion aus Brewfile extrahieren
# ------------------------------------------------------------
# Parst den Casks-Kommentarblock im Brewfile:
#   # Casks (Fonts & Tools)
#   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   # font-meslo-lg-nerd-font:
#   #   Variante: LDZNF (L=Large, DZ=Dotted Zero, NF=Nerd Font)
#   #   Speicherort: ~/Library/Fonts/
#   #   Zweck: Icons (Powerline, Devicons, Font Awesome, Octicons)
#   #   Alternativen: brew search nerd-font
#   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
generate_font_section() {
    local output=""
    local in_block=false
    local font_name=""
    local font_variante=""
    local font_speicherort=""
    local font_zweck=""
    local font_alternativen=""
    
    while IFS= read -r line; do
        # Start des Blocks
        if [[ "$line" == "# Casks"* ]]; then
            in_block=true
            continue
        fi
        
        # Ende des Blocks (cask-Zeile)
        if $in_block && [[ "$line" == cask\ * ]]; then
            # Font-Name aus cask-Zeile extrahieren (erste Font-Zeile)
            if [[ "$line" == *"font-"* && -z "$font_name" ]]; then
                font_name="${line#cask \"}"
                font_name="${font_name%%\"*}"
            fi
            break
        fi
        
        # Trennzeilen überspringen
        if [[ "$line" == "# ~"* ]]; then
            continue
        fi
        
        if $in_block; then
            # Font-spezifische Eigenschaften extrahieren
            if [[ "$line" =~ ^"#   Variante: "(.+)$ ]]; then
                font_variante="${match[1]}"
            elif [[ "$line" =~ ^"#   Speicherort: "(.+)$ ]]; then
                font_speicherort="${match[1]}"
            elif [[ "$line" =~ ^"#   Zweck: "(.+)$ ]]; then
                font_zweck="${match[1]}"
            elif [[ "$line" =~ ^"#   Alternativen: "(.+)$ ]]; then
                font_alternativen="${match[1]}"
            fi
        fi
    done < "$BREWFILE"
    
    # Fallback wenn Font nicht im Brewfile gefunden
    [[ -z "$font_name" ]] && font_name="font-meslo-lg-nerd-font"
    [[ -z "$font_variante" ]] && font_variante="Nerd Font"
    [[ -z "$font_speicherort" ]] && font_speicherort="~/Library/Fonts/"
    [[ -z "$font_zweck" ]] && font_zweck="Icons im Terminal"
    [[ -z "$font_alternativen" ]] && font_alternativen="brew search nerd-font"
    
    # Anzeigename aus font_name generieren (font-meslo-lg-nerd-font → MesloLG)
    local display_name="${font_name#font-}"
    display_name="${display_name%-nerd-font}"
    # Bindestriche entfernen und Title Case
    display_name=$(echo "$display_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' | tr -d ' ')
    
    output+="### ${display_name} Nerd Font\n\n"
    output+="| Eigenschaft | Wert |\n"
    output+="| ----------- | ---- |\n"
    output+="| **Name** | $font_variante |\n"
    output+="| **Installiert via** | \`brew install --cask $font_name\` |\n"
    output+="| **Speicherort** | \`$font_speicherort\` |\n"
    output+="| **Zweck** | $font_zweck |\n\n"
    
    output+="### Warum Nerd Fonts?\n\n"
    output+="Nerd Fonts sind gepatchte Schriftarten mit zusätzlichen Glyphen:\n\n"
    
    # Icons aus Zweck-Feld parsen (Format: "Icons (A, B, C)")
    if [[ "$font_zweck" =~ "Icons" ]]; then
        local icons="${font_zweck#*\(}"
        icons="${icons%\)}"
        local IFS=', '
        for icon in ${(s/, /)icons}; do
            case "$icon" in
                Powerline) output+="- **Powerline-Symbole** – für Prompt-Segmente (Starship)\n" ;;
                Devicons)  output+="- **Devicons** – Sprach- und Framework-Icons (eza)\n" ;;
                "Font Awesome") output+="- **Font Awesome** – Allgemeine Icons\n" ;;
                Octicons)  output+="- **Octicons** – GitHub-Icons\n" ;;
            esac
        done
    fi
    output+="\n"
    
    output+="### Alternative Fonts\n\n"
    output+="\`\`\`zsh\n"
    output+="# Verfügbare Nerd Fonts suchen\n"
    output+="$font_alternativen\n\n"
    output+="# Beispiel: JetBrains Mono installieren\n"
    output+="brew install --cask font-jetbrains-mono-nerd-font\n"
    output+="\`\`\`\n"
    
    echo "$output"
}

# ------------------------------------------------------------
# Theming-Abschnitt generieren
# ------------------------------------------------------------
generate_theming_section() {
    local output=""
    
    output+="Alle Tools nutzen das **Catppuccin Mocha** Farbschema für ein einheitliches Erscheinungsbild:\n\n"
    output+="| Tool | Lokale Konfiguration | Upstream-Quelle |\n"
    output+="| ---- | -------------------- | --------------- |\n"
    output+="| **bat** | \`~/.config/bat/themes/Catppuccin Mocha.tmTheme\` | [github.com/catppuccin/bat](https://github.com/catppuccin/bat) |\n"
    output+="| **btop** | \`~/.config/btop/themes/catppuccin_mocha.theme\` | [github.com/catppuccin/btop](https://github.com/catppuccin/btop) |\n"
    output+="| **eza** | \`~/.config/eza/theme.yml\` | [github.com/catppuccin/eza](https://github.com/catppuccin/eza) |\n"
    output+="| **fzf** | \`~/.config/fzf/config\` | [github.com/catppuccin/fzf](https://github.com/catppuccin/fzf) |\n"
    output+="| **lazygit** | \`~/.config/lazygit/config.yml\` | [github.com/catppuccin/lazygit](https://github.com/catppuccin/lazygit) |\n"
    output+="| **tealdeer** | \`~/.config/tealdeer/config.toml\` | manuell (Catppuccin Palette) |\n"
    output+="| **zsh-syntax-highlighting** | \`~/.config/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh\` | [github.com/catppuccin/zsh-syntax-highlighting](https://github.com/catppuccin/zsh-syntax-highlighting) |\n"
    output+="| **Terminal.app** | \`setup/catppuccin-mocha.terminal\` | [github.com/catppuccin/Terminal.app](https://github.com/catppuccin/Terminal.app) |\n"
    output+="| **Xcode** | \`setup/Catppuccin Mocha.xccolortheme\` | [github.com/catppuccin/xcode](https://github.com/catppuccin/xcode) |\n"
    output+="\n"
    output+="> **Hinweis:** Shell-Farben sind zentral in \`terminal/.config/theme-colors\` definiert.\n"
    output+="> Die vollständige Palette findest du unter [catppuccin.com/palette](https://catppuccin.com/palette).\n"
    
    echo "$output"
}

# ------------------------------------------------------------
# Weiterführende Links sammeln
# ------------------------------------------------------------
generate_links_section() {
    local output=""
    
    output+="- [Homebrew Formulae](https://formulae.brew.sh/)\n"
    output+="- [Nerd Fonts](https://www.nerdfonts.com/)\n"
    output+="- [Starship Presets](https://starship.rs/presets/)\n"
    output+="- [Catppuccin Ports](https://github.com/catppuccin/catppuccin#-ports-and-more) – Themes für weitere Tools\n"
    
    echo "$output"
}

# ------------------------------------------------------------
# Alias-Extraktion aus einer .alias-Datei
# ------------------------------------------------------------
# Rückgabe: Markdown-Tabelle mit Alias|Befehl|Beschreibung
extract_aliases_from_file() {
    local file="$1"
    local output=""
    local prev_comment=""
    local in_section=""
    
    while IFS= read -r line; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        
        # Sektion erkennen (# ---- BESCHREIBUNG ----)
        if [[ "$trimmed" == "# ----"*"----" ]]; then
            in_section="${trimmed#\# ----}"
            in_section="${in_section%%----*}"
            in_section="${in_section## }"
            in_section="${in_section%% }"
            continue
        fi
        
        # Kommentar merken
        if [[ "$trimmed" == \#* && "$trimmed" != \#\ ====* ]]; then
            local content="${trimmed#\# }"
            local first_word="${content%% *}"
            # Header-Keywords ignorieren
            case "$first_word" in
                Zweck|Hinweis|Pfad|Docs|Guard|Voraussetzung)
                    prev_comment=""
                    ;;
                *)
                    prev_comment="$content"
                    ;;
            esac
            continue
        fi
        
        # Alias-Zeile
        if [[ "$trimmed" == alias\ * ]]; then
            local alias_part="${trimmed#alias }"
            local alias_name="${alias_part%%=*}"
            alias_name="${alias_name## }"
            alias_name="${alias_name%% }"
            
            if [[ -n "$alias_name" && "$alias_name" != *" "* ]]; then
                local command=$(parse_alias_command "$trimmed")
                local desc="$prev_comment"
                [[ -z "$desc" ]] && desc="-"
                
                output+="| \`$alias_name\` | \`$command\` | $desc |\n"
            fi
            prev_comment=""
        fi
    done < "$file"
    
    echo "$output"
}

# ------------------------------------------------------------
# Funktions-Extraktion aus einer .alias-Datei
# ------------------------------------------------------------
# Rückgabe: Markdown-Tabelle mit Funktion|Beschreibung
extract_functions_from_file() {
    local file="$1"
    local output=""
    local prev_comment=""
    
    while IFS= read -r line; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        
        # Kommentar merken
        if [[ "$trimmed" == \#* && "$trimmed" != \#\ ====* && "$trimmed" != \#\ ----* ]]; then
            local content="${trimmed#\# }"
            local first_word="${content%% *}"
            case "$first_word" in
                Zweck|Hinweis|Pfad|Docs|Guard|Voraussetzung)
                    prev_comment=""
                    ;;
                *)
                    # Nur Beschreibungskommentare mit – oder -
                    if [[ "$content" == *" – "* || "$content" == *" - "* ]]; then
                        prev_comment="$content"
                    fi
                    ;;
            esac
            continue
        fi
        
        # Funktion gefunden
        if [[ "$trimmed" =~ "^[a-zA-Z][a-zA-Z0-9_-]*\(\)" ]]; then
            local func_name="${trimmed%%\(*}"
            
            # Private Funktionen überspringen
            [[ "$func_name" == _* ]] && { prev_comment=""; continue; }
            
            if [[ -n "$prev_comment" ]]; then
                local parsed=$(parse_description_comment "# $prev_comment")
                local name="${parsed%%|*}"
                local rest="${parsed#*|}"
                local param="${rest%%|*}"
                rest="${rest#*|}"
                local keybindings="${rest%%|*}"
                
                local desc="$name"
                [[ -n "$keybindings" ]] && desc+=" ($keybindings)"
                
                output+="| \`$func_name\` | $desc |\n"
            fi
            prev_comment=""
        fi
    done < "$file"
    
    echo "$output"
}

# ------------------------------------------------------------
# Installierte Tools aus Brewfile
# ------------------------------------------------------------
generate_installed_tools_table() {
    local output=""
    
    output+="| Tool | Beschreibung | Dokumentation |\n"
    output+="| ---- | ------------ | ------------- |\n"
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        rest="${rest#*|}"
        local typ="${rest%%|*}"
        local url="${rest#*|}"
        
        # Nur brew (CLI-Tools) und ZSH-Plugins
        [[ "$typ" != "brew" ]] && continue
        
        # URL als Markdown-Link formatieren
        local docs="-"
        if [[ -n "$url" ]]; then
            local display="${url#https://}"
            display="${display#http://}"
            display="${display%/}"
            docs="[$display]($url)"
        fi
        
        output+="| **$name** | $desc | $docs |\n"
    done < "$BREWFILE"
    
    echo "$output"
}

# ------------------------------------------------------------
# Casks aus Brewfile
# ------------------------------------------------------------
generate_casks_table() {
    local output=""
    
    output+="| App | Beschreibung | Dokumentation |\n"
    output+="| --- | ------------ | ------------- |\n"
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        rest="${rest#*|}"
        local typ="${rest%%|*}"
        local url="${rest#*|}"
        
        [[ "$typ" != "cask" ]] && continue
        
        # URL als Markdown-Link formatieren
        local docs="-"
        if [[ -n "$url" ]]; then
            local display="${url#https://}"
            display="${display#http://}"
            display="${display%/}"
            docs="[$display]($url)"
        fi
        
        output+="| **$name** | $desc | $docs |\n"
    done < "$BREWFILE"
    
    echo "$output"
}

# ------------------------------------------------------------
# MAS-Apps aus Brewfile
# ------------------------------------------------------------
generate_mas_table() {
    local output=""
    
    output+="| App | Beschreibung | Dokumentation |\n"
    output+="| --- | ------------ | ------------ |\n"
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        rest="${rest#*|}"
        local typ="${rest%%|*}"
        local url="${rest#*|}"
        
        [[ "$typ" != "mas" ]] && continue
        
        # URL als Markdown-Link formatieren
        local docs="-"
        if [[ -n "$url" ]]; then
            local display="${url#https://}"
            display="${display#http://}"
            display="${display%/}"
            docs="[$display]($url)"
        fi
        
        output+="| **$name** | $desc | $docs |\n"
    done < "$BREWFILE"
    
    echo "$output"
}

# ------------------------------------------------------------
# Haupt-Generator für tools.md
# ------------------------------------------------------------
generate_tools_md() {
    local output=""
    
    # Header
    output+='# 🛠️ Tools

Übersicht aller installierten CLI-Tools und verfügbaren Aliase.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen direkt im Code (`.alias`-Dateien, `Brewfile`) vornehmen.

---

## Schnellreferenz für Einsteiger

Die wichtigsten Tastenkombinationen und Befehle auf einen Blick:

### Tastenkombinationen (global)

| Taste | Funktion | Beschreibung |
| ----- | -------- | ------------ |
| `Ctrl+X 1` | History-Suche | Frühere Befehle fuzzy suchen |
| `Ctrl+X 2` | Datei einfügen | Datei suchen und in Kommandozeile einfügen |
| `Ctrl+X 3` | Verzeichnis wechseln | Interaktiv in Unterverzeichnis springen |
| `Tab` | Autovervollständigung | Befehle, Pfade, Optionen vervollständigen |
| `→` (Pfeil rechts) | Vorschlag übernehmen | zsh-autosuggestion akzeptieren |

### Die wichtigsten Aliase

| Alias | Statt | Funktion |
| ----- | ----- | -------- |
| `ls` | `ls` | Dateien mit Icons anzeigen |
| `ll` | `ls -la` | Ausführliche Auflistung |
| `cat` | `cat` | Datei mit Syntax-Highlighting |
| `z <ort>` | `cd <pfad>` | Zu häufig besuchtem Verzeichnis springen |
| `brewup` | - | Alle Pakete + Apps aktualisieren |

### Erste Schritte nach der Installation

```zsh
# 1. System aktualisieren
brewup

# 2. Verzeichnis mit Icons anzeigen
ls

# 3. Datei mit Syntax-Highlighting anzeigen
cat ~/.zshrc

# 4. Frühere Befehle suchen (Ctrl+X 1 drücken, tippen, Enter)

# 5. Zu einem Verzeichnis springen (lernt mit der Zeit)
z dotfiles
```

> 💡 **Tipp:** Alle Aliase haben Guard-Checks – fehlt ein Tool, funktioniert der Original-Befehl weiterhin.

---

## Alias-Suche und Dokumentation

### fa – Interaktive Alias-Suche

Die `fa`-Funktion (fzf alias) durchsucht alle Aliase und Funktionen:

```zsh
fa              # Alle Aliase/Funktionen durchsuchen
fa commit       # Nach "commit" filtern
```

| Keybinding | Aktion |
| ---------- | ------ |
| `Enter` | Befehl übernehmen (ins Edit-Buffer) |
| `Ctrl+C` | Preview: Code-Definition |
| `Ctrl+T` | Preview: tldr für Tool-Kategorie |

### brewv – Versionsübersicht

```zsh
brewv           # Alle Formulae, Casks und MAS-Apps mit Versionen
```

---

## tldr mit dotfiles-Erweiterungen

Die `tldr`-Befehle zeigen neben der offiziellen Dokumentation auch **dotfiles-spezifische Aliase und Funktionen**:

```zsh
tldr git      # + Aliase (ga, gc, gp) + Funktionen (glog, gbr, gst)
tldr fzf      # + Tastenkürzel + Funktionen (zf, fkill, fman, ...)
tldr brew     # + brewup, mas-Aliase, fzf-Funktionen
tldr bat      # + cat, catn, catd Aliase
tldr rg       # + rgc, rgi, rga + rgf Funktion
```

Die Erweiterungen sind als Patches implementiert – sie werden automatisch an die offizielle Dokumentation angehängt und beginnen mit `# dotfiles:`.

---

## Installierte CLI-Tools

Diese Tools werden via Brewfile installiert:

'
    output+=$(generate_installed_tools_table)
    
    output+='

### ZSH-Plugins

| Plugin | Beschreibung | Dokumentation |
| ------ | ------------ | ------------- |
| **zsh-autosuggestions** | History-basierte Befehlsvorschläge beim Tippen | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| **zsh-syntax-highlighting** | Echtzeit Syntax-Highlighting für Kommandos | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |

### Casks (Fonts & Tools)

Diese Pakete werden via `brew install --cask` installiert:

'
    output+=$(generate_casks_table)
    
    output+='

### Mac App Store Apps

Diese Apps werden via `mas` installiert (Benutzer muss im App Store angemeldet sein):

'
    output+=$(generate_mas_table)
    
    output+='

> **Hinweis:** Die Anmeldung im App Store muss manuell über App Store.app erfolgen – die Befehle `mas account` und `mas signin` sind auf macOS 12+ nicht verfügbar.

---

## Theming

'
    output+=$(generate_theming_section)

    output+='

---

## Aliase

Verfügbare Aliase aus `~/.config/alias/`:

> **Guard-System:** Alle Tool-Aliase prüfen zuerst ob das jeweilige Tool installiert ist (`command -v`). Ist ein Tool nicht vorhanden, bleiben die originalen Befehle (`ls`, `cat`, `grep`) erhalten.

'
    
    # Alias-Tabellen für jedes Tool
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local tool_name=$(basename "$alias_file" .alias)
        local docs_url=$(parse_header_field "$alias_file" "Docs")
        local hinweis=$(parse_header_field "$alias_file" "Hinweis")
        
        output+="\n### ${tool_name}.alias\n\n"
        
        # Aliase
        local aliases=$(extract_aliases_from_file "$alias_file")
        if [[ -n "${aliases// /}" ]]; then
            output+="| Alias | Befehl | Beschreibung |\n"
            output+="| ----- | ------ | ------------ |\n"
            output+="${aliases}"
        fi
        
        # Funktionen
        local funcs=$(extract_functions_from_file "$alias_file")
        if [[ -n "${funcs// /}" ]]; then
            output+="\n\n**Interaktive Funktionen (mit fzf):**\n\n"
            output+="| Funktion | Beschreibung |\n"
            output+="| -------- | ------------ |\n"
            output+="${funcs}"
        fi
        
        # Hinweis (mit Leerzeile davor für Markdown-Konformität)
        if [[ -n "$hinweis" ]]; then
            output+="\n\n> **Hinweis:** $hinweis\n"
        fi
        
        output+="\n"
    done
    
    # Tool-Nutzung Sektion
    output+='
---

## Tool-Nutzung

Ausführliche Beispiele für die wichtigsten Tools:

'
    output+=$(generate_tool_usage_section)
    
    # Font-Sektion
    output+='
## Font

'
    output+=$(generate_font_section)
    
    # ZSH-Plugins Bedienung
    output+='
---

## ZSH-Plugins

'
    output+=$(generate_zsh_plugins_usage)
    
    # Eigene Tools hinzufügen
    output+='
---

## Eigene Tools hinzufügen

### Brewfile erweitern

```zsh
# Brewfile editieren
$EDITOR ~/dotfiles/setup/Brewfile

# Beispiel: neues Tool hinzufügen
echo '\''brew "toolname"                          # Beschreibung'\'' >> ~/dotfiles/setup/Brewfile

# Installieren (HOMEBREW_BUNDLE_FILE ist in .zprofile gesetzt)
brew bundle
```

### Eigene Aliase

Siehe [CONTRIBUTING.md → Neues Tool hinzufügen](../CONTRIBUTING.md#neues-tool-hinzufügen) für eine Anleitung zum Erstellen eigener Alias-Dateien.

---

## Weiterführende Links

'
    output+=$(generate_links_section)
    
    output+='
---

[← Zurück zur Übersicht](../README.md)'
    
    echo -e "$output"
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_tools_md || true
