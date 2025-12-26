#!/usr/bin/env zsh
# ============================================================
# validate-docs.sh - Konsistenzprüfung Dokumentation ↔ Code
# ============================================================
# Zweck   : Prüft ob Inhalte der Dokumentation mit dem Code
#           übereinstimmen (Anzahlen, Namen, Auflistungen)
#
# HINWEIS : Dies ist KEINE Code-Validierung oder Syntax-Check!
#           Für Installationsprüfung: ./scripts/health-check.sh
#
# Aufruf  : ./scripts/validate-docs.sh [--all|--quick|--core|VALIDATOR]
# ============================================================
# Validatoren unter:
#   scripts/validators/core/     - Core-Prüfungen
#   scripts/validators/extended/ - Erweiterte Prüfungen
# ============================================================

set -euo pipefail

# ============================================================
# Pfad-Setup
# ============================================================
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
VALIDATORS_DIR="$SCRIPT_DIR/validators"

# ============================================================
# Lade Bibliothek
# ============================================================
if [[ -f "$VALIDATORS_DIR/lib.sh" ]]; then
    source "$VALIDATORS_DIR/lib.sh"
else
    print "FEHLER: lib.sh nicht gefunden!" >&2
    exit 1
fi

# ============================================================
# Lade Validatoren
# ============================================================
load_validators() {
    # Core-Validatoren laden
    if [[ -d "$VALIDATORS_DIR/core" ]]; then
        for f in "$VALIDATORS_DIR/core"/*.sh(N); do
            source "$f"
        done
    fi
    
    # Extended-Validatoren laden
    if [[ -d "$VALIDATORS_DIR/extended" ]]; then
        for f in "$VALIDATORS_DIR/extended"/*.sh(N); do
            source "$f"
        done
    fi
}

# ============================================================
# Hilfe
# ============================================================
show_help() {
    print "Verwendung: validate-docs.sh [OPTION|VALIDATOR]"
    print ""
    print "Optionen:"
    print "  --all, -a      Alle Validatoren (Core + Extended)"
    print "  --core, -c     Nur Core-Validatoren"
    print "  --extended, -e Nur erweiterte Validatoren"
    print "  --list, -l     Verfügbare Validatoren auflisten"
    print "  --help, -h     Diese Hilfe anzeigen"
    print ""
    print "Beispiele:"
    print "  validate-docs.sh              # Alle Prüfungen"
    print "  validate-docs.sh --core       # Nur Core-Prüfungen"
    print "  validate-docs.sh alias-names  # Nur Alias-Namen prüfen"
    print "  validate-docs.sh brewfile     # Nur Brewfile prüfen"
}

# ============================================================
# Banner
# ============================================================
print_banner() {
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "📖 Dokumentations-Validierung (Konsistenz Doku↔Code)"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# Hauptprogramm
# ============================================================
print_banner

case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --list|-l)
        load_validators
        list_validators
        exit 0
        ;;
    --core|-c)
        load_validators
        run_core_validators
        print_summary
        exit $?
        ;;
    --extended|-e)
        load_validators
        run_extended_validators
        print_summary
        exit $?
        ;;
    --all|-a|"")
        load_validators
        run_all_validators
        print_summary
        exit $?
        ;;
    *)
        # Spezifischer Validator
        load_validators
        if ! run_validator "$1"; then
            print_summary
            exit 1
        fi
        print_summary
        exit $?
        ;;
esac
