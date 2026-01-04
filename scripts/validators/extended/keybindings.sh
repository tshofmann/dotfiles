#!/usr/bin/env zsh
# ============================================================
# keybindings.sh - Keybinding-Konsistenz Validierung
# ============================================================
# Zweck   : Prüft ob --header= im Code mit Doku übereinstimmt
# Pfad    : scripts/validators/extended/keybindings.sh
# ============================================================
# Prüft:
#   1. Alle fzf-Funktionen mit --bind haben --header
#   2. Ctrl+X/Alt+X Keybindings: Code ↔ tools.md (bidirektional)
#   3. Ctrl+X/Alt+X Keybindings: Code ↔ .patch.md (bidirektional)
# Hinweis:
#   Enter und Tab werden nicht geprüft (Standard-Keys, implizit)
# ============================================================

# Source lib.sh wenn noch nicht geladen
if [[ -z "${VALIDATOR_LIB_LOADED:-}" ]]; then
    source "${0:A:h:h}/lib.sh"
fi

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
TEALDEER_DIR="$TERMINAL_DIR/.config/tealdeer/pages"

# Alle relevanten Keybinding-Patterns
# Format im Code: "Enter: ...", "Ctrl+D: ...", "Tab: ..."
# Format in tools.md: "Enter=...", "Ctrl+D=...", "Tab=..."
# Format in patch.md: "<Enter>", "<Ctrl d>", "<Tab>"
KEYBINDING_PATTERNS='(Ctrl\+[A-Za-z]|Alt\+[A-Za-z]|Enter|Tab)'

# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------

# Normalisiere Keybinding-Format für Vergleich
# Input:  "Ctrl+Y", "<Ctrl y>", "ctrl-y", "ENTER"
# Output: "ctrl-y" oder "enter"
normalize_keybinding() {
    local kb="$1"
    echo "$kb" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/<//g; s/>//g' | \
        sed 's/ctrl[ +]/ctrl-/g' | \
        sed 's/alt[ +]/alt-/g' | \
        sed 's/ //g'
}

# Extrahiere alle Keys aus einem String (Ctrl+X, Alt+X, Enter, Tab)
# Input:  "Enter: Wechseln | Ctrl+D: Löschen | Tab: Mehrfach"
# Output: "enter ctrl-d tab"
# Parameter: $2 = "all" für alle Keys, sonst nur Ctrl+X/Alt+X (Standard)
__extract_all_keys() {
    local text="$1"
    local mode="${2:-special}"  # "all" oder "special" (default)
    local -a keys=()
    
    # Ctrl+X und Alt+X (immer)
    local ctrl_keys=$(echo "$text" | grep -oE 'Ctrl\+[A-Za-z]' | tr '[:upper:]' '[:lower:]' | sed 's/ctrl+/ctrl-/' | sort -u)
    local alt_keys=$(echo "$text" | grep -oE 'Alt\+[A-Za-z]' | tr '[:upper:]' '[:lower:]' | sed 's/alt+/alt-/' | sort -u)
    
    for k in ${(f)ctrl_keys} ${(f)alt_keys}; do
        [[ -n "$k" ]] && keys+=("$k")
    done
    
    # Enter und Tab nur wenn mode="all" (für Vollständigkeitsprüfung)
    if [[ "$mode" == "all" ]]; then
        local enter_key=$(echo "$text" | grep -oE '\bEnter\b' | tr '[:upper:]' '[:lower:]' | sort -u)
        local tab_key=$(echo "$text" | grep -oE '\bTab\b' | tr '[:upper:]' '[:lower:]' | sort -u)
        for k in ${(f)enter_key} ${(f)tab_key}; do
            [[ -n "$k" ]] && keys+=("$k")
        done
    fi
    
    echo "${keys[@]}"
}

# Extrahiere Keys aus patch.md (Format: <Ctrl x>, <Enter>, <Tab>)
# Input:  "... (`<Ctrl d>` Löschen, `<Enter>` Wechseln):"
# Output: "ctrl-d enter"
# Parameter: $2 = "all" für alle Keys, sonst nur Ctrl+X/Alt+X (Standard)
__extract_patch_keys() {
    local text="$1"
    local mode="${2:-special}"
    local -a keys=()
    
    # Ctrl+X und Alt+X (immer) – [A-Za-z] für Groß- und Kleinbuchstaben
    local ctrl_keys=$(echo "$text" | grep -oE '<Ctrl [A-Za-z]>' | tr '[:upper:]' '[:lower:]' | sed 's/<ctrl /ctrl-/;s/>//' | sort -u)
    local alt_keys=$(echo "$text" | grep -oE '<Alt [A-Za-z]>' | tr '[:upper:]' '[:lower:]' | sed 's/<alt /alt-/;s/>//' | sort -u)
    
    for k in ${(f)ctrl_keys} ${(f)alt_keys}; do
        [[ -n "$k" ]] && keys+=("$k")
    done
    
    # Enter und Tab nur wenn mode="all"
    if [[ "$mode" == "all" ]]; then
        local enter_key=$(echo "$text" | grep -oE '<Enter>' | tr '[:upper:]' '[:lower:]' | sed 's/<//;s/>//' | sort -u)
        local tab_key=$(echo "$text" | grep -oE '<Tab>' | tr '[:upper:]' '[:lower:]' | sed 's/<//;s/>//' | sort -u)
        for k in ${(f)enter_key} ${(f)tab_key}; do
            [[ -n "$k" ]] && keys+=("$k")
        done
    fi
    
    echo "${keys[@]}"
}

