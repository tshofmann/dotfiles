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
# Uncommitted Changes stashen (vor stow --adopt)
# ------------------------------------------------------------
# Stasht alle uncommitted Änderungen (inkl. untracked) VOR stow --adopt,
# damit sie nach git reset --hard wiederhergestellt werden können.
# Setzt _STOW_STASH_CREATED=1 wenn Stash erstellt wurde.
_stash_uncommitted_changes() {
    _STOW_STASH_CREATED=0

    # Kein Git? Überspringen.
    command -v git >/dev/null 2>&1 || return 0
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

    # Prüfe auf ALLE Arten von Änderungen (staged, unstaged, untracked)
    local status_output
    status_output=$(git status --porcelain 2>/dev/null)

    if [[ -z "$status_output" ]]; then
        # Keine Änderungen
        return 0
    fi

    # Änderungen gefunden - stashen
    warn "Uncommitted Changes im Repository erkannt"
    log "Stashe Änderungen vor stow --adopt..."

    # Stash-Anzahl vorher merken (Exit-Code von git stash ist unzuverlässig)
    local stash_count_before stash_count_after
    stash_count_before=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

    # Stash mit -u (untracked files) und Zeitstempel
    git stash push -u -m "auto: pre-stow $(date +%Y%m%d-%H%M%S)" >/dev/null 2>&1

    # Verifizieren dass Stash erstellt wurde
    stash_count_after=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

    if (( stash_count_after > stash_count_before )); then
        _STOW_STASH_CREATED=1
        ok "Changes gesichert in: stash@{0}"
    else
        warn "Stash konnte nicht erstellt werden"
    fi

    return 0
}

# ------------------------------------------------------------
# Gestashte Changes wiederherstellen (nach git reset --hard)
# ------------------------------------------------------------
_restore_stashed_changes() {
    [[ "${_STOW_STASH_CREATED:-0}" -eq 1 ]] || return 0

    log "Stelle deine uncommitted Changes wieder her..."

    # --index erhält den Staging-Zustand
    if git stash pop --index >/dev/null 2>&1; then
        ok "Deine Änderungen wurden wiederhergestellt"
    elif git stash pop >/dev/null 2>&1; then
        # Fallback ohne --index (falls Index-Konflikte)
        ok "Änderungen wiederhergestellt (Staging-Zustand nicht erhalten)"
    else
        # Konflikt - Stash bleibt erhalten
        warn "Automatische Wiederherstellung fehlgeschlagen"
        warn "Deine Änderungen sind sicher in: stash@{0}"
        warn "Nach Bootstrap manuell ausführen: git stash pop"
        return 1
    fi

    return 0
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

    # Uncommitted Changes sichern VOR stow --adopt
    # Wichtig: Nach dem Stash sind nur noch adopt-Änderungen sichtbar
    _stash_uncommitted_changes

    # Stow mit --adopt ausführen (übernimmt existierende Dateien)
    # -R = Restow (erst unstow, dann stow)
    if stow --adopt -R "${packages[@]}" 2>/dev/null; then
        ok "Symlinks erstellt für: ${packages[*]}"
    else
        warn "Stow hatte Probleme – prüfe manuell"
        # Stash trotzdem wiederherstellen bei Fehler
        _restore_stashed_changes
        return 0
    fi

    # Adoptierte Dateien auf Repository-Zustand zurücksetzen
    # (Jetzt nur noch adopt-Änderungen, nicht User-Arbeit)
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if git diff HEAD --quiet 2>/dev/null; then
            log "Keine adoptierten Änderungen"
        else
            log "Setze adoptierte Dateien auf Repository-Zustand zurück..."
            git reset --hard HEAD >/dev/null 2>&1
            ok "Repository-Zustand wiederhergestellt"
        fi
    else
        warn "Kein Git-Repository in $DOTFILES_DIR – überspringe Reset"
    fi

    # Gestashte User-Änderungen wiederherstellen
    _restore_stashed_changes

    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_stow() {
    CURRENT_STEP="Stow Setup"
    run_stow
}
