#!/usr/bin/env zsh
# ============================================================
# keybindings.sh - Keybinding-Konsistenz Validierung
# ============================================================
# Zweck   : Prüft ob --header= im Code mit Doku übereinstimmt
# Pfad    : scripts/validators/extended/keybindings.sh
# ============================================================
# Prüft:
#   1. Keybindings im Code (--header=) → tools.md
#   2. Keybindings im Code (--header=) → .patch.md
#   3. Konsistenz zwischen allen drei Quellen
# ============================================================

# Source lib.sh wenn noch nicht geladen
if [[ -z "${VALIDATOR_LIB_LOADED:-}" ]]; then
    source "${0:A:h:h}/lib.sh"
fi

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
TEALDEER_DIR="$TERMINAL_DIR/.config/tealdeer/pages"

# Mapping: alias-Dateiname → patch-Dateiname
typeset -gA PATCH_NAME_MAP=(
    [homebrew]="brew"
    [ripgrep]="rg"
)

# ------------------------------------------------------------
# Hilfsfunktionen: Keybinding-Normalisierung
# ------------------------------------------------------------

# Normalisiere Keybinding-Format für Vergleich
# Input:  "Ctrl+Y", "<Ctrl y>", "Ctrl-Y", "ctrl+y"
# Output: "ctrl-y"
normalize_keybinding() {
    local kb="$1"
    echo "$kb" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/<//g; s/>//g' | \
        sed 's/ctrl[ +]/ctrl-/g' | \
        sed 's/alt[ +]/alt-/g' | \
        sed 's/shift[ +]/shift-/g' | \
        sed 's/ //g'
}

# Extrahiere Keybindings aus --header= String
# Input:  "Enter: Wechseln | Ctrl+D: Löschen | Ctrl+Y: Kopieren"
# Output: Array von normalisierten Keys: (enter ctrl-d ctrl-y)
extract_keys_from_header() {
    local header="$1"
    local -a keys=()
    
    # Splitte bei | und extrahiere Keys
    echo "$header" | tr '|' '\n' | while read -r part; do
        # Extrahiere den Key-Teil (vor dem :)
        local key=$(echo "$part" | sed 's/:.*//' | xargs)
        [[ -n "$key" ]] && keys+=($(normalize_keybinding "$key"))
    done
    
    echo "${keys[@]}"
}

# Extrahiere Keybindings für eine Funktion aus tools.md
# Sucht nach Zeilen wie: | `func` | ... Ctrl+Y=..., Ctrl+D=... |
extract_keys_from_tools_md() {
    local func="$1"
    local file="$DOCS_DIR/tools.md"
    local -a keys=()
    
    # Suche Zeile mit der Funktion in Backticks
    local line=$(grep -E "^\|[^|]*\`${func}\`" "$file" 2>/dev/null | head -1)
    [[ -z "$line" ]] && { echo ""; return; }
    
    # Extrahiere alle Ctrl+X, Alt+X, Enter, Tab Patterns
    local matches=$(echo "$line" | grep -oE '(Ctrl\+[A-Za-z]|Alt\+[A-Za-z]|Enter|Tab)' | sort -u)
    
    for match in ${(f)matches}; do
        keys+=($(normalize_keybinding "$match"))
    done
    
    echo "${keys[@]}"
}

# Extrahiere Keybindings für eine Funktion aus .patch.md
# Sucht nach: - dotfiles: ... (`<Ctrl d>` ..., `<Ctrl y>` ...):
extract_keys_from_patch() {
    local func="$1"
    local patch_base="$2"
    local file="$TEALDEER_DIR/${patch_base}.patch.md"
    local -a keys=()
    
    [[ ! -f "$file" ]] && { echo ""; return; }
    
    # Suche Zeile vor dem Funktionsaufruf
    local line=$(grep -B1 "^\`${func}" "$file" 2>/dev/null | head -1)
    [[ -z "$line" ]] && { echo ""; return; }
    
    # Extrahiere alle <Ctrl x>, <Alt x>, Enter, Tab Patterns
    local matches=$(echo "$line" | grep -oE '(<Ctrl [a-z]>|<Alt [a-z]>|Enter|Tab)' | sort -u)
    
    for match in ${(f)matches}; do
        keys+=($(normalize_keybinding "$match"))
    done
    
    echo "${keys[@]}"
}

