#!/usr/bin/env zsh
# ============================================================
# test-common-parsers.sh - Tests für common/parsers.sh
# ============================================================
# Zweck       : Unit Tests für parse_description_comment(),
#               parse_alias_command(), parse_header_field()
#               und extract_usage_codeblock()
# Pfad        : .github/scripts/tests/test-common-parsers.sh
# Aufruf      : ./.github/scripts/tests/test-common-parsers.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"
source "$SCRIPT_DIR/../generators/common/parsers.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# ============================================================
# parse_description_comment()
# ============================================================
echo "=== parse_description_comment ==="

# Format: name|param|suffix (Keybindings oder Text nach Separator)|description

# Standard: Name(param?) – Key=Aktion
result=$(parse_description_comment "# Navigate(query?) – Enter=Öffnen, Ctrl+Y=Kopieren")
assert_contains "Name erkannt" "Navigate|" "$result"
assert_contains "Parameter erkannt" "query?" "$result"
assert_contains "Keybinding Enter" "Enter=Öffnen" "$result"
assert_contains "Keybinding Ctrl+Y" "Ctrl+Y=Kopieren" "$result"

# Ohne Parameter
result=$(parse_description_comment "# listall – Zeigt alle Einträge")
assert_equals "Ohne Parameter" "listall||Zeigt alle Einträge|listall" "$result"

# Ohne Keybindings
result=$(parse_description_comment "# cleanup")
assert_equals "Nur Name" "cleanup|||cleanup" "$result"

# Mit Leerzeichen vor Klammer (kein Parameter!)
result=$(parse_description_comment "# procs (interaktiv) – Enter=Öffnen")
assert_contains "Leerzeichen vor Klammer = kein Param" "|Enter=Öffnen|" "$result"

# ASCII-Hyphen statt EN-DASH
result=$(parse_description_comment "# finder - Enter=Öffnen")
assert_contains "ASCII-Hyphen als Separator" "Enter=Öffnen" "$result"

# Mehrere Parameter
result=$(parse_description_comment "# search(pattern, dir?) – Tab=Auswählen")
assert_contains "Mehrere Parameter" "pattern, dir?" "$result"

# ============================================================
# parse_alias_command()
# ============================================================
echo ""
echo "=== parse_alias_command ==="

# Einfacher Alias
result=$(parse_alias_command "alias ll='eza -la'")
assert_equals "Einfacher Alias" "eza -la" "$result"

# Mit Flags
result=$(parse_alias_command "alias cat='bat --paging=never'")
assert_equals "Mit Flags" "bat --paging=never" "$result"

# Mit Pipe
result=$(parse_alias_command "alias top='btop --utf-force | head'")
assert_equals "Mit Pipe" "btop --utf-force | head" "$result"

# Double-Quoted Alias
result=$(parse_alias_command 'alias grp="grep --color=auto"')
assert_equals "Double-Quoted" "grep --color=auto" "$result"

# Alias mit nachfolgendem Kommentar (nach schließendem Quote)
result=$(parse_alias_command "alias ls='eza'                # Besseres ls")
assert_equals "Trailing Comment ignoriert" "eza" "$result"

# Leerer Alias
result=$(parse_alias_command "alias x=''")
assert_empty "Leerer Alias" "$result"

# ============================================================
# parse_header_field()
# ============================================================
echo ""
echo "=== parse_header_field ==="

# Standard-Feld extrahieren
cat > "$_TEST_TMPDIR/basic.alias" << 'FIXTURE'
# ============================================================
# basic.alias - Beschreibung
# ============================================================
# Zweck       : Dateien konvertieren
# Pfad        : ~/.config/alias/basic.alias
# Docs        : https://example.com
# Nutzt       : fzf, bat
# Ersetzt     : cat (mit Syntax-Highlighting)
# ============================================================

