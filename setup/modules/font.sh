#!/usr/bin/env zsh
# ============================================================
# font.sh - Nerd Font Verifikation
# ============================================================
# Zweck       : Verifiziert Installation des Nerd Fonts
# Pfad        : setup/modules/font.sh
# Benötigt    : _core.sh, homebrew.sh (Font wird via Brewfile installiert)
# Plattform   : Universell (macOS + Linux)
# CURRENT_STEP: Font-Verifikation
# Font        : MesloLGS Nerd Font (LDZNF = Large, Dotted Zero, Nerd Font)
# Speicherort : ~/Library/Fonts/ (macOS) oder ~/.local/share/fonts/ (Linux)
# Verwendung  : Icons in Terminal (Powerline, Devicons, Font Awesome, Octicons)
# Alternativen: brew search nerd-font
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor font.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly FONT_GLOB="MesloLG*NerdFont*"

# ------------------------------------------------------------
# Font-Installation verifizieren
# ------------------------------------------------------------
font_installed() {
    local -a fonts=()

    if is_macos; then
        # macOS: User- und System-Font-Verzeichnisse
        # (N) = NULL_GLOB, ${~VAR} = Glob-Expansion
        fonts=(
            ~/Library/Fonts/${~FONT_GLOB}(N)
            /Library/Fonts/${~FONT_GLOB}(N)
        )
    elif is_linux; then
        # Linux: XDG-konforme Font-Verzeichnisse
        fonts=(
            ~/.local/share/fonts/${~FONT_GLOB}(N)
            ~/.fonts/${~FONT_GLOB}(N)
            /usr/share/fonts/**/${~FONT_GLOB}(N)
            /usr/local/share/fonts/${~FONT_GLOB}(N)
        )
    fi

    (( ${#fonts} > 0 ))
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_font() {
    CURRENT_STEP="Font-Verifikation"

    if ! font_installed; then
        err "Font nicht gefunden nach Installation."
        if is_macos; then
            err "  Prüfe: ls ~/Library/Fonts/$FONT_GLOB"
        elif is_linux; then
            err "  Prüfe: ls ~/.local/share/fonts/$FONT_GLOB"
            log "  Tipp: Nach manueller Installation 'fc-cache -fv' ausführen"
        fi
        return 1
    fi

    ok "Font vorhanden"
    return 0
}
