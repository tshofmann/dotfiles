#!/usr/bin/env zsh
# ============================================================
# zsh-sessions.sh - ZSH Session-Wiederherstellung deaktivieren
# ============================================================
# Zweck       : Prüft/konfiguriert SHELL_SESSIONS_DISABLE
# Pfad        : setup/modules/zsh-sessions.sh
# Benötigt    : _core.sh
# CURRENT_STEP: ZSH-Sessions Konfiguration
#
# Hintergrund:
#   macOS Terminal.app speichert standardmäßig separate History pro Tab/Fenster
#   in ~/.zsh_sessions/. Die Umgebungsvariable SHELL_SESSIONS_DISABLE=1 in
#   ~/.zshenv deaktiviert das Feature zugunsten einer zentralen ~/.zsh_history.
#
# WICHTIG: Die Variable muss in .zshenv gesetzt werden, da /etc/zshrc_Apple_Terminal
#          VOR .zprofile und .zshrc geladen wird. Eine leere Datei .zsh_sessions_disable
#          hat KEINE Wirkung (verbreiteter Irrtum).
# Ref: /etc/zshrc_Apple_Terminal
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor zsh-sessions.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_zsh_sessions() {
    CURRENT_STEP="ZSH-Sessions Konfiguration"

    log "Prüfe ZSH-Sessions Konfiguration"

    # Prüfe ob .zshenv existiert und SHELL_SESSIONS_DISABLE enthält
    if [[ -f "$HOME/.zshenv" ]] && grep -q "SHELL_SESSIONS_DISABLE=1" "$HOME/.zshenv" 2>/dev/null; then
        ok "zsh_sessions deaktiviert via ~/.zshenv"
    else
        warn "~/.zshenv fehlt oder SHELL_SESSIONS_DISABLE nicht gesetzt"
        warn "Nach 'stow -R terminal editor' wird dies automatisch verlinkt"
    fi

    return 0
}
