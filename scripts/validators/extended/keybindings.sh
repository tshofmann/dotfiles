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
# Validierung: Shell-Keybindings (init.zsh)
# ------------------------------------------------------------
validate_shell_keybindings() {
    local init_zsh="$TERMINAL_DIR/.config/fzf/init.zsh"
    local tools_md="$DOCS_DIR/tools.md"
    local patch_md="$TEALDEER_DIR/fzf.patch.md"
    local errors=0
    
    [[ -f "$init_zsh" ]] || { debug "init.zsh nicht gefunden, überspringe"; return 0; }
    
    # Extrahiere Keybindings aus init.zsh (bindkey '^X1' ...)
    local -a code_keys=()
    while IFS= read -r line; do
        # Extrahiere Nummer nach ^X aus bindkey-Zeilen (nicht -r)
        if [[ "$line" == bindkey\ * ]] && [[ "$line" != *"-r"* ]] && [[ "$line" == *"^X"* ]]; then
            local num=$(echo "$line" | grep -oE '\^X[0-9]' | sed 's/\^X//')
            [[ -n "$num" ]] && code_keys+=("Ctrl+X $num")
        fi
    done < "$init_zsh"
    
    # Extrahiere Keybindings aus tools.md (Shell-Keybindings Sektion)
    local -a docs_keys=()
    local in_shell_kb_section=false
    while IFS= read -r line; do
        if [[ "$line" == *"Shell-Keybindings"* ]]; then
            in_shell_kb_section=true
            continue
        fi
        if $in_shell_kb_section && [[ "$line" == "**"* ]] && [[ "$line" != *"Shell-Keybindings"* ]]; then
            break
        fi
        if $in_shell_kb_section && [[ "$line" == "| \`Ctrl+X"* ]]; then
            local kb=$(echo "$line" | sed 's/^| `//' | sed 's/`.*//')
            docs_keys+=("$kb")
        fi
    done < "$tools_md"
    
    # Extrahiere aus fzf.patch.md
    local -a patch_keys=()
    while IFS= read -r line; do
        if [[ "$line" =~ \<Ctrl\ x\>\ ([0-9]) ]]; then
            patch_keys+=("Ctrl+X ${match[1]}")
        fi
    done < "$patch_md"
    
    # Hilfsfunktion: Prüfe ob Element in Array enthalten ist
    __in_array() {
        local needle="$1"
        shift
        local item
        for item in "$@"; do
            [[ "$item" == "$needle" ]] && return 0
        done
        return 1
    }
    
    # Validiere: Code → Docs
    for key in "${code_keys[@]}"; do
        if ! __in_array "$key" "${docs_keys[@]}"; then
            err "Shell-Keybinding '$key' aus init.zsh fehlt in tools.md"
            (( errors++ )) || true
        fi
    done
    
    # Validiere: Docs → Code
    for key in "${docs_keys[@]}"; do
        if ! __in_array "$key" "${code_keys[@]}"; then
            err "Shell-Keybinding '$key' in tools.md existiert nicht in init.zsh"
            (( errors++ )) || true
        fi
    done
    
    # Validiere: Code → Patch
    for key in "${code_keys[@]}"; do
        if ! __in_array "$key" "${patch_keys[@]}"; then
            err "Shell-Keybinding '$key' aus init.zsh fehlt in fzf.patch.md"
            (( errors++ )) || true
        fi
    done
    
    if (( errors == 0 )) && (( ${#code_keys[@]} > 0 )); then
        ok "Shell-Keybindings (init.zsh): ${#code_keys[@]} validiert"
    fi
    
    return $errors
}

# ------------------------------------------------------------
# Hauptvalidierung
# ------------------------------------------------------------
validate_keybindings() {
    # Deaktiviere errexit lokal für diese Funktion (grep gibt Exit 1 bei no-match)
    setopt localoptions noerrexit
    
    local errors=0
    
    # Validiere Shell-Keybindings zuerst
    validate_shell_keybindings
    (( errors += $? )) || true
    
    log "Prüfe Keybindings in Code vs. Dokumentation..."
    
    # Durchsuche alle .alias Dateien
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local base=$(basename "$alias_file" .alias)
        local patch_file="$TEALDEER_DIR/${base}.patch.md"
        
        # Finde alle Funktionen (keine privaten mit _)
        local -a functions=($(extract_functions_from_file "$alias_file" | grep -v "^_"))
        
        for func in "${functions[@]}"; do
            # Extrahiere Funktionsblock mit korrektem Brace-Counting
            # Extrahiere Funktionsblock - einfacherer Ansatz:
            # Start: Zeile mit "funcname() {" am Anfang
            # Ende: Zeile die nur "}" enthält (auf gleicher Einrückungsebene)
            local func_block=$(awk -v fn="$func" '
                BEGIN { 
                    gsub(/[.^$*+?(){}|]/, "\\\\&", fn)
                    in_func = 0
                    start_indent = ""
                    pattern = "^([[:space:]]*)" fn "\\(\\)[[:space:]]*\\{"
                }
                match($0, pattern) {
                    in_func = 1
                    # Speichere Einrückung der Funktionsdefinition
                    start_indent = ""
                    for (i = 1; i <= length($0); i++) {
                        c = substr($0, i, 1)
                        if (c == " " || c == "\t") start_indent = start_indent c
                        else break
                    }
                    print
                    next
                }
                in_func {
                    print
                    # Ende: Zeile ist nur "}" mit gleicher oder weniger Einrückung
                    if ($0 ~ "^" start_indent "\\}[[:space:]]*$") {
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
            
            # Extrahiere --bind Keys aus dem Funktionsblock (ctrl-x, alt-x)
            local -a bind_keys=()
            local bind_ctrl=$(echo "$func_block" | grep -oE "bind.*ctrl-[a-z]" | grep -oE "ctrl-[a-z]" | sort -u)
            local bind_alt=$(echo "$func_block" | grep -oE "bind.*alt-[a-z]" | grep -oE "alt-[a-z]" | sort -u)
            for k in ${(f)bind_ctrl} ${(f)bind_alt}; do
                [[ -n "$k" ]] && bind_keys+=("$k")
            done
            
            # PRÜFUNG 0: --bind Keys müssen im --header dokumentiert sein
            if (( ${#bind_keys[@]} > 0 )); then
                if [[ -z "$header" ]]; then
                    err "$func: Hat --bind Keybindings aber keinen --header"
                    for key in "${bind_keys[@]}"; do
                        print "   ${RED}→${NC} $key undokumentiert"
                    done
                    (( errors++ )) || true
                    continue
                fi
                
                # Normalisiere Header-Keys für Vergleich
                local header_normalized=$(echo "$header" | tr '[:upper:]' '[:lower:]' | sed 's/ctrl+/ctrl-/g; s/alt+/alt-/g')
                
                for key in "${bind_keys[@]}"; do
                    if [[ ! "$header_normalized" =~ "$key" ]]; then
                        err "$func: --bind '$key' fehlt im --header"
                        (( errors++ )) || true
                    fi
                done
            fi
            
            # PRÜFUNG 1: fzf-Funktion ohne --header (nur wenn keine bind-keys gefunden)
            if $uses_fzf && [[ -z "$header" ]] && (( ${#bind_keys[@]} == 0 )); then
                # Keine Keybindings, kein Header – das ist OK (z.B. einfache Auswahl)
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
                        err "$func: Keybinding '$key' aus Code fehlt in ${base}.patch.md"
                        (( errors++ )) || true
                    fi
                done
            fi
            
            # PRÜFUNG 5: .patch.md → Code
            if [[ -n "$patch_line" ]]; then
                for key in "${patch_keys[@]}"; do
                    if [[ ! " ${code_keys[*]} " =~ " ${key} " ]]; then
                        err "$func: Keybinding '$key' in ${base}.patch.md existiert nicht im Code"
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
