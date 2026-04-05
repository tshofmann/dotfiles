#!/usr/bin/env zsh
# ============================================================
# macos.sh - macOS Version Helper
# ============================================================
# Zweck       : macOS-Versionen und Codenamen aus Bootstrap extrahieren
# Pfad        : .github/scripts/generators/common/macos.sh
# Hinweis     : macOS-spezifische Funktionen – plattformunabhängige
#           Funktionen gehören in separate Module (z.B. starship.sh)
# ============================================================

# Abhängigkeit: config.sh muss vorher geladen sein

# ------------------------------------------------------------
# macOS Version Helper
# ------------------------------------------------------------
# Mapping: Major-Version → Codename
get_macos_codename() {
    local version="${1:-14}"
    case "$version" in
        11) echo "Big Sur" ;;
        12) echo "Monterey" ;;
        13) echo "Ventura" ;;
        14) echo "Sonoma" ;;
        15) echo "Sequoia" ;;
        # Apple sprang von Version 15 → 26 (2025, Alignment mit Jahreszahl)
        26) echo "Tahoe" ;;
        *)  echo "macOS $version" ;;
    esac
}

# ------------------------------------------------------------
# Bootstrap-Modul Parser
# ------------------------------------------------------------
# Prüft ob modulare Bootstrap-Struktur existiert
has_bootstrap_modules() {
    [[ -d "$BOOTSTRAP_MODULES" && -f "$BOOTSTRAP_MODULES/_core.sh" ]]
}

# Extrahiert MACOS_MIN_VERSION aus validation.sh
extract_macos_min_version_smart() {
    local validation="$BOOTSTRAP_MODULES/validation.sh"
    [[ -f "$validation" ]] || { echo "26"; return; }
    local version=$(grep 'MACOS_MIN_VERSION=' "$validation" | grep -v '^[[:space:]]*#' | head -1 | sed 's/.*=\([0-9]*\).*/\1/' || true)
    [[ -z "$version" ]] && warn "MACOS_MIN_VERSION nicht in $validation gefunden – Fallback auf 26"
    echo "${version:-26}"
}

# Extrahiert MACOS_TESTED_VERSION aus validation.sh
extract_macos_tested_version_smart() {
    local validation="$BOOTSTRAP_MODULES/validation.sh"
    [[ -f "$validation" ]] || { echo "26"; return; }
    local version=$(grep 'MACOS_TESTED_VERSION=' "$validation" | grep -v '^[[:space:]]*#' | head -1 | sed 's/.*=\([0-9]*\).*/\1/' || true)
    [[ -z "$version" ]] && warn "MACOS_TESTED_VERSION nicht in $validation gefunden – Fallback auf 26"
    echo "${version:-26}"
}
