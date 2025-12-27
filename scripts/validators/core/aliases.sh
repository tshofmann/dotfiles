#!/usr/bin/env zsh
# ============================================================
# aliases.sh - Alias-Dateien Validierung (Anzahlen)
# ============================================================
# Prüft: Alias + Funktions-Anzahlen pro Datei vs tools.md
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_alias_files() {
    log "Prüfe Alias-Dokumentation..."
    
    local alias_dir="$TERMINAL_DIR/.config/alias"
    local tools_doc="$DOCS_DIR/tools.md"
    
    # Bekannte bedingte Aliase (können je nach System variieren)
    local -A conditional_aliases=(
        [homebrew]=1
        [bat]=1
    )
    
    local name base alias_count func_count code_count docs_count tolerance
    for alias_file in "$alias_dir"/*.alias(N); do
        [[ -f "$alias_file" ]] || continue
        
        name=$(basename "$alias_file")
        base=${name%.alias}
        
        # Zähle Aliase und Funktionen
        alias_count=$(grep -cE "^[[:space:]]*alias [a-z]" "$alias_file" 2>/dev/null) || alias_count=0
        func_count=$(grep -cE "^[[:space:]]*[a-z_]+\(\)[[:space:]]*\{" "$alias_file" 2>/dev/null) || func_count=0
        code_count=$((alias_count + func_count))
        
        if grep -q "### ${base}.alias" "$tools_doc" 2>/dev/null; then
            # Zähle dokumentierte Aliase UND Funktionen
            docs_count=$(sed -n "/### ${base}.alias/,/^### /p" "$tools_doc" | grep -cE "^\| \`[a-z]" 2>/dev/null || echo 0)
            tolerance=${conditional_aliases[$base]:-0}
            
            local display_info=""
            [[ "$alias_count" -gt 0 ]] && display_info="$alias_count Aliase"
            [[ "$func_count" -gt 0 ]] && {
                [[ -n "$display_info" ]] && display_info="$display_info + "
                display_info="${display_info}$func_count Funktionen"
            }
            
            if [[ "$code_count" -eq "$docs_count" ]]; then
                ok "$name: $display_info"
            elif [[ "$tolerance" -gt 0 ]] && [[ "$code_count" -le "$((docs_count + tolerance))" ]]; then
                ok "$name: $display_info (inkl. bedingte)"
            else
                err "$name: Code=$code_count ($display_info), Docs=$docs_count"
            fi
        else
            err "$name: Nicht in tools.md dokumentiert"
        fi
    done
}

register_validator "aliases" "check_alias_files" "Alias-Dateien" "core"
