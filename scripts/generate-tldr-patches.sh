#!/usr/bin/env zsh
# ============================================================
# generate-tldr-patches.sh - tldr-Patches aus Code generieren
# ============================================================
# Zweck   : Single Source of Truth – generiert .patch.md aus Code
# Pfad    : scripts/generate-tldr-patches.sh
# Aufruf  : ./scripts/generate-tldr-patches.sh [--check|--generate]
# ============================================================
# Quellen:
#   - .alias Dateien: Funktionen + Beschreibungskommentare
#   - fzf/config: Globale Keybindings
#   - Header-Blöcke: Cross-Referenzen
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"
FZF_CONFIG="$DOTFILES_DIR/terminal/.config/fzf/config"
TEALDEER_DIR="$DOTFILES_DIR/terminal/.config/tealdeer/pages"

# Farben
C_RESET='\033[0m'
C_GREEN='\033[38;2;166;227;161m'
C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'
C_BLUE='\033[38;2;137;180;250m'

# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------
log() { echo -e "${C_BLUE}→${C_RESET} $1"; }
ok() { echo -e "${C_GREEN}✔${C_RESET} $1"; }
err() { echo -e "${C_RED}✖${C_RESET} $1" >&2; }
warn() { echo -e "${C_YELLOW}⚠${C_RESET} $1"; }

# ------------------------------------------------------------
# Parser: Beschreibungskommentar
# ------------------------------------------------------------
# Format: # Name(param?) – Key1=Aktion1, Key2=Aktion2
# Rückgabe: name|param|keybindings
parse_description_comment() {
    local comment="$1"
    local name param keybindings
    
    # Entferne führendes "# "
    comment="${comment#\# }"
    comment="${comment#\#}"
    comment="${comment## }"
    
    # Extrahiere Name (vor Klammer oder Dash)
    if [[ "$comment" == *'('* ]]; then
        name="${comment%%\(*}"
        name="${name%% }"
        # Parameter extrahieren
        local param_part="${comment#*\(}"
        param="${param_part%%\)*}"
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
    
    echo "${name}|${param}|${keybindings}"
}

# ------------------------------------------------------------
# Parser: Keybindings zu tldr-Format
# ------------------------------------------------------------
# Eingabe: Enter=Öffnen, Ctrl+S=man↔tldr
# Ausgabe: (`<Enter>` Öffnen, `<Ctrl s>` man↔tldr)
format_keybindings_for_tldr() {
    local keybindings="$1"
    [[ -z "$keybindings" ]] && return
    
    # Prüfe ob überhaupt Keybindings vorhanden sind (Key=Action Format)
    # Gültige Keys: Enter, Tab, Ctrl+X, Shift+X, Alt+X, Esc
    case "$keybindings" in
        *Enter* | *Tab* | *Ctrl* | *Shift* | *Alt* | *Esc*) ;;
        *) return ;;  # Kein Keybinding-Format, ignorieren
    esac
    
    local result=""
    local IFS=','
    
    for binding in ${=keybindings}; do
        binding="${binding## }"  # Trim
        binding="${binding%% }"
        
        # Nur verarbeiten wenn es ein Key=Action Format ist
        [[ "$binding" != *"="* ]] && continue
        
        local key="${binding%%=*}"
        local action="${binding#*=}"
        
        # Validiere dass key ein gültiger Key ist (einfache Pattern-Prüfung)
        case "$key" in
            Enter | Tab | Esc | Ctrl+* | Shift+* | Alt+*) ;;
            *) continue ;;  # Kein gültiger Key
        esac
        
        # Konvertiere Key-Format: Ctrl+S → Ctrl s (lowercase nach Modifier)
        key="${key//+/ }"
        # Zweiten Teil lowercase machen (nur wenn es ein Buchstabe ist)
        if [[ "$key" == *" "* ]]; then
            local modifier="${key%% *}"
            local letter="${key##* }"
            # Nur Buchstaben lowercase machen
            if [[ "$letter" == [A-Za-z] ]]; then
                key="${modifier} ${(L)letter}"
            else
                key="${modifier} ${letter}"
            fi
        fi
        
        [[ -n "$result" ]] && result+=", "
        result+="\`<${key}>\` ${action}"
    done
    
    [[ -n "$result" ]] && echo "($result)"
}

# ------------------------------------------------------------
# Parser: Parameter zu tldr-Format
# ------------------------------------------------------------
# Eingabe: suche? oder pfad=. oder leer
# Ausgabe: {{suche}} oder {{pfad}} oder leer
format_param_for_tldr() {
    local param="$1"
    [[ -z "$param" ]] && return
    
    # Entferne ? und =default
    param="${param%%\?}"
    param="${param%%=*}"
    
    echo "{{${param}}}"
}

