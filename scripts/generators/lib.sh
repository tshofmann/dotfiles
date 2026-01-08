#!/usr/bin/env zsh
# ============================================================
# lib.sh - Gemeinsame Bibliothek für Dokumentations-Generatoren
# ============================================================
# Zweck   : Parser, Hilfsfunktionen, Konfiguration
# Pfad    : scripts/generators/lib.sh
# ============================================================

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
GENERATORS_DIR="${SCRIPT_DIR}"
DOTFILES_DIR="${GENERATORS_DIR:h:h}"
ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"
DOCS_DIR="$DOTFILES_DIR/docs"
FZF_CONFIG="$DOTFILES_DIR/terminal/.config/fzf/config"
TEALDEER_DIR="$DOTFILES_DIR/terminal/.config/tealdeer/pages"
BREWFILE="$DOTFILES_DIR/setup/Brewfile"
BOOTSTRAP="$DOTFILES_DIR/setup/bootstrap.sh"
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/shell-colors"

# Farben (Catppuccin Mocha) – zentral definiert
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
log()  { echo -e "${C_BLUE}→${C_RESET} $1"; }
ok()   { echo -e "${C_GREEN}✔${C_RESET} $1"; }
warn() { echo -e "${C_YELLOW}⚠${C_RESET} $1"; }
err()  { echo -e "${C_RED}✖${C_RESET} $1" >&2; }
dim()  { echo -e "${C_DIM}$1${C_RESET}"; }

# ------------------------------------------------------------
# Parser: Header-Block Metadaten
# ------------------------------------------------------------
# Extrahiert Metadaten aus Header-Blöcken:
#   # Zweck   : Beschreibung
#   # Docs    : https://...
#   # Hinweis : Kann mehrzeilig sein
#               Fortsetzung mit Einrückung
# Rückgabe: Wert oder leer
parse_header_field() {
    local file="$1"
    local field="$2"
    local value=""
    local in_field=false
    
    while IFS= read -r line; do
        # Header endet bei Guard oder ====== Abschluss nach gefundenem Feld
        [[ "$line" == "# Guard"* ]] && break
        
        # Field-Pattern: # Field   : Value
        if [[ "$line" == "# ${field}"*":"* ]]; then
            value="${line#*: }"
            in_field=true
            continue
        fi
        
        # Fortsetzungszeile (mit Einrückung, Teil des aktuellen Felds)
        if $in_field; then
            if [[ "$line" == "#           "* ]]; then
                # Fortsetungszeile - füge zum Wert hinzu
                local continuation="${line#\#           }"
                value+=" $continuation"
            else
                # Keine Fortsetzung mehr
                break
            fi
        fi
    done < "$file"
    
    echo "$value"
}

# ------------------------------------------------------------
# Parser: Beschreibungskommentar (für Aliase/Funktionen)
# ------------------------------------------------------------
# Format: # Name(param?) – Key1=Aktion1, Key2=Aktion2
# Rückgabe: name|param|keybindings|description
parse_description_comment() {
    local comment="$1"
    local name param keybindings description
    
    # Entferne führendes "# "
    comment="${comment#\# }"
    comment="${comment#\#}"
    comment="${comment## }"
    
    # Extrahiere Name (vor Klammer oder Dash)
    if [[ "$comment" == *[a-zA-Z0-9]'('* ]]; then
        # Klammer direkt nach Wort → Parameter-Notation
        name="${comment%%\(*}"
        name="${name%% }"
        local param_part="${comment#*\(}"
        param="${param_part%%\)*}"
    elif [[ "$comment" == *' ('* ]]; then
        # Leerzeichen vor Klammer → nur Hinweis, kein Parameter
        name="${comment%% \(*}"
        name="${name%% –*}"
        name="${name%% -*}"
        param=""
    else
        name="${comment%% –*}"
        name="${name%% -*}"
        param=""
    fi
    
    # Keybindings extrahieren (nach – oder -)
    if [[ "$comment" == *" – "* ]]; then
        keybindings="${comment#* – }"
    elif [[ "$comment" == *" - "* ]]; then
        keybindings="${comment#* - }"
    else
        keybindings=""
    fi
    
    # Description ist der Name selbst (für tools.md Tabelle)
    description="$name"
    
    echo "${name}|${param}|${keybindings}|${description}"
}

