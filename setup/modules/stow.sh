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
# Gibt den SHA des erstellten Stash auf stdout aus (leer wenn kein Stash nötig).
_stash_uncommitted_changes() {
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
    warn "Uncommitted Changes im Repository erkannt" >&2
    log "Stashe Änderungen vor stow --adopt..." >&2

    # Stash mit -u (untracked files), PID im Message für Identifikation
    local stash_msg="auto: pre-stow $$-$(date +%Y%m%d-%H%M%S)"
    git stash push -u -m "$stash_msg" >/dev/null 2>&1

    # SHA sofort nach push ermitteln (Mikrosekunden-Fenster, Single-User)
    local stash_sha
    stash_sha=$(git rev-parse stash@{0} 2>/dev/null) || true

    if [[ -z "$stash_sha" ]]; then
        warn "Stash konnte nicht erstellt werden" >&2
        return 1
    fi

    # Verifizierung: Message muss unsere PID enthalten
    local top_msg
    top_msg=$(git --no-pager stash list -1 --format="%s" 2>/dev/null)
    if [[ "$top_msg" != *"$$-"* ]]; then
        warn "Stash-Verifizierung fehlgeschlagen (Race Condition?)" >&2
        warn "Erwartet PID $$ in Message, gefunden: $top_msg" >&2
        warn "Prüfe manuell: git stash list" >&2
        return 1
    fi

    print "$stash_sha"
    ok "Changes gesichert (SHA: ${stash_sha:0:8})" >&2

    return 0
}

# ------------------------------------------------------------
# Gestashte Changes wiederherstellen (nach git reset --hard)
# ------------------------------------------------------------
# Argument: $1 = SHA des Stash (von _stash_uncommitted_changes)
_restore_stashed_changes() {
    local stash_sha="$1"
    [[ -n "$stash_sha" ]] || return 0

    log "Stelle deine uncommitted Changes wieder her..."

    # SHA → stash@{N} auflösen (TOCTOU-sicher: unabhängig von Stash-Reihenfolge)
    local stash_ref=""
    local line ref
    while IFS= read -r line; do
        ref="${line%%:*}"
        if [[ "$(git rev-parse "$ref" 2>/dev/null)" == "$stash_sha" ]]; then
            stash_ref="$ref"
            break
        fi
    done < <(git --no-pager stash list 2>/dev/null)

    if [[ -z "$stash_ref" ]]; then
        warn "Stash mit SHA $stash_sha nicht mehr gefunden"
        warn "Prüfe manuell: git stash list"
        return 1
    fi

    # --index erhält den Staging-Zustand
    if git stash apply --index "$stash_ref" >/dev/null 2>&1; then
        git stash drop "$stash_ref" >/dev/null 2>&1 || warn "Stash apply OK, aber drop fehlgeschlagen für: $stash_ref"
        ok "Deine Änderungen wurden wiederhergestellt"
    elif git stash apply "$stash_ref" >/dev/null 2>&1; then
        # Fallback ohne --index (falls Index-Konflikte)
        git stash drop "$stash_ref" >/dev/null 2>&1 || warn "Stash apply OK, aber drop fehlgeschlagen für: $stash_ref"
        ok "Änderungen wiederhergestellt (Staging-Zustand nicht erhalten)"
    else
        # Konflikt - Stash bleibt erhalten
        warn "Automatische Wiederherstellung fehlgeschlagen"
        warn "Deine Änderungen sind sicher in: $stash_ref"
        warn "Nach Bootstrap manuell ausführen: git stash apply $stash_sha"
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

    # Ins dotfiles-Verzeichnis wechseln (pushd isoliert den CWD-Wechsel)
    pushd "$DOTFILES_DIR" >/dev/null || {
        err "Konnte nicht nach $DOTFILES_DIR wechseln"
        return 1
    }

    # Packages dynamisch ermitteln (aus backup.sh)
    local packages
    packages=($(_get_stow_packages))

    if [[ ${#packages[@]} -eq 0 ]]; then
        warn "Keine Stow-Packages gefunden"
        popd >/dev/null
        return 0
    fi

    # Uncommitted Changes sichern VOR stow --adopt
    # Wichtig: Nach dem Stash sind nur noch adopt-Änderungen sichtbar
    # SHA wird für TOCTOU-sichere Wiederherstellung gespeichert
    local stash_sha
    stash_sha=$(_stash_uncommitted_changes) || {
        err "Stash fehlgeschlagen – überspringe stow --adopt um Datenverlust zu vermeiden"
        warn "Bitte manuell committen oder stashen, dann erneut ausführen"
        popd >/dev/null
        return 1
    }

    # Stow mit --adopt ausführen (übernimmt existierende Dateien)
    # -R = Restow (erst unstow, dann stow)
    # || stow_rc=$? verhindert, dass set -e das Script abbricht
    # bevor _restore_stashed_changes aufgerufen wird
    local stow_output stow_rc=0
    stow_output=$(stow --adopt -R "${packages[@]}" 2>&1) || stow_rc=$?

    if (( stow_rc == 0 )); then
        ok "Symlinks erstellt für: ${packages[*]}"
    else
        warn "Stow hatte Probleme (Exit-Code: $stow_rc):"
        # Jede Zeile einzeln loggen für konsistente Formatierung
        # warn() nutzt print -P: % vor Ausgabe escapen, um Prompt-Escapes zu vermeiden
        local line safe_line
        while IFS= read -r line; do
            safe_line=${line//\%/%%}
            [[ -n "$safe_line" ]] && warn "  $safe_line"
        done <<< "$stow_output"
        # Stash trotzdem wiederherstellen bei Fehler
        if ! _restore_stashed_changes "$stash_sha"; then
            warn "Bootstrap fortgesetzt – Stash manuell wiederherstellen"
        fi
        popd >/dev/null
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
    if ! _restore_stashed_changes "$stash_sha"; then
        warn "Bootstrap fortgesetzt – Stash manuell wiederherstellen"
    fi

    # CWD wiederherstellen
    popd >/dev/null

    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_stow() {
    CURRENT_STEP="Stow Setup"
    run_stow
}
