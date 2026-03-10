#!/usr/bin/env zsh
# ============================================================
# run-all.sh - Test-Runner für Generator Unit Tests
# ============================================================
# Zweck       : Findet und führt alle test-*.sh Skripte aus
# Pfad        : .github/scripts/tests/run-all.sh
# Aufruf      : ./.github/scripts/tests/run-all.sh
# Nutzt       : theme-style (Farben, optional)
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"

# Farben laden (optional)
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-style"
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

log()  { echo -e "${C_BLUE:-}→${C_RESET:-} $1"; }
ok()   { echo -e "${C_GREEN:-}✔${C_RESET:-} $1"; }
err()  { echo -e "${C_RED:-}✖${C_RESET:-} $1" >&2; }

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
log "Starte Generator Unit Tests..."
echo ""

total_files=0
failed_files=0

for test_file in "$SCRIPT_DIR"/test-*.sh(N); do
    (( total_files++ )) || true

    name="${test_file:t}"
    echo "── $name ──"

    if zsh "$test_file"; then
        echo ""
    else
        (( failed_files++ )) || true
        echo ""
    fi
done

# Gesamtergebnis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if (( total_files == 0 )); then
    err "Keine Test-Dateien gefunden"
    exit 1
fi

if (( failed_files > 0 )); then
    err "$failed_files von $total_files Test-Dateien fehlgeschlagen"
    exit 1
fi

ok "Alle $total_files Test-Dateien bestanden"
