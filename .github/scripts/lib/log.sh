#!/usr/bin/env zsh
# ============================================================
# log.sh - Gemeinsame Logging-Funktionen (ZSH)
# ============================================================
# Zweck       : Einheitliche log/ok/warn/err für alle ZSH-Skripte
# Pfad        : .github/scripts/lib/log.sh
# Nutzt       : theme-style (Farben, optional)
# ============================================================
# Verwendung:
#   source "${0:A:h}/lib/log.sh"      # aus .github/scripts/
#   source "${0:A:h}/../lib/log.sh"   # aus .github/scripts/tests/
#
# Definiert:
#   log()   – Info (blau →)
#   ok()    – Erfolg (grün ✔)
#   warn()  – Warnung (gelb ⚠)
#   err()   – Fehler (rot ✖, stderr)
#
# HINWEIS: Nutzt echo -e statt print -P, um %-Expansion zu
#          vermeiden. Sicher bei beliebigem Text (Dateinamen,
#          URLs, Prozentwerte). Siehe Issue #365.
# ============================================================

# Guard: Nicht mehrfach laden
[[ -n "${_LOG_SH_LOADED:-}" ]] && return 0
_LOG_SH_LOADED=1

# Farben laden (optional – graceful degradation)
# Aufrufer kann DOTFILES_DIR setzen, oder wir leiten es ab
if [[ -z "${C_BLUE:-}" ]]; then
    typeset _log_dotfiles="${DOTFILES_DIR:-${0:A:h:h:h:h}}"
    typeset _log_colors="$_log_dotfiles/terminal/.config/theme-style"
    [[ -f "$_log_colors" ]] && source "$_log_colors"
    unset _log_dotfiles _log_colors
fi

# Logging-Funktionen
# echo -e statt print -P: Vermeidet %-Expansion (sicherer bei beliebigem Input)
log()  { echo -e "${C_BLUE:-}→${C_RESET:-} $*"; }
ok()   { echo -e "${C_GREEN:-}✔${C_RESET:-} $*"; }
warn() { echo -e "${C_YELLOW:-}⚠${C_RESET:-} $*"; }
err()  { echo -e "${C_RED:-}✖${C_RESET:-} $*" >&2; }