# ------------------------------------------------------------
# Hauptvalidierung
# ------------------------------------------------------------
validate_keybindings() {
    local errors=0
    
    section "Keybinding-Konsistenz"
    log "Prüfe Keybindings in Code vs. Dokumentation..."
    
    # Durchsuche alle .alias Dateien nach --header=
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local base=$(basename "$alias_file" .alias)
        local patch_name="${PATCH_NAME_MAP[$base]:-$base}"
        
        # Finde alle Funktionen in dieser Datei
        local -a functions=($(extract_functions_from_file "$alias_file" | grep -v "^_"))
        
        for func in "${functions[@]}"; do
            # Extrahiere Funktionsblock - flexibel für eingerückte Funktionen
            # Suche von "func() {" bis zur schließenden "}"
            local func_block=$(awk "/[[:space:]]*${func}\(\)[[:space:]]*\{/,/^[[:space:]]*\}/" "$alias_file" 2>/dev/null)
            
            # Suche --header= im Block
            local header_line=$(echo "$func_block" | grep -o -- "--header='[^']*'" | head -1)
            [[ -z "$header_line" ]] && continue
            
            # Extrahiere Header-Inhalt
            local header=$(echo "$header_line" | sed "s/--header='//;s/'$//")
            
            # Extrahiere Keys aus Header (Ctrl+X, Alt+X)
            local -a code_keys=()
            local code_ctrl_keys=$(echo "$header" | grep -oE 'Ctrl\+[A-Za-z]' | tr '[:upper:]' '[:lower:]' | sed 's/ctrl+/ctrl-/' | sort -u)
            local code_alt_keys=$(echo "$header" | grep -oE 'Alt\+[A-Za-z]' | tr '[:upper:]' '[:lower:]' | sed 's/alt+/alt-/' | sort -u)
            for k in ${(f)code_ctrl_keys} ${(f)code_alt_keys}; do
                [[ -n "$k" ]] && code_keys+=("$k")
            done
            
            # Extrahiere Keys aus tools.md
            local -a docs_keys=()
            local docs_line=$(grep -E "^\|[^|]*\`${func}\`" "$DOCS_DIR/tools.md" 2>/dev/null | head -1)
            if [[ -n "$docs_line" ]]; then
                local docs_ctrl_keys=$(echo "$docs_line" | grep -oE 'Ctrl\+[A-Za-z]' | tr '[:upper:]' '[:lower:]' | sed 's/ctrl+/ctrl-/' | sort -u)
                local docs_alt_keys=$(echo "$docs_line" | grep -oE 'Alt\+[A-Za-z]' | tr '[:upper:]' '[:lower:]' | sed 's/alt+/alt-/' | sort -u)
                for k in ${(f)docs_ctrl_keys} ${(f)docs_alt_keys}; do
                    [[ -n "$k" ]] && docs_keys+=("$k")
                done
            fi
            
            # Extrahiere Keys aus .patch.md
            local patch_file="$TEALDEER_DIR/${patch_name}.patch.md"
            local -a patch_keys=()
            if [[ -f "$patch_file" ]]; then
                # Format: "- dotfiles: ... (`<Ctrl x>` ...):"; dann Leerzeile; dann "`befehl`"
                local patch_line=$(grep -B2 "^\`${func}\`\$" "$patch_file" 2>/dev/null | head -1)
                if [[ -n "$patch_line" ]]; then
                    local patch_ctrl_keys=$(echo "$patch_line" | grep -oE '<Ctrl [a-z]>' | tr '[:upper:]' '[:lower:]' | sed 's/<ctrl /ctrl-/;s/>//' | sort -u)
                    local patch_alt_keys=$(echo "$patch_line" | grep -oE '<Alt [a-z]>' | tr '[:upper:]' '[:lower:]' | sed 's/<alt /alt-/;s/>//' | sort -u)
                    for k in ${(f)patch_ctrl_keys} ${(f)patch_alt_keys}; do
                        [[ -n "$k" ]] && patch_keys+=("$k")
                    done
                fi
            fi
            
            # Vergleiche Code vs tools.md
            if [[ -n "${docs_line:-}" ]]; then
                for key in "${code_keys[@]}"; do
                    if [[ ! " ${docs_keys[*]} " =~ " ${key} " ]]; then
                        err "$func: Keybinding '$key' fehlt in tools.md"
                        (( errors++ )) || true
                    fi
                done
            fi
            
            # Vergleiche Code vs .patch.md
            if [[ -n "${patch_line:-}" ]]; then
                for key in "${code_keys[@]}"; do
                    if [[ ! " ${patch_keys[*]} " =~ " ${key} " ]]; then
                        err "$func: Keybinding '$key' fehlt in ${patch_name}.patch.md"
                        (( errors++ )) || true
                    fi
                done
            fi
        done
    done
    
    if (( errors == 0 )); then
        ok "Alle Keybindings sind konsistent dokumentiert"
    fi
    
    return $errors
}

# Registrierung
register_validator "keybindings" "validate_keybindings" "Keybinding-Konsistenz" "extended"
