#!/usr/bin/env zsh
# ============================================================
# lib.zsh - Gemeinsame Funktionen für fzf-Helper
# ============================================================
# Zweck       : Geteilte Utilities für alle fzf-Skripte
# Pfad        : ~/.config/fzf/lib.zsh
# ============================================================
# Hinweis     : Wird von fzf-Helpern per 'source' eingebunden
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
# Verwendung  : echo "$text" | _fzf_strip_ansi
_fzf_strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# ------------------------------------------------------------
# Generischer Dispatcher für Helper-Skripte
# ------------------------------------------------------------
# Verwendung  : _fzf_dispatch "helper-name" "$@"
# Erwartet    : Funktionen _<name>_<cmd>() und _<name>_usage()
_fzf_dispatch() {
    local name="$1"
    shift
    local cmd="${1:-}"

    case "$cmd" in
        -h|--help|"")
            "_${name}_usage"
            ;;
        *)
            if typeset -f "_${name}_${cmd}" >/dev/null 2>&1; then
                shift
                "_${name}_${cmd}" "$@"
            else
                echo "${C_RED}Unknown command:${C_RESET} $cmd" >&2
                "_${name}_usage" >&2
                return 1
            fi
            ;;
    esac
}

# Farben beim Laden initialisieren
_fzf_load_colors
