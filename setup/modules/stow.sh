#!/usr/bin/env zsh
# ============================================================
# stow.sh - GNU Stow Symlink-Konfiguration
# ============================================================
# Zweck       : Verlinkt Konfigurationsdateien via Stow
# Pfad        : setup/modules/stow.sh
# Benötigt    : _core.sh, backup.sh, homebrew.sh (stow muss installiert sein)
#
# STEP        : Stow Symlinks | Verlinkt Dotfile-Packages dynamisch | ⚠️ Kritisch
# Packages    : Automatisch erkannt via _get_stow_packages()
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor stow.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
# Packages werden dynamisch via _get_stow_packages() aus backup.sh ermittelt
# Keine hardcoded Liste mehr nötig

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

    # Backup vor Stow erstellen (falls noch nicht vorhanden)
    # backup.sh MUSS vorher geladen sein - ohne Backup kein --adopt!
    if type backup_create_if_needed >/dev/null 2>&1; then
        backup_create_if_needed || {
            err "Backup fehlgeschlagen – Abbruch"
            return 1
        }
    else
        err "backup.sh nicht geladen – Backup ist Pflicht für stow --adopt"
        err "Bitte sicherstellen dass backup.sh vor stow.sh geladen wird"
        return 1
    fi

    log "Verlinke Konfigurationsdateien..."

    # Ins dotfiles-Verzeichnis wechseln
    cd "$DOTFILES_DIR" || {
        err "Konnte nicht nach $DOTFILES_DIR wechseln"
        return 1
    }

    # Packages dynamisch ermitteln (aus backup.sh)
    local packages
    packages=($(_get_stow_packages))

    if [[ ${#packages[@]} -eq 0 ]]; then
        warn "Keine Stow-Packages gefunden"
        return 0
    fi

    # Stow mit --adopt ausführen (übernimmt existierende Dateien)
    # -R = Restow (erst unstow, dann stow)
    if stow --adopt -R "${packages[@]}" 2>/dev/null; then
        ok "Symlinks erstellt für: ${packages[*]}"
    else
        warn "Stow hatte Probleme – prüfe manuell"
        return 0  # Kein fataler Fehler
    fi

    # Adoptierte Dateien auf Repository-Zustand zurücksetzen
    # (Falls existierende Configs abweichen)
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if git diff --quiet 2>/dev/null; then
            log "Keine adoptierten Änderungen"
        else
            log "Setze adoptierte Dateien auf Repository-Zustand zurück..."
            git reset --hard HEAD >/dev/null 2>&1
            ok "Repository-Zustand wiederhergestellt"
        fi
    else
        warn "Kein Git-Repository in $DOTFILES_DIR – überspringe Reset"
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
