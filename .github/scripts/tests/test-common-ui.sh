#!/usr/bin/env zsh
# ============================================================
# test-common-ui.sh - Tests für common/ui.sh
# ============================================================
# Zweck       : Unit Tests für ui_banner(), ui_section(),
#               ui_footer(), compare_content(), write_if_changed()
# Pfad        : .github/scripts/tests/test-common-ui.sh
# Aufruf      : ./.github/scripts/tests/test-common-ui.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# ui.sh wird via common.sh geladen – braucht config.sh Pfade
# Guard: Nur Funktionen laden, nicht den Generator ausführen
_SOURCED_BY_GENERATOR=1
source "$SCRIPT_DIR/../generators/common.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# ============================================================
# ui_banner()
# ============================================================
echo "=== ui_banner ==="

result=$(ui_banner "🔍" "Test-Banner")
assert_contains "Banner enthält Titel" "Test-Banner" "$result"
assert_contains "Banner enthält Emoji" "🔍" "$result"
# Trennlinie vorhanden (UI_LINE = ━━━...━━━)
assert_contains "Banner enthält Trennlinie" "━" "$result"

# ============================================================
# ui_section()
# ============================================================
echo ""
echo "=== ui_section ==="

result=$(ui_section "Symlinks")
assert_contains "Section enthält Titel" "Symlinks" "$result"
assert_contains "Section enthält Trennzeichen" "━━━" "$result"

# ============================================================
# ui_footer()
# ============================================================
echo ""
echo "=== ui_footer ==="

result=$(ui_footer)
assert_contains "Footer enthält Trennlinie" "━" "$result"

# ============================================================
# compare_content()
# ============================================================
echo ""
echo "=== compare_content ==="

# Gleicher Inhalt → Return 0
echo -n "Testinhalt" > "$_TEST_TMPDIR/same.txt"
if compare_content "$_TEST_TMPDIR/same.txt" "Testinhalt"; then
    echo "  ${C_GREEN:-}✔${C_RESET:-} Gleicher Inhalt → true"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} Gleicher Inhalt sollte true sein"
    (( _TEST_FAILED++ )) || true
fi

# Unterschiedlicher Inhalt → Return 1
if compare_content "$_TEST_TMPDIR/same.txt" "Anderer Inhalt"; then
    echo "  ${C_RED:-}✖${C_RESET:-} Unterschiedlicher Inhalt sollte false sein"
    (( _TEST_FAILED++ )) || true
else
    echo "  ${C_GREEN:-}✔${C_RESET:-} Unterschiedlicher Inhalt → false"
    (( _TEST_PASSED++ )) || true
fi

# Nichtexistente Datei → Return 1
if compare_content "$_TEST_TMPDIR/nonexistent.txt" "Content"; then
    echo "  ${C_RED:-}✖${C_RESET:-} Nichtexistente Datei sollte false sein"
    (( _TEST_FAILED++ )) || true
else
    echo "  ${C_GREEN:-}✔${C_RESET:-} Nichtexistente Datei → false"
    (( _TEST_PASSED++ )) || true
fi

# Leere Datei vs leerer String
echo -n "" > "$_TEST_TMPDIR/empty.txt"
if compare_content "$_TEST_TMPDIR/empty.txt" ""; then
    echo "  ${C_GREEN:-}✔${C_RESET:-} Leere Datei vs leerer String → true"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} Leere Datei vs leerer String sollte true sein"
    (( _TEST_FAILED++ )) || true
fi

# ============================================================
# write_if_changed()
# ============================================================
echo ""
echo "=== write_if_changed ==="

# Neue Datei anlegen
local test_file="$_TEST_TMPDIR/output.md"
result=$(write_if_changed "$test_file" "Neuer Inhalt" 2>&1)
assert_contains "Neue Datei: Generiert-Meldung" "Generiert" "$result"
# Datei existiert und hat korrekten Inhalt
local file_content
file_content=$(command cat "$test_file")
assert_equals "Neuer Inhalt geschrieben" "Neuer Inhalt" "$file_content"

# Gleicher Inhalt → "Unverändert"
result=$(write_if_changed "$test_file" "Neuer Inhalt" 2>&1)
assert_contains "Gleicher Inhalt: Unverändert" "Unverändert" "$result"

# Geänderter Inhalt → "Generiert"
result=$(write_if_changed "$test_file" "Aktualisierter Inhalt" 2>&1)
assert_contains "Geänderter Inhalt: Generiert" "Generiert" "$result"
file_content=$(command cat "$test_file")
assert_equals "Aktualisierter Inhalt" "Aktualisierter Inhalt" "$file_content"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
