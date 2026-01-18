#!/usr/bin/env zsh
# ============================================================
# stow.sh - GNU Stow Symlink-Konfiguration
# ============================================================
# Zweck       : Verlinkt Konfigurationsdateien via Stow
# Pfad        : setup/modules/stow.sh
# Benötigt    : _core.sh, homebrew.sh (stow muss installiert sein)
#
# STEP        : Stow Symlinks | Verlinkt terminal/ und editor/ Configs | ⚠️ Kritisch
# Packages    : terminal, editor
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor stow.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly STOW_PACKAGES=(terminal editor)

# ------------------------------------------------------------
# Prüfen ob Stow installiert ist
# ------------------------------------------------------------
stow_installed() {
    command -v stow >/dev/null 2>&1
}

# ------------------------------------------------------------
# Stow ausführen
# ------------------------------------------------------------
run_stow() {
    CURRENT_STEP="Stow Symlinks"

    if ! stow_installed; then
        err "stow nicht installiert"
        return 1
    fi

    log "Verlinke Konfigurationsdateien..."

    # Ins dotfiles-Verzeichnis wechseln
    cd "$DOTFILES_DIR" || {
        err "Konnte nicht nach $DOTFILES_DIR wechseln"
        return 1
    }

    # Stow mit --adopt ausführen (übernimmt existierende Dateien)
    # -R = Restow (erst unstow, dann stow)
    if stow --adopt -R "${STOW_PACKAGES[@]}" 2>/dev/null; then
        ok "Symlinks erstellt für: ${STOW_PACKAGES[*]}"
    else
        warn "Stow hatte Probleme – prüfe manuell"
        return 0  # Kein fataler Fehler
    fi

    # Adoptierte Dateien auf Repository-Zustand zurücksetzen
    # (Falls existierende Configs abweichen)
    if git diff --quiet 2>/dev/null; then
        log "Keine adoptierten Änderungen"
    else
        log "Setze adoptierte Dateien auf Repository-Zustand zurück..."
        git reset --hard HEAD >/dev/null 2>&1
        ok "Repository-Zustand wiederhergestellt"
    fi

    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_stow() {
    CURRENT_STEP="Stow Setup"
    run_stow
}

# Modul ausführen wenn direkt aufgerufen
if [[ "${(%):-%N}" == "$0" ]]; then
    source "${0:A:h}/_core.sh"
    setup_stow
fi
