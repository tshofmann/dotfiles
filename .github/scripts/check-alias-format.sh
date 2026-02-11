#!/usr/bin/env zsh
# ============================================================
# check-alias-format.sh - Alias-Datei-Format prüfen
# ============================================================
# Zweck       : Prüft ob alle .alias-Dateien einen Header-Block
#               und einen Guard-Check besitzen
# Pfad        : .github/scripts/check-alias-format.sh
# Aufruf      : ./.github/scripts/check-alias-format.sh
# Nutzt       : theme-style (Farben)
# Generiert   : Nichts (nur Validierung)
# ============================================================

set -uo pipefail

# Dotfiles-Verzeichnis ermitteln
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h}"  # .github/scripts → dotfiles

# Farben laden (optional – funktioniert auch ohne)
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-style"
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

# Logging
log()  { echo -e "${C_BLUE:-}→${C_RESET:-} $1"; }
ok()   { echo -e "${C_GREEN:-}✔${C_RESET:-} $1"; }
err()  { echo -e "${C_RED:-}✖${C_RESET:-} $1" >&2; }

# ------------------------------------------------------------
# Alias-Datei-Format prüfen (Guards, Header)
# ------------------------------------------------------------
check_alias_format() {
    local errors=0

    for file in "$DOTFILES_DIR"/terminal/.config/alias/*.alias(N); do
        local name=$(basename "$file")

        # Header-Block vorhanden?
        if ! head -3 "$file" | grep -q "^# ===="; then
            err "$name: Kein Header-Block"
            (( errors++ )) || true
        fi

        # Guard-Check vorhanden?
        if ! grep -q "command -v.*>/dev/null" "$file"; then
            err "$name: Kein Guard-Check"
            (( errors++ )) || true
        fi
    done

    if (( errors > 0 )); then
        err "$errors Alias-Datei(en) mit Format-Fehlern"
        return 1
    fi

    ok "Alias-Format OK"
    return 0
}

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
log "Prüfe Alias-Datei-Format..."
check_alias_format
