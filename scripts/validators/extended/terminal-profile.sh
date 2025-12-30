#!/usr/bin/env zsh
# ============================================================
# terminal-profile.sh - Terminal-Profil Konsistenz Validierung
# ============================================================
# Prüft: PROFILE_NAME in bootstrap.sh = health-check.sh = Doku
# Verhindert Drift zwischen Code und Dokumentation
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_terminal_profile() {
    log "Prüfe Terminal-Profil Konsistenz..."
    
    local errors=0
    local bootstrap="$DOTFILES_DIR/setup/bootstrap.sh"
    local healthcheck="$DOTFILES_DIR/scripts/health-check.sh"
    
    # 1. PROFILE_NAME aus bootstrap.sh extrahieren
    local code_name
    code_name=$(grep -E '^readonly PROFILE_NAME=' "$bootstrap" 2>/dev/null | cut -d'"' -f2)
    
    if [[ -z "$code_name" ]]; then
        err "PROFILE_NAME nicht in bootstrap.sh gefunden"
        return 1
    fi
    
    # 2. Profil-Datei existiert?
    local profile_file="$DOTFILES_DIR/setup/${code_name}.terminal"
    if [[ ! -f "$profile_file" ]]; then
        err "Profil-Datei nicht gefunden: setup/${code_name}.terminal"
        (( errors++ )) || true
    fi
    
    # 3. Health-Check verwendet gleichen Namen?
    local healthcheck_name
    healthcheck_name=$(grep -E '^profile_name=' "$healthcheck" 2>/dev/null | cut -d'"' -f2)
    
    if [[ -z "$healthcheck_name" ]]; then
        err "profile_name nicht in health-check.sh gefunden"
        (( errors++ )) || true
    elif [[ "$code_name" != "$healthcheck_name" ]]; then
        err "Health-Check verwendet '$healthcheck_name', erwartet '$code_name'"
        (( errors++ )) || true
    fi
    
    # 4. Dokumentation prüfen - veraltete Referenzen finden
    # Suche nach tshofmann (außer in URLs wie github.com/tshofmann)
    local -a doc_files=("$DOTFILES_DIR/docs"/*.md "$DOTFILES_DIR/CONTRIBUTING.md")
    local old_refs=0
    local old_ref_file
    
    for doc in "${doc_files[@]}"; do
        [[ ! -f "$doc" ]] && continue
        # Filtere GitHub-URLs heraus und zähle restliche Treffer
        local actual_count=0
        actual_count=$(grep "tshofmann" "$doc" 2>/dev/null | grep -v "github.com/tshofmann" | wc -l | tr -d ' ') || true
        (( actual_count > 0 )) && {
            old_ref_file="${doc##*/}"
            err "Veraltete 'tshofmann' Referenz in $old_ref_file ($actual_count Stellen)"
            (( old_refs += actual_count )) || true
        }
    done
    
    if (( old_refs > 0 )); then
        (( errors++ )) || true
    fi
    
    # 5. Ergebnis
    if (( errors == 0 )); then
        ok "Terminal-Profil konsistent: $code_name"
        return 0
    else
        return 1
    fi
}

register_validator "terminal-profile" "check_terminal_profile" "Terminal-Profil Konsistenz"
