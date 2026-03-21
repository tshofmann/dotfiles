#!/usr/bin/env zsh
# ============================================================
# run-all.sh - Test-Runner für Generator Unit Tests
# ============================================================
# Zweck       : Findet und führt alle test-*.sh Skripte aus
# Pfad        : .github/scripts/tests/run-all.sh
# Aufruf      : ./.github/scripts/tests/run-all.sh
# Nutzt       : lib/log.sh (Logging + Farben)
# ============================================================

set -uo pipefail

# Dotfiles-Verzeichnis ermitteln
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"  # .github/scripts/tests → dotfiles

# Logging + Farben (geteilte Library)
source "${0:A:h}/../lib/log.sh"

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
