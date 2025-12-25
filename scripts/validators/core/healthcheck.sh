#!/usr/bin/env zsh
# ============================================================
# healthcheck.sh - Health-Check Tools Validierung
# ============================================================
# Prüft: health-check.sh Tools vs tools.md
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_healthcheck_tools() {
    log "Prüfe Health-Check Tool-Liste..."
    
    local health_check="$SCRIPTS_DIR/health-check.sh"
    local tools_doc="$DOCS_DIR/tools.md"
    
    # Zähle check_tool Aufrufe
    local tool_count
    tool_count=$(grep -c 'check_tool "' "$health_check" 2>/dev/null || echo 0)
    
    ok "Health-Check prüft $tool_count Tools"
    
    # Prüfe kritische Tools
    local -a critical=(fzf stow starship zoxide eza bat fd btop gh)
    local missing=0
    
    for tool in "${critical[@]}"; do
        if ! grep -q "check_tool \"$tool\"" "$health_check" 2>/dev/null; then
            # Einige haben andere Befehlsnamen
            if [[ "$tool" == "ripgrep" ]] && grep -q 'check_tool "rg"' "$health_check" 2>/dev/null; then
                continue
            fi
            warn "Tool '$tool' nicht in health-check.sh"
            ((missing++)) || true
        fi
    done
    
    if (( missing == 0 )); then
        ok "Alle kritischen Tools werden geprüft"
    fi
}

register_validator "healthcheck" "check_healthcheck_tools" "Health-Check Tools" "core"
