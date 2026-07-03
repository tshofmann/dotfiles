#!/usr/bin/env zsh
# ============================================================
# prompts.zsh - EOF-sichere interaktive Prompts
# ============================================================
# Zweck       : EOF-sichere Ja/Nein- und Eingabe-Prompts (Ctrl-D = Nein/Default)
# Pfad        : setup/lib/prompts.zsh
# Geladen     : setup/restore.sh, setup/modules/ssh-keys.sh
# Nutzt       : theme-style Farben (mit Fallback)
# ============================================================

# Mehrfaches Laden verhindern
[[ -n "${_SETUP_PROMPTS_LOADED:-}" ]] && return 0
readonly _SETUP_PROMPTS_LOADED=1

# Farb-Fallbacks: prompts.zsh läuft evtl. unter `set -u` (restore.sh) ohne
# geladenes theme-style – ohne Fallback bräche ein unbound $C_MAUVE das Skript ab.
: "${C_MAUVE:=}" "${C_RESET:=}" "${C_DIM:=}"

# Prompt-Ausgabe auf das controlling tty (sichtbar auch bei umgeleitetem stdout;
# bei _ask_input würde $() sonst den Prompt einfangen). Die Subshell verwirft den
# Redirection-Fehler, falls kein tty existiert (non-interaktiv) – ohne Fehler-Spam.
_tty_print() { ( print "$@" >/dev/tty ) 2>/dev/null; }

# ------------------------------------------------------------
# Ja/Nein-Abfrage (set -e sicher)
# ------------------------------------------------------------
# read -r liefert Exit 0 solange stdin offen ist; bei EOF (Ctrl-D) Exit 1 →
# würde unter `set -e` das Skript abbrechen. Daher EOF explizit abfangen.
# read -q wäre keine Alternative (Exit 1 bereits bei "Nein" → gleicher Abbruch).
_ask_yes_no() {
    local prompt="$1"
    local answer
    _tty_print -rn -- "${C_MAUVE}?${C_RESET} ${prompt} [j/N] "
    if ! read -r answer; then
        # EOF (Ctrl-D) → wie "Nein" behandeln
        _tty_print -r -- ""
        return 1
    fi
    # j (deutsch) und y (englisch) als Ja akzeptieren
    [[ "$answer" == [jJyY] ]]
}

# ------------------------------------------------------------
# Eingabe mit optionalem Vorschlag (set -e sicher)
# ------------------------------------------------------------
# Prompt auf /dev/tty, Ergebnis auf stdout – so fängt $(...) nur die Antwort,
# nicht den Prompt. Bei EOF wird der Default zurückgegeben (Exit 0).
_ask_input() {
    local prompt="$1"
    local default="${2:-}"
    local answer
    if [[ -n "$default" ]]; then
        _tty_print -rn -- "${C_MAUVE}?${C_RESET} ${prompt} ${C_DIM}[$default]${C_RESET} "
    else
        _tty_print -rn -- "${C_MAUVE}?${C_RESET} ${prompt} "
    fi
    if ! read -r answer; then
        # EOF (Ctrl-D) → Default zurückgeben
        _tty_print -r -- ""
        print -r -- "$default"
        return 0
    fi
    print -r -- "${answer:-$default}"
}
