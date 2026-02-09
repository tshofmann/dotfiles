#!/bin/sh
# ============================================================
# logging.sh - POSIX-kompatible Logging-Funktionen
# ============================================================
# Zweck       : Gemeinsame Logging-API für Setup-Skripte
# Pfad        : setup/lib/logging.sh
# Kompatibel  : POSIX sh, bash, dash, zsh
# Nutzer      : install.sh, restore.sh
# ============================================================
# Farben werden entweder vom Aufrufer gesetzt (theme-style)
# oder diese Fallback-Werte werden verwendet.
# ============================================================

# Fallback-Farben (Catppuccin Mocha ANSI-Approximation)
# Werden nur gesetzt wenn noch nicht definiert
if [ -t 1 ]; then
    : "${C_RED:=\033[38;5;210m}"
    : "${C_GREEN:=\033[38;5;157m}"
    : "${C_YELLOW:=\033[38;5;223m}"
    : "${C_BLUE:=\033[38;5;111m}"
    : "${C_MAUVE:=\033[38;5;183m}"
    : "${C_RESET:=\033[0m}"
    : "${C_BOLD:=\033[1m}"
    : "${C_DIM:=\033[2m}"
else
    C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_MAUVE='' C_RESET='' C_BOLD='' C_DIM=''
fi

# Farben exportieren (für Aufrufer wie install.sh Banner)
export C_RED C_GREEN C_YELLOW C_BLUE C_MAUVE C_RESET C_BOLD C_DIM

# ------------------------------------------------------------
# Logging-Funktionen
# ------------------------------------------------------------
log()  { printf "${C_BLUE}→${C_RESET} %s\n" "$*"; }
ok()   { printf "${C_GREEN}✔${C_RESET} %s\n" "$*"; }
warn() { printf "${C_YELLOW}⚠${C_RESET} %s\n" "$*"; }
err()  { printf "${C_RED}✖${C_RESET} %s\n" "$*" >&2; }

# ------------------------------------------------------------
# Erweiterte Funktionen (optional)
# ------------------------------------------------------------
# Überschrift mit Linie
section() {
    printf "\n${C_MAUVE}━━━ ${C_BOLD}%s${C_RESET}${C_MAUVE} ━━━${C_RESET}\n" "$*"
}

# Gedimmter Text
dim() {
    printf "${C_DIM}%s${C_RESET}\n" "$*"
}
