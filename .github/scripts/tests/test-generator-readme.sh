#!/usr/bin/env zsh
# ============================================================
# test-generator-readme.sh - Tests für generators/readme.sh
# ============================================================
# Zweck       : Unit Tests für generate_tool_replacements_table()
# Pfad        : .github/scripts/tests/test-generator-readme.sh
# Aufruf      : ./.github/scripts/tests/test-generator-readme.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# readme.sh → common.sh → config.sh + parsers.sh (alles in einem Source-Durchlauf)
# Guard: Nur Funktionen laden, nicht den Generator ausführen
_SOURCED_BY_GENERATOR=1
source "$SCRIPT_DIR/../generators/readme.sh"

# Pfade aus common.sh sind jetzt gesetzt (DOTFILES_DIR, ALIAS_DIR etc.)

# ============================================================
# generate_tool_replacements_table() – mit echtem ALIAS_DIR
# ============================================================
echo "=== generate_tool_replacements_table (Integration) ==="

result=$(generate_tool_replacements_table)

# Tabellen-Header prüfen
assert_contains "Tabellen-Header Vorher" "| Vorher" "$result"
assert_contains "Tabellen-Header Nachher" "| Nachher" "$result"
assert_contains "Tabellen-Header Vorteil" "| Vorteil" "$result"
assert_contains "Header-Separator" "| ------" "$result"

# Mindestens eine Tool-Ersetzung vorhanden (bat.alias hat Ersetzt: cat)
assert_contains "bat ersetzt cat" "cat" "$result"
assert_contains "bat als Nachher" "bat" "$result"

# ============================================================
# generate_tool_replacements_table() – mit Fixture-Verzeichnis
# ============================================================
echo ""
echo "=== generate_tool_replacements_table (Fixture) ==="

# Eigenes ALIAS_DIR mit kontrollierten Fixtures
_ORIG_ALIAS_DIR="$ALIAS_DIR"
ALIAS_DIR="$_TEST_TMPDIR/alias"
mkdir -p "$ALIAS_DIR"

cat > "$ALIAS_DIR/newtool.alias" << 'FIXTURE'
# ============================================================
# newtool.alias - Neues Tool
# ============================================================
# Zweck       : Bessere Dateiliste
# Ersetzt     : ls (mit Icons und Git-Status)
# ============================================================

# Guard
if ! command -v newtool >/dev/null 2>&1; then return 0; fi
FIXTURE

cat > "$ALIAS_DIR/other.alias" << 'FIXTURE'
# ============================================================
# other.alias - Anderes Tool
# ============================================================
# Zweck       : Test-Tool
# Ersetzt     : find (schneller und einfacher)
# ============================================================

# Guard
if ! command -v other >/dev/null 2>&1; then return 0; fi
FIXTURE

# Datei OHNE Ersetzt-Feld (sollte ignoriert werden)
cat > "$ALIAS_DIR/noersetzt.alias" << 'FIXTURE'
# ============================================================
# noersetzt.alias - Kein Ersetzt-Feld
# ============================================================
# Zweck       : Test

# Guard
if ! command -v noersetzt >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(generate_tool_replacements_table)

assert_contains "Fixture: ls als Vorher" '`ls`' "$result"
assert_contains "Fixture: newtool als Nachher" '`newtool`' "$result"
assert_contains "Fixture: find als Vorher" '`find`' "$result"
assert_contains "Fixture: other als Nachher" '`other`' "$result"
assert_contains "Fixture: Vorteil für ls" "mit Icons und Git-Status" "$result"

# noersetzt sollte nicht in der Tabelle auftauchen
# (Prüfung: Datei ohne Ersetzt-Feld)
local line_count
line_count=$(echo "$result" | wc -l)
# 2 Header-Zeilen + 2 Datenzeilen = 4
assert_equals "Fixture: 4 Zeilen (Header + 2 Ersetzungen)" "4" "${line_count##* }"

# ALIAS_DIR zurücksetzen
ALIAS_DIR="$_ORIG_ALIAS_DIR"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
