#!/usr/bin/env zsh
# ============================================================
# test-tldr-alias-helpers.sh - Tests für tldr/alias-helpers.sh
# ============================================================
# Zweck       : Unit Tests für extract_alias_header_info()
# Pfad        : .github/scripts/tests/test-tldr-alias-helpers.sh
# Aufruf      : ./.github/scripts/tests/test-tldr-alias-helpers.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Pfade für Dependencies
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"
ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"

# Zu testende Module (alias-helpers.sh braucht common/parsers.sh)
source "$SCRIPT_DIR/../generators/common/parsers.sh"
source "$SCRIPT_DIR/../generators/tldr/alias-helpers.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# ============================================================
# extract_alias_header_info()
# ============================================================
echo "=== extract_alias_header_info ==="

# Vollständiger Header
cat > "$_TEST_TMPDIR/bat.alias" << 'FIXTURE'
# ============================================================
# bat.alias - Aliase für bat (cat mit Syntax-Highlighting)
# ============================================================
# Zweck       : Aliase für bat mit verschiedenen Ausgabe-Stilen
# Pfad        : ~/.config/alias/bat.alias
# Docs        : https://github.com/sharkdp/bat
# Config      : ~/.config/bat/config
# Nutzt       : fzf (Theme-Browser)
# Ersetzt     : cat (mit Syntax-Highlighting)
# Aliase      : cat, catn, catd, bat-theme
# ============================================================

# Guard
if ! command -v bat >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(extract_alias_header_info "$_TEST_TMPDIR/bat.alias")
assert_contains "Tool-Name erkannt" "bat|" "$result"
assert_contains "Zweck erkannt" "Aliase für bat" "$result"
assert_contains "Docs erkannt" "https://github.com/sharkdp/bat" "$result"
assert_contains "Nutzt erkannt" "fzf (Theme-Browser)" "$result"
assert_contains "Config erkannt" "~/.config/bat/config" "$result"

# Pipe-Trennung prüfen (5 Felder)
local field_count
field_count=$(echo "$result" | tr '|' '\n' | wc -l)
assert_equals "5 Pipe-getrennte Felder" "5" "${field_count##* }"

# Header ohne optionale Felder
cat > "$_TEST_TMPDIR/minimal.alias" << 'FIXTURE'
# ============================================================
# minimal.alias - Minimaler Header
# ============================================================
# Zweck       : Nur das Nötigste
# ============================================================

# Guard
if ! command -v minimal >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(extract_alias_header_info "$_TEST_TMPDIR/minimal.alias")
assert_contains "Minimaler Tool-Name" "minimal|" "$result"
assert_contains "Minimaler Zweck" "Nur das Nötigste" "$result"

# Nutzt mit Strich (keine Abhängigkeiten)
cat > "$_TEST_TMPDIR/standalone.alias" << 'FIXTURE'
# ============================================================
# standalone.alias - Standalone-Tool
# ============================================================
# Zweck       : Standalone ohne Abhängigkeiten
# Docs        : https://example.com
# Nutzt       : -
# ============================================================

# Guard
if ! command -v standalone >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(extract_alias_header_info "$_TEST_TMPDIR/standalone.alias")
assert_contains "Standalone: Nutzt = Strich" "|-|" "$result"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