# Guard
if ! command -v basic >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(parse_header_field "$_TEST_TMPDIR/basic.alias" "Zweck")
assert_equals "Zweck-Feld extrahieren" "Dateien konvertieren" "$result"

result=$(parse_header_field "$_TEST_TMPDIR/basic.alias" "Docs")
assert_equals "Docs-Feld extrahieren" "https://example.com" "$result"

result=$(parse_header_field "$_TEST_TMPDIR/basic.alias" "Nutzt")
assert_equals "Mehrere Abhängigkeiten" "fzf, bat" "$result"

result=$(parse_header_field "$_TEST_TMPDIR/basic.alias" "Ersetzt")
assert_equals "Ersetzt-Feld mit Klammer" "cat (mit Syntax-Highlighting)" "$result"

# Strich als Wert (keine Abhängigkeiten)
cat > "$_TEST_TMPDIR/dash.alias" << 'FIXTURE'
# ============================================================
# dash.alias - Beschreibung
# ============================================================
# Nutzt       : -
# ============================================================

# Guard
if ! command -v dash >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(parse_header_field "$_TEST_TMPDIR/dash.alias" "Nutzt")
assert_equals "Strich als Wert" "-" "$result"

# Nichtexistentes Feld
result=$(parse_header_field "$_TEST_TMPDIR/basic.alias" "Gibtsnet")
assert_empty "Nichtexistentes Feld" "$result"

# Mehrzeilige Fortsetzung (Einrückung nach Feldname)
cat > "$_TEST_TMPDIR/multi.alias" << 'FIXTURE'
# ============================================================
# multi.alias - Beschreibung
# ============================================================
# Nutzt       : fzf, bat, eza, fd, tldr,
#               pdftotext, 7zz
# ============================================================

# Guard
if ! command -v multi >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(parse_header_field "$_TEST_TMPDIR/multi.alias" "Nutzt")
assert_contains "Mehrzeilige Fortsetzung" "fzf, bat" "$result"
assert_contains "Fortsetzung enthält zweite Zeile" "pdftotext, 7zz" "$result"

# ============================================================
# extract_usage_codeblock()
# ============================================================
echo ""
echo "=== extract_usage_codeblock ==="

# Alias-Datei mit Sektionen und Guard
cat > "$_TEST_TMPDIR/usage.alias" << 'FIXTURE'
# ============================================================
# usage.alias - Test-Datei
# ============================================================
# Zweck       : Test
# ============================================================

# Guard
if ! command -v usage >/dev/null 2>&1; then return 0; fi

# ------------------------------------------------------------
# Dateiansicht
# ------------------------------------------------------------
# Ersetzt cat mit Highlighting
alias cat='bat -pp'

# Mit Zeilennummern
alias catn='bat --style=numbers'

# ------------------------------------------------------------
# Themes
# ------------------------------------------------------------
# Theme-Browser(query?) – Enter=Auswählen
bat-theme() {
    bat --list-themes | fzf
}
FIXTURE

result=$(extract_usage_codeblock "$_TEST_TMPDIR/usage.alias")

assert_contains "Alias cat im Codeblock" "cat" "$result"
assert_contains "Alias catn im Codeblock" "catn" "$result"
assert_contains "Funktion bat-theme im Codeblock" "bat-theme" "$result"
assert_contains "Beschreibung im Codeblock" "Ersetzt cat mit Highlighting" "$result"
assert_contains "Sektionsheader Dateiansicht" "# Dateiansicht" "$result"
assert_contains "Sektionsheader Themes" "# Themes" "$result"

# Leere Datei (nur Header + Guard)
cat > "$_TEST_TMPDIR/empty.alias" << 'FIXTURE'
# ============================================================
# empty.alias - Leere Datei
# ============================================================
# Zweck       : Test

# Guard
if ! command -v empty >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(extract_usage_codeblock "$_TEST_TMPDIR/empty.alias")
assert_empty "Leere Datei liefert leeren Codeblock" "$result"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
