#!/usr/bin/env zsh
# ============================================================
# git-hooks.sh - Git Hooks Konfiguration
# ============================================================
# Zweck       : Aktiviert Pre-Commit Hooks für das Repository
# Pfad        : setup/modules/git-hooks.sh
# Benötigt    : _core.sh
#
# STEP        : Git Hooks | Aktiviert Pre-Commit Validierung | ✓ Schnell
# Hooks       : .github/hooks/pre-commit
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor git-hooks.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly HOOKS_PATH=".github/hooks"

# ------------------------------------------------------------
# Git Hooks aktivieren
# ------------------------------------------------------------
configure_git_hooks() {
    CURRENT_STEP="Git Hooks"
    
    # Prüfe ob wir in einem Git-Repository sind
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        warn "Kein Git-Repository – Hooks übersprungen"
        return 0
    fi
    
    # Prüfe ob Hooks-Verzeichnis existiert
    local hooks_dir="$DOTFILES_DIR/$HOOKS_PATH"
    if [[ ! -d "$hooks_dir" ]]; then
        warn "Hooks-Verzeichnis nicht gefunden: $hooks_dir"
        return 0
    fi
    
    # Aktuellen hooksPath prüfen
    local current_hooks
    current_hooks=$(git config --get core.hooksPath 2>/dev/null || echo "")
    
    if [[ "$current_hooks" == "$HOOKS_PATH" ]]; then
        ok "Git Hooks bereits aktiviert"
        return 0
    fi
    
    log "Aktiviere Git Pre-Commit Hooks..."
    
    cd "$DOTFILES_DIR" || return 1
    
    if git config core.hooksPath "$HOOKS_PATH"; then
        ok "Git Hooks aktiviert: $HOOKS_PATH"
    else
        warn "Konnte Git Hooks nicht aktivieren"
    fi
    
    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_git_hooks() {
    CURRENT_STEP="Git Hooks Setup"
    configure_git_hooks
}

# Modul ausführen wenn direkt aufgerufen
if [[ "${(%):-%N}" == "$0" ]]; then
    source "${0:A:h}/_core.sh"
    setup_git_hooks
fi
