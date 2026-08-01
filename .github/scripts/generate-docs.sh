#!/usr/bin/env zsh
# ============================================================
# generate-docs.sh - Dokumentations-Generator (Single Source of Truth)
# ============================================================
# Zweck       : Generiert alle Dokumentation aus Code-Kommentaren
# Pfad        : scripts/generate-docs.sh
# Aufruf      : ./scripts/generate-docs.sh [--check|--generate]
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

source "$GENERATORS_DIR/common.sh"

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
    if ! diff -q "$DOTFILES_DIR/README.md" <(printf '%s\n' "$generated") >/dev/null 2>&1; then
        err "README.md ist veraltet"
        diff -u --label "README.md (aktuell)" --label "README.md (generiert)" "$DOTFILES_DIR/README.md" <(printf '%s\n' "$generated") | head -30 || true
        (( errors++ )) || true
    else
        ok "README.md ist aktuell"
    fi

    # docs/setup.md
    generated=$(run_generator "setup.sh" "generate_setup_md")
    if ! diff -q "$DOCS_DIR/setup.md" <(printf '%s\n' "$generated") >/dev/null 2>&1; then
        err "docs/setup.md ist veraltet"
        diff -u --label "docs/setup.md (aktuell)" --label "docs/setup.md (generiert)" "$DOCS_DIR/setup.md" <(printf '%s\n' "$generated") | head -30 || true
        (( errors++ )) || true
    else
        ok "docs/setup.md ist aktuell"
    fi

    # docs/customization.md
    generated=$(run_generator "customization.sh" "generate_customization_md")
    if ! diff -q "$DOCS_DIR/customization.md" <(printf '%s\n' "$generated") >/dev/null 2>&1; then
        err "docs/customization.md ist veraltet"
        diff -u --label "docs/customization.md (aktuell)" --label "docs/customization.md (generiert)" "$DOCS_DIR/customization.md" <(printf '%s\n' "$generated") | head -30 || true
        (( errors++ )) || true
    else
        ok "docs/customization.md ist aktuell"
    fi

    # CONTRIBUTING.md (manuell gepflegt, nur ToC wird generiert)
    generated=$(run_generator "contributing.sh" "generate_contributing_md")
    if ! diff -q "$DOTFILES_DIR/CONTRIBUTING.md" <(printf '%s\n' "$generated") >/dev/null 2>&1; then
        err "CONTRIBUTING.md ist veraltet"
        diff -u --label "CONTRIBUTING.md (aktuell)" --label "CONTRIBUTING.md (generiert)" "$DOTFILES_DIR/CONTRIBUTING.md" <(printf '%s\n' "$generated") | head -30 || true
        (( errors++ )) || true
    else
        ok "CONTRIBUTING.md ist aktuell"
    fi

    # tldr-Patches
    local tldr_ok=true
    (
        export _SOURCED_BY_GENERATOR=1
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

    # CONTRIBUTING.md (manuell gepflegt, nur ToC wird generiert)
    generated=$(run_generator "contributing.sh" "generate_contributing_md")
    write_if_changed "$DOTFILES_DIR/CONTRIBUTING.md" "$generated"

    # tldr-Patches
    (
        export _SOURCED_BY_GENERATOR=1
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
            echo "  CONTRIBUTING.md (nur ToC)"
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
