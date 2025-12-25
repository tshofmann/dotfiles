#!/usr/bin/env zsh
# ============================================================
# aliases.sh - Alias-Dateien Validierung (Anzahlen)
# ============================================================
# Prüft: Alias-Anzahlen pro Datei vs tools.md
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_alias_files() {
    log "Prüfe Alias-Dokumentation..."
    
    local alias_dir="$TERMINAL_DIR/.config/alias"
    local tools_doc="$DOCS_DIR/tools.md"
    
    # Bekannte bedingte Aliase
    local -A conditional_aliases=(
        [homebrew]=1
        [bat]=1
    )
    
    local name base code_count docs_count tolerance
    for alias_file in "$alias_dir"/*.alias(N); do
        [[ -f "$alias_file" ]] || continue
        
        name=$(basename "$alias_file")
        base=${name%.alias}
        
        # fzf.alias enthält Funktionen
        if [[ "$base" == "fzf" ]]; then
            code_count=$(grep -cE "^[a-z]+\(\)[[:space:]]*\{" "$alias_file" 2>/dev/null || echo 0)
            ok "$name: $code_count Funktionen"
            continue
        fi
        
        # Zähle Aliase
        code_count=$(grep -cE "^[[:space:]]*alias [a-z]" "$alias_file" 2>/dev/null || echo 0)
        
        if grep -q "### ${base}.alias" "$tools_doc" 2>/dev/null; then
            docs_count=$(sed -n "/### ${base}.alias/,/^### /p" "$tools_doc" | grep -cE "^\| \`[a-z]" 2>/dev/null || echo 0)
            tolerance=${conditional_aliases[$base]:-0}
            
            if [[ "$code_count" -eq "$docs_count" ]]; then
                ok "$name: $code_count Aliase"
            elif [[ "$tolerance" -gt 0 ]] && [[ "$code_count" -eq "$((docs_count + tolerance))" ]]; then
                ok "$name: $code_count Aliase (inkl. $tolerance bedingte)"
            else
                err "$name: Code=$code_count, Docs=$docs_count"
            fi
        else
            err "$name: Nicht in tools.md dokumentiert"
        fi
    done
}

register_validator "aliases" "check_alias_files" "Alias-Dateien" "core"