# ------------------------------------------------------------
# Parser: Alias-Befehl extrahieren
# ------------------------------------------------------------
# Format: alias name='command' oder alias name="command"  # optional comment
# Rückgabe: command (ohne äußere Quotes)
# Unterstützt:
#   - Einfache Aliase: alias x='cmd'
#   - Mit Pipes: alias x='cmd | grep foo'
#   - Escaped single quotes: alias x='echo '\''text'\''' → echo 'text'
#   - Escaped double quotes: alias x="say \"hello\"" → say "hello"
parse_alias_command() {
    local line="$1"
    local after_eq
    
    # Entferne "alias name="
    after_eq="${line#alias *=}"
    
    # Entferne trailing comment (nach schließendem Quote und Whitespace)
    # Aber vorsichtig – # innerhalb des Befehls behalten
    
    if [[ "$after_eq" == \'* ]]; then
        # Single-quoted alias
        after_eq="${after_eq#\'}"  # Öffnendes Quote entfernen
        
        # Bei '\'' Pattern: Ersetze durch einzelnes Quote für Ausgabe
        # Das Pattern '\'' ist: Ende-Quote + Escaped-Quote + Start-Quote
        # Für die Doku wollen wir das lesbare Ergebnis
        local result=""
        local rest="$after_eq"
        
        while [[ -n "$rest" ]]; do
            # Nimm alles bis zum nächsten Quote
            local segment="${rest%%\'*}"
            result+="$segment"
            rest="${rest#"$segment"}"
            
            # Prüfe was nach dem Quote kommt
            if [[ "$rest" == "'\\''"* ]]; then
                # Pattern '\'' gefunden – füge literal ' hinzu
                result+="'"
                rest="${rest#\"'\\''\"}"
                rest="${rest#\'\\\'\'}"
            elif [[ "$rest" == "'"* ]]; then
                # Normales schließendes Quote – fertig
                break
            else
                # Kein Quote mehr – fertig
                break
            fi
        done
        
        echo "$result"
        
    elif [[ "$after_eq" == \"* ]]; then
        # Double-quoted alias
        after_eq="${after_eq#\"}"  # Öffnendes Quote entfernen
        
        # Bei \" Pattern: Ersetze durch einzelnes Quote für Ausgabe
        local result=""
        local rest="$after_eq"
        
        while [[ -n "$rest" ]]; do
            local segment="${rest%%\"*}"
            
            # Prüfe ob das " escaped war (Backslash davor)
            if [[ "$segment" == *'\' ]]; then
                # Escaped quote – füge ohne Backslash + Quote hinzu
                result+="${segment%\\}\""
                rest="${rest#"$segment"\"}"
            else
                # Normales schließendes Quote
                result+="$segment"
                break
            fi
        done
        
        echo "$result"
        
    else
        # Kein Quote (ungewöhnlich)
        echo "${after_eq%%[[:space:]#]*}"
    fi
}

# ------------------------------------------------------------
# Parser: Brewfile
# ------------------------------------------------------------
# Extrahiert Tool-Name, Beschreibung und URL
# Format: brew "name"                # Beschreibung | URL
# Rückgabe: name|beschreibung|typ|url (brew/cask/mas)
parse_brewfile_entry() {
    local line="$1"
    local name description typ url
    
    case "$line" in
        brew\ *)
            typ="brew"
            name="${line#brew \"}"
            name="${name%%\"*}"
            ;;
        cask\ *)
            typ="cask"
            name="${line#cask \"}"
            name="${name%%\"*}"
            ;;
        mas\ *)
            typ="mas"
            name="${line#mas \"}"
            name="${name%%\"*}"
            ;;
        *)
            return 1
            ;;
    esac
    
    # Beschreibung und URL aus Kommentar (Format: # Beschreibung | URL)
    if [[ "$line" == *"#"* ]]; then
        local comment="${line#*# }"
        if [[ "$comment" == *" | "* ]]; then
            description="${comment%% | *}"
            url="${comment##* | }"
        else
            description="$comment"
            url=""
        fi
    else
        description=""
        url=""
    fi
    
    echo "${name}|${description}|${typ}|${url}"
}

# ------------------------------------------------------------
# Parser: Tool-Nutzung aus Alias-Datei
# ------------------------------------------------------------
# Generiert Codeblock mit Alias-Beispielen pro Sektion
# Struktur: # ---- \n # Sektions-Titel \n # ---- \n # Beschreibung \n alias
extract_usage_codeblock() {
    local file="$1"
    local output=""
    local prev_line=""
    local prev_prev_line=""
    local current_section=""
    local in_header=true
    local first_section=true
    
    while IFS= read -r line; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        
        # Header überspringen (bis Guard endet)
        # Guard kann einzeilig sein: if ...; then return 0; fi
        # Oder mehrzeilig mit 'fi' auf eigener Zeile
        if $in_header; then
            if [[ "$trimmed" == "fi" || "$trimmed" == *"; fi" || "$trimmed" == *";fi" ]]; then
                in_header=false
                prev_line=""
                prev_prev_line=""
            fi
            continue
        fi
        
        # Sektions-Titel erkennen:
        # Aktuelle Zeile ist "# ----" und prev_prev_line war auch "# ----"
        # Dann ist prev_line der Titel
        if [[ "$trimmed" == "# ----"* && "$prev_prev_line" == "# ----"* ]]; then
            local title="${prev_line#\# }"
            if [[ -n "$title" && "$title" != "$current_section" ]]; then
                if ! $first_section; then
                    output+="\n"
                fi
                first_section=false
                output+="# ${title}\n"
                current_section="$title"
            fi
            prev_prev_line="$prev_line"
            prev_line="$trimmed"
            continue
        fi
        
        # Alias-Zeile mit vorheriger Beschreibung
        if [[ "$trimmed" == alias\ * && "$prev_line" == "# "* && "$prev_line" != "# ----"* ]]; then
            local alias_part="${trimmed#alias }"
            local alias_name="${alias_part%%=*}"
            alias_name="${alias_name## }"
            alias_name="${alias_name%% }"
            
            local desc="${prev_line#\# }"
            
            # Alignment (max 18 Zeichen)
            local padding=$((18 - ${#alias_name}))
            [[ "$padding" -lt 1 ]] && padding=1
            local spaces=""
            for ((i=0; i<padding; i++)); do spaces+=" "; done
            
            output+="${alias_name}${spaces}# ${desc}\n"
        fi
        
        # Funktion mit vorheriger Beschreibung: name() {
        if [[ "$trimmed" == [a-z][a-z0-9_-]*"() "* && "$prev_line" == "# "* && "$prev_line" != "# ----"* ]]; then
            local func_name="${trimmed%%\(*}"
            local desc="${prev_line#\# }"
            
            # Alignment (max 18 Zeichen)
            local padding=$((18 - ${#func_name}))
            [[ "$padding" -lt 1 ]] && padding=1
            local spaces=""
            for ((i=0; i<padding; i++)); do spaces+=" "; done
            
            output+="${func_name}${spaces}# ${desc}\n"
        fi
        
        prev_prev_line="$prev_line"
        prev_line="$trimmed"
    done < "$file"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Datei-Vergleich
# ------------------------------------------------------------
# Vergleicht generierten Inhalt mit existierender Datei
# Return: 0 wenn gleich, 1 wenn unterschiedlich
compare_content() {
    local file="$1"
    local content="$2"
    
    [[ ! -f "$file" ]] && return 1
    
    local current=$(cat "$file")
    [[ "$current" == "$content" ]]
}

# ------------------------------------------------------------
# Datei schreiben (nur wenn geändert)
# ------------------------------------------------------------
write_if_changed() {
    local file="$1"
    local content="$2"
    
    if compare_content "$file" "$content"; then
        dim "  Unverändert: $(basename "$file")"
        return 0
    fi
    
    # printf statt echo um trailing newline zu vermeiden
    printf '%s\n' "$content" > "$file"
    ok "Generiert: $(basename "$file")"
    return 0
}
