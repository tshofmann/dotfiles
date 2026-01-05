#!/usr/bin/env zsh
# ============================================================
# generate-docs.sh - Haupt-Generator für Dokumentation
# ============================================================
# Zweck   : Generiert Dokumentations-Inhalte aus Code
# Aufruf  : ./scripts/generate-docs.sh [--dry-run]
# ============================================================

set -euo pipefail

# ============================================================
# Pfad-Setup
# ============================================================
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
GENERATORS_DIR="$SCRIPT_DIR/generators"

# ============================================================
# Lade Bibliothek
# ============================================================
if [[ -f "$GENERATORS_DIR/lib.sh" ]]; then
    source "$GENERATORS_DIR/lib.sh"
else
    print "FEHLER: generators/lib.sh nicht gefunden!" >&2
    exit 1
fi

# ============================================================
# Lade Generatoren
# ============================================================
load_generators() {
    if [[ -d "$GENERATORS_DIR" ]]; then
        for f in "$GENERATORS_DIR"/*.sh(N); do
            # Überspringe lib.sh
            [[ "$(basename $f)" == "lib.sh" ]] && continue
            source "$f"
            debug "Geladen: $(basename $f)"
        done
    fi
}

# ============================================================
# Banner
# ============================================================
print_banner() {
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "📝 Dokumentations-Generator (Code → Docs)"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# Hilfe
# ============================================================
show_help() {
    print "Verwendung: generate-docs.sh [OPTION]"
    print ""
    print "Optionen:"
    print "  --dry-run, -n  Zeige was generiert würde, ohne zu ändern"
    print "  --help, -h     Diese Hilfe anzeigen"
    print ""
    print "Beispiele:"
    print "  generate-docs.sh           # Generiere alle Dokumentations-Inhalte"
    print "  generate-docs.sh --dry-run # Prüfe was generiert würde"
}

# ============================================================
# Hauptprogramm
# ============================================================
main() {
    local dry_run=false
    
    # Parse Argumente
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --dry-run|-n)
            dry_run=true
            export GEN_DRY_RUN=1
            ;;
    esac
    
    print_banner
    print ""
    
    # Lade Generatoren
    load_generators
    
    # Führe Generatoren aus
    log "Generiere Dokumentations-Inhalte..."
    print ""
    
    # 1. Alias-Tabellen
    if [[ $(type -w generate_alias_sections) == *function* ]]; then
        generate_alias_sections "$DOCS_DIR/tools.md"
        print ""
    fi
    
    # Zusammenfassung
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if $dry_run; then
        info "Dry-Run abgeschlossen – keine Änderungen vorgenommen"
    else
        ok "Dokumentation erfolgreich generiert"
    fi
}

main "$@"
