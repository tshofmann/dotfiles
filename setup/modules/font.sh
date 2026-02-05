#!/usr/bin/env zsh
# ============================================================
# font.sh - Nerd Font Verifikation
# ============================================================
# Zweck       : Verifiziert Installation eines Nerd Fonts
# Pfad        : setup/modules/font.sh
# Benötigt    : _core.sh, homebrew.sh (Font wird via Brewfile installiert)
# Plattform   : Universell (macOS + Linux)
#
# STEP        : Font-Verifikation | Prüft Nerd Font Installation | ❌ Exit
# Font        : JetBrains Mono oder MesloLG Nerd Font (via Brewfile)
# Speicherort : ~/Library/Fonts/ (macOS) oder ~/.local/share/fonts/ (Linux)
# Verwendung  : Icons in Terminal (Powerline, Devicons, Font Awesome, Octicons)
# Alternativen : brew search nerd-font
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor font.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
# Unterstützte Nerd Fonts (aus Brewfile)
readonly -a FONT_GLOBS=(
    "JetBrainsMono*NerdFont*"
    "MesloLG*NerdFont*"
)

# ------------------------------------------------------------
# Font-Installation verifizieren
# ------------------------------------------------------------
font_installed() {
    local -a fonts=()
    local glob

    for glob in "${FONT_GLOBS[@]}"; do
        if is_macos; then
            # macOS: User- und System-Font-Verzeichnisse
            # (N) = NULL_GLOB, ${~VAR} = Glob-Expansion
            fonts+=(
                ~/Library/Fonts/${~glob}(N)
                /Library/Fonts/${~glob}(N)
            )
        elif is_linux; then
            # Linux: XDG-konforme Font-Verzeichnisse
            fonts+=(
                ~/.local/share/fonts/${~glob}(N)
                ~/.fonts/${~glob}(N)
                /usr/share/fonts/**/${~glob}(N)
                /usr/local/share/fonts/${~glob}(N)
            )
        fi
    done

    (( ${#fonts} > 0 ))
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_font() {
    CURRENT_STEP="Font-Verifikation"

    if ! font_installed; then
        err "Kein Nerd Font gefunden nach Installation."
        if is_macos; then
            err "  Prüfe: ls ~/Library/Fonts/*NerdFont*"
        elif is_linux; then
            err "  Prüfe: ls ~/.local/share/fonts/*NerdFont*"
            log "  Tipp: Nach manueller Installation 'fc-cache -fv' ausführen"
        fi
        return 1
    fi

    ok "Nerd Font vorhanden"
    return 0
}
