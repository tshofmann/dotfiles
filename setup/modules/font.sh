#!/usr/bin/env zsh
# ============================================================
# font.sh - Nerd Font Verifikation
# ============================================================
# Zweck       : Verifiziert Installation des Nerd Fonts
# Pfad        : setup/modules/font.sh
# Benötigt    : _core.sh, homebrew.sh (Font wird via Brewfile installiert)
# CURRENT_STEP: Font-Verifikation
# Font        : MesloLGS Nerd Font (LDZNF = Large, Dotted Zero, Nerd Font)
# Speicherort : ~/Library/Fonts/ (via Homebrew Cask)
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
    # Prüfe User- und System-Font-Verzeichnisse (Homebrew installiert nach ~/Library/Fonts)
    # Array sammelt alle gematchten Dateien; (N) = NULL_GLOB, ${~VAR} = Glob-Expansion
    local -a fonts=(
        ~/Library/Fonts/${~FONT_GLOB}(N)
        /Library/Fonts/${~FONT_GLOB}(N)
    )
    (( ${#fonts} > 0 ))
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_font() {
    CURRENT_STEP="Font-Verifikation"

    if ! font_installed; then
        err "Font nicht gefunden nach Installation, Terminal-Profil wird nicht importiert."
        err "  Prüfe: ls ~/Library/Fonts/$FONT_GLOB"
        return 1
    fi

    ok "Font vorhanden"
    return 0
}
