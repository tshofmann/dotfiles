#!/usr/bin/env zsh
# ============================================================
# bootstrap.sh - Bootstrap-Schritte Validierung
# ============================================================
# Prüft: CURRENT_STEP vs installation.md
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_bootstrap_steps() {
    log "Prüfe Bootstrap-Schritte..."
    
    local bootstrap="$SETUP_DIR/bootstrap.sh"
    local install_doc="$DOCS_DIR/installation.md"
    
    # Zähle CURRENT_STEP Zuweisungen (ohne Initialisierung)
    local code_step_count
    code_step_count=$(grep -c 'CURRENT_STEP=' "$bootstrap" 2>/dev/null || echo 0)
    # Minus 1 für die Initialisierung
    code_step_count=$((code_step_count - 1))
    
    ok "Bootstrap-Schritte im Code: $code_step_count"
    
    # Prüfe ob kritische Schritte in installation.md dokumentiert sind
    local -a critical_keywords=("Netzwerk" "Homebrew" "Brewfile" "Font" "Terminal" "Starship" "ZSH")
    local missing=0
    
    for keyword in "${critical_keywords[@]}"; do
        if ! grep -qi "$keyword" "$install_doc" 2>/dev/null; then
            warn "Keyword '$keyword' nicht in installation.md"
            ((missing++)) || true
        fi
    done
    
    if (( missing == 0 )); then
        ok "Alle Bootstrap-Schritte in installation.md referenziert"
    fi
}

register_validator "bootstrap" "check_bootstrap_steps" "Bootstrap-Schritte" "core"