# ------------------------------------------------------------
# Hauptvalidierung
# ------------------------------------------------------------
validate_keybindings() {
    # Deaktiviere errexit lokal für diese Funktion (grep gibt Exit 1 bei no-match)
    setopt localoptions noerrexit
    
    local errors=0
    
    section "Keybinding-Konsistenz"
    log "Prüfe Keybindings in Code vs. Dokumentation..."
    
    # Durchsuche alle .alias Dateien
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local base=$(basename "$alias_file" .alias)
        local patch_file="$TEALDEER_DIR/${base}.patch.md"
        
        # Finde alle Funktionen (keine privaten mit _)
        local -a functions=($(extract_functions_from_file "$alias_file" | grep -v "^_"))
        
        for func in "${functions[@]}"; do
            # Extrahiere Funktionsblock mit korrektem Brace-Counting
            # (unterstützt verschachtelte Funktionen wie _fenv_colorize in fenv)
            local func_block=$(awk -v fn="$func" '
                BEGIN { 
                    gsub(/[.^$*+?(){}|]/, "\\\\&", fn)
                    in_func = 0
                    brace_count = 0
                }
                $0 ~ fn"\\(\\)[[:space:]]*\\{" {
                    in_func = 1
                    brace_count = 1
                    print
                    next
                }
                in_func {
                    # Zähle öffnende und schließende Klammern
                    for (i = 1; i <= length($0); i++) {
                        c = substr($0, i, 1)
                        if (c == "{") brace_count++
                        if (c == "}") brace_count--
                    }
                    print
                    if (brace_count <= 0) {
                        in_func = 0
                        exit
                    }
                }
            ' "$alias_file" 2>/dev/null)
            
            # Prüfe ob Funktion fzf verwendet (|| true für set -e Kompatibilität)
            local uses_fzf=false
            if echo "$func_block" | grep -q 'fzf'; then
                uses_fzf=true
            fi
            
            # Suche --header= im Block
            local header_line=$(echo "$func_block" | grep -o -- "--header='[^']*'" | head -1 || true)
            local header=""
            [[ -n "$header_line" ]] && header=$(echo "$header_line" | sed "s/--header='//;s/'$//")
            
            # PRÜFUNG 1: fzf-Funktion ohne --header
            if $uses_fzf && [[ -z "$header" ]]; then
                # Prüfe ob es --bind Aktionen gibt (dann sollte Header existieren)
                if echo "$func_block" | grep -qE -- "--bind '[[:space:]]*(enter|ctrl|alt)"; then
                    err "$func: fzf-Funktion mit Keybindings aber ohne --header"
                    (( errors++ )) || true
                fi
                continue
            fi
            
            [[ -z "$header" ]] && continue
            
            # Extrahiere Keys aus Code-Header
            local -a code_keys=($(__extract_all_keys "$header"))
            
            # Extrahiere Keys aus tools.md (suche | `func` | exakt mit schließendem Backtick)
            local docs_line=$(grep -F "\`${func}\`" "$DOCS_DIR/tools.md" 2>/dev/null | grep -E '^\|' | head -1)
            local -a docs_keys=()
            [[ -n "$docs_line" ]] && docs_keys=($(__extract_all_keys "$docs_line"))
            
            # Extrahiere Keys aus .patch.md
            local patch_line=""
            local -a patch_keys=()
            if [[ -f "$patch_file" ]]; then
                patch_line=$(grep -F "\`${func}\`" "$patch_file" 2>/dev/null | head -n1 | xargs -I{} grep -B2 -F "{}" "$patch_file" | head -1)
                [[ -n "$patch_line" ]] && patch_keys=($(__extract_patch_keys "$patch_line"))
            fi
            
            # PRÜFUNG 2: Code → tools.md (alle Code-Keys müssen in Doku sein)
            if [[ -n "$docs_line" ]]; then
                for key in "${code_keys[@]}"; do
                    if [[ ! " ${docs_keys[*]} " =~ " ${key} " ]]; then
                        err "$func: Keybinding '$key' aus Code fehlt in tools.md"
                        (( errors++ )) || true
                    fi
                done
            fi
            
            # PRÜFUNG 3: tools.md → Code (alle Doku-Keys müssen im Code sein)
            if [[ -n "$docs_line" ]]; then
                for key in "${docs_keys[@]}"; do
                    if [[ ! " ${code_keys[*]} " =~ " ${key} " ]]; then
                        err "$func: Keybinding '$key' in tools.md existiert nicht im Code"
                        (( errors++ )) || true
                    fi
                done
            fi
            
            # PRÜFUNG 4: Code → .patch.md
            if [[ -n "$patch_line" ]]; then
                for key in "${code_keys[@]}"; do
                    if [[ ! " ${patch_keys[*]} " =~ " ${key} " ]]; then
                        err "$func: Keybinding '$key' aus Code fehlt in ${patch_name}.patch.md"
                        (( errors++ )) || true
                    fi
                done
            fi
            
            # PRÜFUNG 5: .patch.md → Code
            if [[ -n "$patch_line" ]]; then
                for key in "${patch_keys[@]}"; do
                    if [[ ! " ${code_keys[*]} " =~ " ${key} " ]]; then
                        err "$func: Keybinding '$key' in ${patch_name}.patch.md existiert nicht im Code"
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
