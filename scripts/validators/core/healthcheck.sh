#!/usr/bin/env zsh
# ============================================================
# healthcheck.sh - Health-Check Tools Validierung
# ============================================================
# Prüft: health-check.sh verwendet dynamische Erkennung
#        und alle Brewfile-Tools werden geprüft
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_healthcheck_tools() {
    log "Prüfe Health-Check Tool-Liste..."
    
    local health_check="$SCRIPTS_DIR/health-check.sh"
    local brewfile="$SETUP_DIR/Brewfile"
    
    # Prüfe ob health-check.sh dynamisch arbeitet (get_tools_from_brewfile)
    if grep -q 'get_tools_from_brewfile' "$health_check" 2>/dev/null; then
        ok "Health-Check verwendet dynamische Brewfile-Erkennung"
    else
        warn "Health-Check nutzt keine dynamische Erkennung"
        return
    fi
    
    # Extrahiere Tools aus Brewfile (gleiche Logik wie health-check.sh)
    local -a tools=($(grep -E '^brew "[^"]+"' "$brewfile" | \
        sed 's/brew "\([^"]*\)".*/\1/' | \
        grep -v 'zsh-syntax-highlighting\|zsh-autosuggestions'))
    
    ok "Brewfile enthält ${#tools[@]} CLI-Tools (werden dynamisch geprüft)"
    
    # Prüfe dass das Mapping für ripgrep existiert
    if grep -q '\[ripgrep\]=rg' "$health_check" 2>/dev/null; then
        ok "Tool-Mapping für ripgrep → rg vorhanden"
    else
        warn "Tool-Mapping für ripgrep fehlt"
    fi
}

register_validator "healthcheck" "check_healthcheck_tools" "Health-Check Tools" "core"
