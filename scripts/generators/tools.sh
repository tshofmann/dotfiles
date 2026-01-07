#!/usr/bin/env zsh
# ============================================================
# tools.sh - Generator für docs/tools.md
# ============================================================
# Zweck   : Generiert Tool-Dokumentation aus .alias-Dateien
# Pfad    : scripts/generators/tools.sh
# ============================================================

source "${0:A:h}/lib.sh"

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
    
    echo -e "$output"
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
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Installierte Tools aus Brewfile
# ------------------------------------------------------------
generate_installed_tools_table() {
    local output=""
    
    output+="| Tool | Beschreibung | Dokumentation |\n"
    output+="|------|--------------|---------------|\n"
    
    # Bekannte Docs-URLs (aus bestehender tools.md extrahiert)
    typeset -A docs_urls
    docs_urls=(
        [bat]="[github.com/sharkdp/bat](https://github.com/sharkdp/bat)"
        [btop]="[github.com/aristocratos/btop](https://github.com/aristocratos/btop)"
        [eza]="[github.com/eza-community/eza](https://github.com/eza-community/eza)"
        [fastfetch]="[github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch)"
        [fd]="[github.com/sharkdp/fd](https://github.com/sharkdp/fd)"
        [fzf]="[github.com/junegunn/fzf](https://github.com/junegunn/fzf)"
        [gh]="[cli.github.com](https://cli.github.com/)"
        [lazygit]="[github.com/jesseduffield/lazygit](https://github.com/jesseduffield/lazygit)"
        [mas]="[github.com/mas-cli/mas](https://github.com/mas-cli/mas)"
        [ripgrep]="[github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)"
        [starship]="[starship.rs](https://starship.rs/)"
        [stow]="[gnu.org/software/stow](https://www.gnu.org/software/stow/)"
        [tealdeer]="[github.com/tealdeer-rs/tealdeer](https://github.com/tealdeer-rs/tealdeer)"
        [zoxide]="[github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)"
        [zsh-autosuggestions]="[github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)"
        [zsh-syntax-highlighting]="[github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)"
    )
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        local typ="${rest##*|}"
        
        # Nur brew (CLI-Tools) und ZSH-Plugins
        [[ "$typ" != "brew" ]] && continue
        
        local docs="${docs_urls[$name]:-}"
        [[ -z "$docs" ]] && docs="-"
        
        output+="| **$name** | $desc | $docs |\n"
    done < "$BREWFILE"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Casks aus Brewfile
# ------------------------------------------------------------
generate_casks_table() {
    local output=""
    
    output+="| App | Beschreibung | Dokumentation |\n"
    output+="|-----|--------------|---------------|\n"
    
    typeset -A cask_docs
    cask_docs=(
        [claude-code]="[github.com/anthropics/claude-code](https://github.com/anthropics/claude-code)"
        [font-meslo-lg-nerd-font]="[github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts)"
    )
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        local typ="${rest##*|}"
        
        [[ "$typ" != "cask" ]] && continue
        
        local docs="${cask_docs[$name]:-}"
        [[ -z "$docs" ]] && docs="-"
        
        output+="| **$name** | $desc | $docs |\n"
    done < "$BREWFILE"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# MAS-Apps aus Brewfile
# ------------------------------------------------------------
generate_mas_table() {
    local output=""
    
    output+="| App | Beschreibung |\n"
    output+="|-----|--------------|\n"
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        local typ="${rest##*|}"
        
        [[ "$typ" != "mas" ]] && continue
        
        output+="| **$name** | $desc |\n"
    done < "$BREWFILE"
    
    echo -e "$output"
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
|-------|----------|--------------|
| `Ctrl+X 1` | History-Suche | Frühere Befehle fuzzy suchen |
| `Ctrl+X 2` | Datei einfügen | Datei suchen und in Kommandozeile einfügen |
| `Ctrl+X 3` | Verzeichnis wechseln | Interaktiv in Unterverzeichnis springen |
| `Tab` | Autovervollständigung | Befehle, Pfade, Optionen vervollständigen |
| `→` (Pfeil rechts) | Vorschlag übernehmen | zsh-autosuggestion akzeptieren |

### Die wichtigsten Aliase

| Alias | Statt | Funktion |
|-------|-------|----------|
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
|------------|--------|
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
|--------|--------------|---------------|
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

## Aliase

Verfügbare Aliase aus `~/.config/alias/`:

> **Guard-System:** Alle Tool-Aliase prüfen zuerst ob das jeweilige Tool installiert ist (`command -v`). Ist ein Tool nicht vorhanden, bleiben die originalen Befehle (`ls`, `cat`, `grep`) erhalten.

'
    
    # Alias-Tabellen für jedes Tool
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local tool_name=$(basename "$alias_file" .alias)
        local docs_url=$(parse_header_field "$alias_file" "Docs")
        local hinweis=$(parse_header_field "$alias_file" "Hinweis")
        
        output+="\n<a name=\"${tool_name}alias\"></a>\n\n"
        output+="### ${tool_name}.alias\n\n"
        
        # Aliase
        local aliases=$(extract_aliases_from_file "$alias_file")
        if [[ -n "${aliases// /}" ]]; then
            output+="| Alias | Befehl | Beschreibung |\n"
            output+="|-------|--------|--------------|\n"
            output+="$aliases"
            output+="\n"
        fi
        
        # Funktionen
        local funcs=$(extract_functions_from_file "$alias_file")
        if [[ -n "${funcs// /}" ]]; then
            output+="**Interaktive Funktionen (mit fzf):**\n\n"
            output+="| Funktion | Beschreibung |\n"
            output+="|----------|--------------|\n"
            output+="$funcs"
            output+="\n"
        fi
        
        # Hinweis
        if [[ -n "$hinweis" ]]; then
            output+="> **Hinweis:** $hinweis\n"
        fi
        
        output+="\n"
    done
    
    echo -e "$output"
}

# Nur ausführen wenn direkt aufgerufen
if [[ "${(%):-%x}" == "${0:A}" ]]; then
    generate_tools_md
fi
