#!/usr/bin/env zsh
# ============================================================
# bat.sh - bat Theme-Cache Konfiguration
# ============================================================
# Zweck       : Baut bat Theme-Cache für Catppuccin Mocha
# Pfad        : setup/modules/bat.sh
# Benötigt    : _core.sh, stow.sh (Themes müssen verlinkt sein)
#
# STEP        : bat Cache | Baut Theme-Cache für Syntax-Highlighting | ✓ Schnell
# Theme       : ~/.config/bat/themes/Catppuccin Mocha.tmTheme
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor bat.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Prüfen ob bat installiert ist
# ------------------------------------------------------------
bat_installed() {
    command -v bat >/dev/null 2>&1
}

# ------------------------------------------------------------
# Prüfen ob Theme-Dateien existieren
# ------------------------------------------------------------
themes_exist() {
    local theme_dir="$HOME/.config/bat/themes"
    [[ -d "$theme_dir" ]] && [[ -n "$(ls -A "$theme_dir" 2>/dev/null)" ]]
}

# ------------------------------------------------------------
# bat Cache bauen
# ------------------------------------------------------------
build_bat_cache() {
    CURRENT_STEP="bat Cache"
    
    if ! bat_installed; then
        log "bat nicht installiert – übersprungen"
        return 0
    fi
    
    if ! themes_exist; then
        log "Keine bat Themes gefunden – übersprungen"
        log "Führe zuerst 'stow terminal' aus"
        return 0
    fi
    
    log "Baue bat Theme-Cache..."
    
    if bat cache --build >/dev/null 2>&1; then
        ok "bat Cache gebaut (Catppuccin Mocha aktiv)"
    else
        warn "bat cache --build fehlgeschlagen"
    fi
    
    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_bat() {
    CURRENT_STEP="bat Setup"
    build_bat_cache
}

# Modul ausführen wenn direkt aufgerufen
if [[ "${(%):-%N}" == "$0" ]]; then
    source "${0:A:h}/_core.sh"
    setup_bat
fi
