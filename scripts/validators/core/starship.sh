#!/usr/bin/env zsh
# ============================================================
# starship.sh - Starship-Preset Validierung
# ============================================================
# Prüft: STARSHIP_PRESET_DEFAULT vs Docs
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_starship_preset() {
    log "Prüfe Starship-Preset Dokumentation..."
    
    local bootstrap="$SETUP_DIR/bootstrap.sh"
    local config_doc="$DOCS_DIR/configuration.md"
    local arch_doc="$DOCS_DIR/architecture.md"
    
    # Extrahiere Default-Preset aus bootstrap.sh
    local code_preset
    code_preset=$(grep -E '^readonly STARSHIP_PRESET_DEFAULT=' "$bootstrap" 2>/dev/null | sed 's/.*="//' | sed 's/".*//') || true
    
    if [[ -z "$code_preset" ]]; then
        warn "STARSHIP_PRESET_DEFAULT nicht in bootstrap.sh gefunden"
        return 0
    fi
    
    ok "Code-Preset: $code_preset"
    
    # Prüfe configuration.md
    if grep -q "$code_preset" "$config_doc" 2>/dev/null; then
        ok "configuration.md: Preset dokumentiert"
    else
        warn "Preset '$code_preset' nicht in configuration.md erwähnt"
    fi
    
    # Prüfe architecture.md  
    if grep -q "$code_preset" "$arch_doc" 2>/dev/null; then
        ok "architecture.md: Preset dokumentiert"
    else
        warn "Preset '$code_preset' nicht in architecture.md erwähnt"
    fi
}

register_validator "starship" "check_starship_preset" "Starship-Preset" "core"
