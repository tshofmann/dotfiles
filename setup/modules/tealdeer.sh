#!/usr/bin/env zsh
# ============================================================
# tealdeer.sh - tealdeer (tldr) Cache Konfiguration
# ============================================================
# Zweck       : Lädt tldr-Pages für Offline-Nutzung herunter
# Pfad        : setup/modules/tealdeer.sh
# Benötigt    : _core.sh, homebrew.sh (tealdeer muss installiert sein)
#
# STEP        : tldr Cache | Lädt tldr-Pages herunter | ⚠️ Netzwerk
# Cache       : ~/.cache/tealdeer/
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor tealdeer.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Prüfen ob tealdeer installiert ist
# ------------------------------------------------------------
tealdeer_installed() {
    command -v tldr >/dev/null 2>&1
}

# ------------------------------------------------------------
# Prüfen ob Cache bereits existiert
# ------------------------------------------------------------
cache_exists() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tealdeer"
    [[ -d "$cache_dir/tldr-pages" ]] || [[ -d "$cache_dir/pages" ]]
}

# ------------------------------------------------------------
# tldr Cache aktualisieren
# ------------------------------------------------------------
update_tldr_cache() {
    CURRENT_STEP="tldr Cache"
    
    if ! tealdeer_installed; then
        log "tealdeer nicht installiert – übersprungen"
        return 0
    fi
    
    # Prüfe ob Cache bereits existiert und aktuell ist
    if cache_exists; then
        ok "tldr Cache bereits vorhanden"
        log "Für Update: tldr --update"
        return 0
    fi
    
    log "Lade tldr-Pages herunter (einmalig)..."
    
    if tldr --update 2>/dev/null; then
        ok "tldr Cache heruntergeladen"
    else
        warn "tldr --update fehlgeschlagen (Netzwerk?)"
        log "Später manuell ausführen: tldr --update"
    fi
    
    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_tealdeer() {
    CURRENT_STEP="tealdeer Setup"
    update_tldr_cache
}

# Modul ausführen wenn direkt aufgerufen
if [[ "${(%):-%N}" == "$0" ]]; then
    source "${0:A:h}/_core.sh"
    setup_tealdeer
fi
