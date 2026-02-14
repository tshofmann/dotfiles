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
        26) echo "Tahoe" ;;  # macOS 26 (2025)
        *)  echo "macOS $version" ;;
    esac
}

# Extrahiert MACOS_MIN_VERSION aus bootstrap.sh (unterstützt ab)
extract_macos_min_version() {
    [[ -f "$BOOTSTRAP" ]] || { echo "26"; return; }
    local version=$(grep "^readonly MACOS_MIN_VERSION=" "$BOOTSTRAP" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# Extrahiert MACOS_TESTED_VERSION aus bootstrap.sh (zuletzt getestet auf)
extract_macos_tested_version() {
    [[ -f "$BOOTSTRAP" ]] || { echo "26"; return; }
    local version=$(grep "^readonly MACOS_TESTED_VERSION=" "$BOOTSTRAP" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# ------------------------------------------------------------
# Bootstrap-Modul Parser (Modulare Struktur)
# ------------------------------------------------------------
# Prüft ob modulare Bootstrap-Struktur existiert
has_bootstrap_modules() {
    [[ -d "$BOOTSTRAP_MODULES" && -f "$BOOTSTRAP_MODULES/_core.sh" ]]
}

# Extrahiert MACOS_MIN_VERSION aus validation.sh (modulare Struktur)
extract_macos_min_version_from_module() {
    local validation="$BOOTSTRAP_MODULES/validation.sh"
    [[ -f "$validation" ]] || { echo "26"; return; }
    local version=$(grep "^[[:space:]]*MACOS_MIN_VERSION=" "$validation" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# Extrahiert MACOS_TESTED_VERSION aus validation.sh (modulare Struktur)
extract_macos_tested_version_from_module() {
    local validation="$BOOTSTRAP_MODULES/validation.sh"
    [[ -f "$validation" ]] || { echo "26"; return; }
    local version=$(grep "^[[:space:]]*MACOS_TESTED_VERSION=" "$validation" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# Smart-Extraktor: Prüft zuerst Module, dann bootstrap.sh
extract_macos_min_version_smart() {
    if has_bootstrap_modules; then
        extract_macos_min_version_from_module
    else
        extract_macos_min_version
    fi
}

extract_macos_tested_version_smart() {
    if has_bootstrap_modules; then
        extract_macos_tested_version_from_module
    else
        extract_macos_tested_version
    fi
}
