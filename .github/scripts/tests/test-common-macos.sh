#!/usr/bin/env zsh
# ============================================================
# test-common-macos.sh - Tests für common/macos.sh
# ============================================================
# Zweck       : Unit Tests für get_macos_codename(),
#               has_bootstrap_modules(), extract_macos_min_version(),
#               extract_macos_tested_version()
# Pfad        : .github/scripts/tests/test-common-macos.sh
# Aufruf      : ./.github/scripts/tests/test-common-macos.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# macos.sh braucht config.sh (für BOOTSTRAP Pfad-Variable)
# Für pure-function get_macos_codename() reicht ein Stub
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"
BOOTSTRAP="$DOTFILES_DIR/setup/bootstrap.sh"
BOOTSTRAP_MODULES="$DOTFILES_DIR/setup/modules"

source "$SCRIPT_DIR/../generators/common/macos.sh"

# warn() wird von extract_macos_*_version benötigt (kommt aus log.sh)
source "$SCRIPT_DIR/../lib/log.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# ============================================================
# get_macos_codename()
# ============================================================
echo "=== get_macos_codename ==="

assert_equals "Big Sur"   "Big Sur"     "$(get_macos_codename 11)"
assert_equals "Monterey"  "Monterey"    "$(get_macos_codename 12)"
assert_equals "Ventura"   "Ventura"     "$(get_macos_codename 13)"
assert_equals "Sonoma"    "Sonoma"      "$(get_macos_codename 14)"
assert_equals "Sequoia"   "Sequoia"     "$(get_macos_codename 15)"
assert_equals "Tahoe"     "Tahoe"       "$(get_macos_codename 26)"

# Edge Cases
assert_equals "Unbekannte Version" "macOS 99" "$(get_macos_codename 99)"
assert_equals "Ohne Argument (Default)" "Sonoma" "$(get_macos_codename)"
assert_equals "Version 0"  "macOS 0"  "$(get_macos_codename 0)"
assert_equals "Lücke 16-25" "macOS 20" "$(get_macos_codename 20)"

# Badge-URL-Encoding: Leerzeichen im Codenamen müssen %20-encodiert werden
local name_with_space="$(get_macos_codename 11)"
local encoded="${name_with_space// /%20}"
assert_equals "URL-Encoding Leerzeichen" "Big%20Sur" "$encoded"

local name_without_space="$(get_macos_codename 26)"
local encoded_no_space="${name_without_space// /%20}"
assert_equals "URL-Encoding ohne Leerzeichen" "Tahoe" "$encoded_no_space"

# ============================================================
# has_bootstrap_modules()
# ============================================================
echo ""
echo "=== has_bootstrap_modules ==="

# Echtes Setup → sollte Module haben
if has_bootstrap_modules; then
    echo "  ${C_GREEN:-}✔${C_RESET:-} Echte Module vorhanden"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} Echte Module nicht gefunden"
    (( _TEST_FAILED++ )) || true
fi

# Fixture: Fehlende _core.sh
_ORIG_BOOTSTRAP_MODULES="$BOOTSTRAP_MODULES"
BOOTSTRAP_MODULES="$_TEST_TMPDIR/no-core"
mkdir -p "$BOOTSTRAP_MODULES"

if has_bootstrap_modules; then
    echo "  ${C_RED:-}✖${C_RESET:-} Ohne _core.sh fälschlich erkannt"
    (( _TEST_FAILED++ )) || true
else
    echo "  ${C_GREEN:-}✔${C_RESET:-} Ohne _core.sh korrekt abgelehnt"
    (( _TEST_PASSED++ )) || true
fi

# Fixture: Mit _core.sh
touch "$BOOTSTRAP_MODULES/_core.sh"
if has_bootstrap_modules; then
    echo "  ${C_GREEN:-}✔${C_RESET:-} Mit _core.sh korrekt erkannt"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} Mit _core.sh fälschlich abgelehnt"
    (( _TEST_FAILED++ )) || true
fi

# Fixture: Kein Verzeichnis
BOOTSTRAP_MODULES="$_TEST_TMPDIR/nonexistent"
if has_bootstrap_modules; then
    echo "  ${C_RED:-}✖${C_RESET:-} Nichtexistentes Dir fälschlich erkannt"
    (( _TEST_FAILED++ )) || true
else
    echo "  ${C_GREEN:-}✔${C_RESET:-} Nichtexistentes Dir korrekt abgelehnt"
    (( _TEST_PASSED++ )) || true
fi

BOOTSTRAP_MODULES="$_ORIG_BOOTSTRAP_MODULES"

# ============================================================
# extract_macos_min_version()
# ============================================================
echo ""
echo "=== extract_macos_min_version ==="

# Fixture: validation.sh mit Version
BOOTSTRAP_MODULES="$_TEST_TMPDIR/modules-min"
mkdir -p "$BOOTSTRAP_MODULES"
cat > "$BOOTSTRAP_MODULES/validation.sh" << 'FIXTURE'
#!/usr/bin/env zsh
# Test-Modul
MACOS_MIN_VERSION=15
MACOS_TESTED_VERSION=26
FIXTURE

result=$(extract_macos_min_version 2>/dev/null)
assert_equals "Min-Version aus Fixture" "15" "$result"

# Fixture: Fehlende validation.sh → Fallback 26
BOOTSTRAP_MODULES="$_TEST_TMPDIR/no-validation"
mkdir -p "$BOOTSTRAP_MODULES"

result=$(extract_macos_min_version 2>/dev/null)
assert_equals "Fallback ohne validation.sh" "26" "$result"

# Fixture: validation.sh ohne MACOS_MIN_VERSION → Fallback 26
BOOTSTRAP_MODULES="$_TEST_TMPDIR/modules-empty"
mkdir -p "$BOOTSTRAP_MODULES"
echo "# Nur ein Kommentar" > "$BOOTSTRAP_MODULES/validation.sh"

result=$(extract_macos_min_version 2>/dev/null | tail -1)
assert_equals "Fallback ohne Variable" "26" "$result"

BOOTSTRAP_MODULES="$_ORIG_BOOTSTRAP_MODULES"

# ============================================================
# extract_macos_tested_version()
# ============================================================
echo ""
echo "=== extract_macos_tested_version ==="

BOOTSTRAP_MODULES="$_TEST_TMPDIR/modules-min"

result=$(extract_macos_tested_version 2>/dev/null)
assert_equals "Tested-Version aus Fixture" "26" "$result"

# Fehlende Datei → Fallback
BOOTSTRAP_MODULES="$_TEST_TMPDIR/no-validation"
result=$(extract_macos_tested_version 2>/dev/null)
assert_equals "Fallback ohne validation.sh" "26" "$result"

BOOTSTRAP_MODULES="$_ORIG_BOOTSTRAP_MODULES"

# Integration: Echte validation.sh
result=$(extract_macos_min_version 2>/dev/null)
local real_min_ok=false
[[ "$result" =~ ^[0-9]+$ && "$result" -ge 11 && "$result" -le 99 ]] && real_min_ok=true
if $real_min_ok; then
    echo "  ${C_GREEN:-}✔${C_RESET:-} Echte Min-Version plausibel ($result)"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} Echte Min-Version unplausibel: $result"
    (( _TEST_FAILED++ )) || true
fi

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