# ------------------------------------------------------------
# Parser: fzf/config globale Keybindings
# ------------------------------------------------------------
# Format in config:
#   # Ctrl+/ : Vorschau ein-/ausblenden
#   --bind=ctrl-/:toggle-preview
parse_fzf_config_keybindings() {
    local config="$1"
    local output=""
    local prev_comment=""
    
    while IFS= read -r line; do
        # Kommentar mit Keybinding-Beschreibung (startet mit # Ctrl oder # Alt)
        if [[ "$line" == "# Ctrl"*":"* || "$line" == "# Alt"*":"* ]]; then
            prev_comment="${line#\# }"
        # --bind Zeile
        elif [[ "$line" == "--bind="* && -n "$prev_comment" ]]; then
            local key="${prev_comment%% :*}"
            local action="${prev_comment#*: }"
            
            # Konvertiere Ctrl+/ → Ctrl / und lowercase (nur Buchstaben)
            key="${key//+/ }"
            if [[ "$key" == *" "* ]]; then
                local modifier="${key%% *}"
                local letter="${key##* }"
                # Nur Buchstaben lowercase, Sonderzeichen behalten
                if [[ "$letter" =~ ^[A-Za-z]+$ ]]; then
                    letter="${(L)letter}"
                fi
                key="${modifier} ${letter}"
            fi
            
            output+="- dotfiles: ${action}:\n\n\`<${key}>\`\n\n"
            prev_comment=""
        else
            prev_comment=""
        fi
    done < "$config"
    
    # Tab ist fzf-default, manuell hinzufügen
    output+="- dotfiles: Einzelnen Eintrag zur Auswahl hinzufügen:\n\n\`<Tab>\`\n\n"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Parser: Shell-Keybindings aus fzf.alias Header
# ------------------------------------------------------------
# Format: # Ctrl+X 1: History durchsuchen mit Vorschau
parse_shell_keybindings() {
    local file="$1"
    local output=""
    local in_section=false
    
    while IFS= read -r line; do
        # Sektion beginnt bei Shell-Keybindings Header (Zeile mit ----)
        if [[ "$line" == *"Shell-Keybindings"* ]]; then
            in_section=true
            continue
        fi
        
        # Trennlinien innerhalb der Sektion überspringen
        [[ "$in_section" == true && "$line" == "# ----"* ]] && continue
        
        # Sektion endet bei ZOXIDE oder nächster benannter Sektion
        [[ "$in_section" == true && "$line" == *"ZOXIDE"* ]] && break
        
        # Keybinding parsen: # Ctrl+X N: Beschreibung
        if [[ "$in_section" == true && "$line" == "# Ctrl+X "* ]]; then
            # Extrahiere: # Ctrl+X 1: History durchsuchen...
            local rest="${line#\# Ctrl+X }"
            local num="${rest%%:*}"
            local desc="${rest#*: }"
            output+="- dotfiles: ${desc}:\n\n\`<Ctrl x> ${num}\`\n\n"
        fi
    done < "$file"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Parser: Cross-Referenzen aus Header-Block
# ------------------------------------------------------------
# Format im Header:
#   #           - fd.alias   → cdf (Verzeichnis), fo (Datei öffnen)
# Ausgabe: fd|cdf,fo
parse_cross_references() {
    local file="$1"
    local output=""
    
    while IFS= read -r line; do
        # Header endet bei Guard
        [[ "$line" == "# Guard"* ]] && break
        
        # Cross-Reference Pattern: "- tool.alias → func1 (desc), func2"
        if [[ "$line" == *".alias"*"→"* ]]; then
            # Extrahiere Tool-Name
            local tool=$(echo "$line" | sed -n 's/.*- \([a-z]*\)\.alias.*/\1/p')
            # Extrahiere alles nach →
            local after_arrow="${line#*→ }"
            # Entferne Beschreibungen in Klammern und trimme
            local funcs=$(echo "$after_arrow" | sed 's/([^)]*)//g' | tr -d ' ')
            
            [[ -n "$tool" && -n "$funcs" ]] && output+="${tool}|${funcs}\n"
        fi
    done < "$file"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Patch für eine .alias Datei
# ------------------------------------------------------------
generate_patch_for_alias() {
    local alias_file="$1"
    local tool_name=$(basename "$alias_file" .alias)
    local output=""
    local prev_comment=""
    local line_num=0
    
    # Sammle Funktionen und ihre Beschreibungen
    while IFS= read -r line; do
        (( line_num++ )) || true
        
        # Kommentar vor Funktion merken
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        if [[ "$trimmed" == \#* && "$trimmed" != \#\ ----* && "$trimmed" != \#\ ====* ]]; then
            # Beschreibungskommentar: # Name(params?) – Keybindings
            # Muss mit "# Wort(" oder "# Wort –" beginnen (ohne : dazwischen)
            # Header-Kommentare haben Format "# Wort   :" und werden übersprungen
            local content="${trimmed#\# }"
            local first_word="${content%% *}"
            # Beschreibungskommentar erkennen: enthält – und beginnt NICHT mit Keyword:
            if [[ "$content" == *" – "* || "$content" == *" - "* ]]; then
                # Header-Keywords ausschließen
                case "$first_word" in
                    Zweck|Hinweis|Pfad|Docs|Guard|Voraussetzung)
                        prev_comment=""
                        ;;
                    *)
                        prev_comment="$trimmed"
                        ;;
                esac
            fi
            continue
        fi
        
        # Funktion gefunden
        if [[ "$trimmed" =~ "^[a-zA-Z][a-zA-Z0-9_-]*\(\) \{" ]]; then
            local func_name="${trimmed%%\(*}"
            
            # Private Funktionen überspringen
            [[ "$func_name" == _* ]] && { prev_comment=""; continue; }
            
            if [[ -n "$prev_comment" ]]; then
                local parsed=$(parse_description_comment "$prev_comment")
                local name="${parsed%%|*}"
                local rest="${parsed#*|}"
                local param="${rest%%|*}"
                local keybindings="${rest#*|}"
                
                local tldr_param=$(format_param_for_tldr "$param")
                local tldr_keys=$(format_keybindings_for_tldr "$keybindings")
                
                output+="- dotfiles: ${name}"
                [[ -n "$tldr_keys" ]] && output+=" ${tldr_keys}"
                output+=":\n\n"
                output+="\`${func_name}"
                [[ -n "$tldr_param" ]] && output+=" ${tldr_param}"
                output+="\`\n\n"
            fi
            
            prev_comment=""
        fi
    done < "$alias_file"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Cross-Referenzen für fzf.patch.md
# ------------------------------------------------------------
generate_cross_references() {
    local fzf_alias="$ALIAS_DIR/fzf.alias"
    local output=""
    
    local refs=$(parse_cross_references "$fzf_alias")
    
    while IFS='|' read -r tool funcs; do
        [[ -z "$tool" ]] && continue
        output+="- dotfiles: Siehe \`tldr ${tool}\` für \`${funcs//,/\`, \`}\`\n"
    done <<< "$refs"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Kompletter Patch für ein Tool
# ------------------------------------------------------------
generate_complete_patch() {
    local tool_name="$1"
    local alias_file="$ALIAS_DIR/${tool_name}.alias"
    local output=""
    
    [[ ! -f "$alias_file" ]] && { err "Alias-Datei nicht gefunden: $alias_file"; return 1; }
    
    # Spezialfall fzf: Globale Keybindings + Shell-Keybindings + Cross-Refs
    if [[ "$tool_name" == "fzf" ]]; then
        output+="# dotfiles: Globale Tastenkürzel (in allen fzf-Dialogen)\n\n"
        output+=$(parse_fzf_config_keybindings "$FZF_CONFIG")
        output+="\n# dotfiles: Funktionen (aus fzf.alias)\n\n"
    fi
    
    # Funktionen aus .alias
    output+=$(generate_patch_for_alias "$alias_file")
    
    # Spezialfall fzf: Shell-Keybindings + Cross-Referenzen
    if [[ "$tool_name" == "fzf" ]]; then
        output+="\n# dotfiles: Shell-Keybindings (Ctrl+X Prefix)\n\n"
        output+=$(parse_shell_keybindings "$alias_file")
        output+="\n# dotfiles: Tool-spezifische fzf-Funktionen\n\n"
        output+=$(generate_cross_references)
    fi
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Hauptlogik
# ------------------------------------------------------------
main() {
    local mode="${1:---check}"
    local errors=0
    
    case "$mode" in
        --check)
            log "Prüfe ob Patches aktuell sind..."
            
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                
                [[ ! -f "$patch_file" ]] && continue
                
                local generated=$(generate_complete_patch "$tool_name")
                local current=$(cat "$patch_file")
                
                if [[ "$generated" != "$current" ]]; then
                    err "${tool_name}.patch.md ist veraltet"
                    (( errors++ )) || true
                else
                    ok "${tool_name}.patch.md ist aktuell"
                fi
            done
            
            if (( errors > 0 )); then
                echo ""
                err "$errors Patch(es) veraltet. Führe './scripts/generate-tldr-patches.sh --generate' aus."
                return 1
            fi
            ;;
            
        --generate)
            log "Generiere Patches..."
            
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                
                local generated=$(generate_complete_patch "$tool_name")
                
                # Nur generieren wenn Inhalt vorhanden ist
                # (mehr als nur Whitespace)
                local trimmed="${generated//[[:space:]]/}"
                if [[ -z "$trimmed" ]]; then
                    # Leere Patch-Datei löschen falls vorhanden
                    [[ -f "$patch_file" ]] && rm "$patch_file"
                    continue
                fi
                
                echo -e "$generated" > "$patch_file"
                ok "Generiert: ${tool_name}.patch.md"
            done
            ;;
            
        *)
            echo "Verwendung: $0 [--check|--generate]"
            echo "  --check    Prüft ob Patches aktuell sind (Default)"
            echo "  --generate Generiert alle Patches neu"
            return 1
            ;;
    esac
}

main "$@"
