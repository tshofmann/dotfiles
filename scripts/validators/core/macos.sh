#!/usr/bin/env zsh
# ============================================================
# macos.sh - macOS Versions-Validierung
# ============================================================
# Prüft: macOS Mindestversion in Code vs Docs
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_macos_version() {
    log "Prüfe macOS Versionsangaben..."
    
    local bootstrap="$SETUP_DIR/bootstrap.sh"
    local install_doc="$DOCS_DIR/installation.md"
    local readme="$DOTFILES_DIR/README.md"
    
    # Extrahiere MACOS_MIN_VERSION aus bootstrap.sh
    local code_version
    code_version=$(grep -E '^readonly MACOS_MIN_VERSION=' "$bootstrap" 2>/dev/null | sed 's/.*=//') || true
    
    if [[ -z "$code_version" ]]; then
        warn "MACOS_MIN_VERSION nicht in bootstrap.sh gefunden"
        return 0
    fi
    
    # Prüfe installation.md
    if grep -qE "macOS ${code_version}(\+| |\))" "$install_doc" 2>/dev/null; then
        ok "installation.md: macOS $code_version+"
    else
        err "installation.md: macOS Version stimmt nicht (erwartet: $code_version)"
    fi
    
    # Prüfe README.md
    if grep -qE "macOS ${code_version}(\+| |\))" "$readme" 2>/dev/null; then
        ok "README.md: macOS $code_version+"
    else
        err "README.md: macOS Version stimmt nicht (erwartet: $code_version)"
    fi
}

register_validator "macos" "check_macos_version" "macOS Version" "core"
