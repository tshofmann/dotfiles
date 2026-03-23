#!/usr/bin/env zsh
# ============================================================
# test-common-macos.sh - Tests für common/macos.sh
# ============================================================
# Zweck       : Unit Tests für get_macos_codename()
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
# Zusammenfassung
# ============================================================
test_summary
