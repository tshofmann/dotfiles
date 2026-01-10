#!/usr/bin/env zsh
# ============================================================
# generate-docs.sh - Dokumentations-Generator (Single Source of Truth)
# ============================================================
# Zweck   : Generiert alle Dokumentation aus Code-Kommentaren
# Pfad    : scripts/generate-docs.sh
# Aufruf  : ./scripts/generate-docs.sh [--check|--generate]
# ============================================================
# Architektur:
#   Code (.alias, Brewfile, configs) → Generator → Docs
#   Keine manuelle Dokumentation – Code ist die Wahrheit
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
GENERATORS_DIR="$SCRIPT_DIR/generators"
DOTFILES_DIR="${SCRIPT_DIR:h:h}"  # .github/scripts → dotfiles
DOCS_DIR="$DOTFILES_DIR/docs"

# Laden der gemeinsamen Bibliothek
source "$GENERATORS_DIR/lib.sh"

# ------------------------------------------------------------
# Generator-Funktionen direkt einbinden (nicht source!)
# ------------------------------------------------------------
# Die Generator-Module definieren Funktionen die wir aufrufen können

# Hilfsfunktion: Generiere Inhalt mittels Subshell um globalen State zu vermeiden
run_generator() {
    local module="$1"
    local func="$2"
    local output

    # Subshell mit Error-Handling
    if ! output=$(
        export _SOURCED_BY_GENERATOR=1
        source "$GENERATORS_DIR/$module"
        "$func"
    ); then
        err "Generator $module ($func) fehlgeschlagen"
        return 1
    fi

    printf '%s\n' "$output"
}

# ------------------------------------------------------------
# Modus: Prüfen
# ------------------------------------------------------------
check_all() {
    log "Prüfe ob Dokumentation aktuell ist..."
    local errors=0

    # README.md
    local generated=$(run_generator "readme.sh" "generate_readme_md")
    if ! compare_content "$DOTFILES_DIR/README.md" "$generated"; then
        err "README.md ist veraltet"
        (( errors++ )) || true
    else
        ok "README.md ist aktuell"
    fi

    # docs/setup.md
    generated=$(run_generator "setup.sh" "generate_setup_md")
    if ! compare_content "$DOCS_DIR/setup.md" "$generated"; then
        err "docs/setup.md ist veraltet"
        (( errors++ )) || true
    else
        ok "docs/setup.md ist aktuell"
    fi

    # docs/customization.md
    generated=$(run_generator "customization.sh" "generate_customization_md")
    if ! compare_content "$DOCS_DIR/customization.md" "$generated"; then
        err "docs/customization.md ist veraltet"
        (( errors++ )) || true
    else
        ok "docs/customization.md ist aktuell"
    fi

    # tldr-Patches
    local tldr_ok=true
    (
        source "$GENERATORS_DIR/tldr.sh"
        generate_tldr_patches --check
    ) || {
        tldr_ok=false
        (( errors++ )) || true
    }
    $tldr_ok && ok "tldr-Patches sind aktuell"

    if (( errors > 0 )); then
        echo ""
        err "$errors Datei(en) veraltet. Führe './scripts/generate-docs.sh --generate' aus."
        return 1
    fi

    echo ""
    ok "Alle Dokumentation ist aktuell"
    return 0
}

# ------------------------------------------------------------
# Modus: Generieren
# ------------------------------------------------------------
generate_all() {
    log "Generiere Dokumentation..."

    # README.md
    local generated=$(run_generator "readme.sh" "generate_readme_md")
    write_if_changed "$DOTFILES_DIR/README.md" "$generated"

    # docs/setup.md
    generated=$(run_generator "setup.sh" "generate_setup_md")
    write_if_changed "$DOCS_DIR/setup.md" "$generated"

    # docs/customization.md
    generated=$(run_generator "customization.sh" "generate_customization_md")
    write_if_changed "$DOCS_DIR/customization.md" "$generated"

    # tldr-Patches
    (
        source "$GENERATORS_DIR/tldr.sh"
        generate_tldr_patches --generate
    )

    echo ""
    ok "Dokumentation generiert"
}

# ------------------------------------------------------------
# Hauptlogik
# ------------------------------------------------------------
main() {
    local mode="${1:---check}"

    case "$mode" in
        --check)
            check_all
            ;;
        --generate)
            generate_all
            ;;
        --help|-h)
            echo "Verwendung: $0 [--check|--generate]"
            echo ""
            echo "  --check     Prüft ob Dokumentation aktuell ist (Default)"
            echo "  --generate  Generiert alle Dokumentation neu"
            echo ""
            echo "Generierte Dateien:"
            echo "  README.md"
            echo "  docs/setup.md"
            echo "  docs/customization.md"
            echo "  terminal/.config/tealdeer/pages/*.patch.md"
            ;;
        *)
            err "Unbekannte Option: $mode"
            echo "Verwende --help für Hilfe"
            return 1
            ;;
    esac
}

main "$@"
