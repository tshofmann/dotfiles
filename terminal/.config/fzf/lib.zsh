#!/usr/bin/env zsh
# ============================================================
# lib.zsh - Gemeinsame Funktionen für fzf-Helper
# ============================================================
# Zweck   : Geteilte Utilities für alle fzf-Skripte
# Pfad    : ~/.config/fzf/lib.zsh
# ============================================================
# Hinweis : Wird von fzf-Helpern per 'source' eingebunden
#           Keine direkte Ausführung vorgesehen
# ============================================================

# Guard: Nicht doppelt laden
[[ -n "${FZF_LIB_LOADED:-}" ]] && return 0
FZF_LIB_LOADED=1

# ------------------------------------------------------------
# Shell-Farben laden (Catppuccin Mocha)
# ------------------------------------------------------------
_fzf_load_colors() {
    local colors_file="${XDG_CONFIG_HOME:-$HOME/.config}/theme-style"
    [[ -f "$colors_file" ]] && source "$colors_file"

    # Fallback: leere Werte wenn theme-style nicht verfügbar
    : "${C_MAUVE:=}"
    : "${C_GREEN:=}"
    : "${C_BLUE:=}"
    : "${C_RED:=}"
    : "${C_TEXT:=}"
    : "${C_RESET:=}"
}

# ------------------------------------------------------------
# ANSI-Escape-Codes entfernen
# ------------------------------------------------------------
# Verwendung: echo "$text" | _fzf_strip_ansi
_fzf_strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# Farben beim Laden initialisieren
_fzf_load_colors
