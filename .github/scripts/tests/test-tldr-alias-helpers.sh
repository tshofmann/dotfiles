#!/usr/bin/env zsh
# ============================================================
# test-tldr-alias-helpers.sh - Tests für tldr/alias-helpers.sh
# ============================================================
# Zweck       : Unit Tests für extract_alias_names(), extract_alias_desc(),
#               extract_function_desc(), extract_section_items(),
#               find_config_path(), extract_alias_header_info(),
#               extract_section_names()
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
# extract_alias_names()
# ============================================================
echo "=== extract_alias_names ==="

cat > "$_TEST_TMPDIR/names.alias" << 'FIXTURE'
# ============================================================
# names.alias - Test
# ============================================================
# Zweck       : Test

# Guard
if ! command -v names >/dev/null 2>&1; then return 0; fi

# Erster Alias
alias foo='echo foo'
# Zweiter Alias
alias bar='echo bar'
# Dritter Alias
alias baz='echo baz'
# Vierter Alias
alias qux='echo qux'
FIXTURE

result=$(extract_alias_names "$_TEST_TMPDIR/names.alias" 3)
assert_equals "Erste 3 Aliase" "foo, bar, baz" "$result"

result=$(extract_alias_names "$_TEST_TMPDIR/names.alias" 2)
assert_equals "Erste 2 Aliase" "foo, bar" "$result"

result=$(extract_alias_names "$_TEST_TMPDIR/names.alias")
assert_equals "Default max=3" "foo, bar, baz" "$result"

result=$(extract_alias_names "$_TEST_TMPDIR/names.alias" 10)
assert_equals "Max > Vorhanden" "foo, bar, baz, qux" "$result"

# Datei ohne Aliase
cat > "$_TEST_TMPDIR/no-alias.alias" << 'FIXTURE'
# Nur Funktionen
myfunc() {
    echo "hello"
}
FIXTURE

result=$(extract_alias_names "$_TEST_TMPDIR/no-alias.alias" 3)
assert_empty "Keine Aliase gefunden" "$result"

# ============================================================
# extract_alias_desc()
# ============================================================
echo ""
echo "=== extract_alias_desc ==="

cat > "$_TEST_TMPDIR/desc.alias" << 'FIXTURE'
# cat mit Syntax-Highlighting – Standard-Alias
alias cat='bat'
# Nur Text ohne Zeilennummern
alias catn='bat --plain'

alias nodesc='echo test'
FIXTURE

result=$(extract_alias_desc "$_TEST_TMPDIR/desc.alias" "cat")
assert_equals "Beschreibung vor Trennzeichen" "cat mit Syntax-Highlighting" "$result"

result=$(extract_alias_desc "$_TEST_TMPDIR/desc.alias" "catn")
assert_equals "Beschreibung ohne Trennzeichen" "Nur Text ohne Zeilennummern" "$result"

result=$(extract_alias_desc "$_TEST_TMPDIR/desc.alias" "nodesc")
assert_empty "Keine Beschreibung (keine Kommentarzeile direkt davor)" "$result"

result=$(extract_alias_desc "$_TEST_TMPDIR/desc.alias" "nonexistent")
assert_empty "Nichtexistenter Alias" "$result"

# ============================================================
# extract_function_desc()
# ============================================================
echo ""
echo "=== extract_function_desc ==="

cat > "$_TEST_TMPDIR/funcdesc.alias" << 'FIXTURE'
# ============================================================
# funcdesc.alias - Test
# ============================================================
# Zweck : Test

# Guard
if ! command -v funcdesc >/dev/null 2>&1; then return 0; fi

# ------------------------------------------------------------
# Sektion Eins
# ------------------------------------------------------------
# Dateien suchen – Enter=Öffnen, Ctrl+Y=Kopieren
# Nutzt : fd, bat
myfunc() {
    echo "hello"
}

# ------------------------------------------------------------
# Sektion Zwei
# ------------------------------------------------------------
# Prozesse anzeigen – Tab=Auswählen
procs() {
    echo "procs"
}

# Voraussetzung : gh
nodescfunc() {
    echo "nodesc"
}
FIXTURE

result=$(extract_function_desc "$_TEST_TMPDIR/funcdesc.alias" "myfunc")
assert_equals "Funktion Beschreibung" "Dateien suchen" "$result"

result=$(extract_function_desc "$_TEST_TMPDIR/funcdesc.alias" "procs")
assert_equals "Funktion Beschreibung (zweite)" "Prozesse anzeigen" "$result"

result=$(extract_function_desc "$_TEST_TMPDIR/funcdesc.alias" "nonexistent")
assert_empty "Nichtexistente Funktion" "$result"

# ============================================================
# extract_section_items()
# ============================================================
echo ""
echo "=== extract_section_items ==="

cat > "$_TEST_TMPDIR/sections.alias" << 'FIXTURE'
# ============================================================
# sections.alias - Test
# ============================================================
# Zweck       : Test

# Guard
if ! command -v sections >/dev/null 2>&1; then return 0; fi

# ------------------------------------------------------------
# Update & Wartung
# ------------------------------------------------------------
# Alle Pakete aktualisieren
alias bup='brew update && brew upgrade'
# Verwaiste Pakete anzeigen
alias bout='brew autoremove --dry-run'

# Interaktives Update – Enter=Installieren
brew-update() {
    echo "update"
}

# ------------------------------------------------------------
# Suche & Info
# ------------------------------------------------------------
# Paket suchen
alias bse='brew search'
# Paket-Info anzeigen
alias binfo='brew info'
FIXTURE

result=$(extract_section_items "$_TEST_TMPDIR/sections.alias" "Update & Wartung")
assert_contains "Alias bup erkannt" "bup|" "$result"
assert_contains "Alias bout erkannt" "bout|" "$result"
assert_contains "Funktion brew-update erkannt" "brew-update|" "$result"
assert_contains "Beschreibung Alias" "Alle Pakete aktualisieren" "$result"
assert_contains "Beschreibung Funktion" "Interaktives Update" "$result"

# Zweite Sektion
result=$(extract_section_items "$_TEST_TMPDIR/sections.alias" "Suche & Info")
assert_contains "Zweite Sektion: bse" "bse|" "$result"
assert_contains "Zweite Sektion: binfo" "binfo|" "$result"
# Erste Sektion darf nicht auftauchen
local bup_count
bup_count=$(echo "$result" | grep -c "bup" || true)
assert_equals "bup nicht in Suche & Info" "0" "$bup_count"

# Nichtexistente Sektion
result=$(extract_section_items "$_TEST_TMPDIR/sections.alias" "Gibts Nicht")
assert_empty "Nichtexistente Sektion" "$result"

# Guard-Einrückung: Items innerhalb eines Guards
cat > "$_TEST_TMPDIR/guarded.alias" << 'FIXTURE'
# ============================================================
# guarded.alias - Test
# ============================================================
# Zweck       : Test

# Guard
if ! command -v guarded >/dev/null 2>&1; then return 0; fi

# ------------------------------------------------------------
# Geschützte Befehle
# ------------------------------------------------------------
if command -v sometool >/dev/null 2>&1; then
    # Geschützter Alias
    alias gtool='sometool --fancy'
fi
FIXTURE

result=$(extract_section_items "$_TEST_TMPDIR/guarded.alias" "Geschützte Befehle")
assert_contains "Guard-eingerückter Alias" "gtool|" "$result"

# ============================================================
# find_config_path()
# ============================================================
echo ""
echo "=== find_config_path ==="

# Fixture: Config-Verzeichnis mit Pfad-Header
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles"
mkdir -p "$DOTFILES_DIR/terminal/.config/testtool"

cat > "$DOTFILES_DIR/terminal/.config/testtool/config" << 'FIXTURE'
# ============================================================
# config - Testtool Konfiguration
# ============================================================
# Pfad        : ~/.config/testtool/config
# Zweck       : Konfiguration für Testtool
# ============================================================
some_option = true
FIXTURE

result=$(find_config_path "testtool")
assert_contains "Config-Pfad gefunden" "~/.config/testtool/config" "$result"
assert_contains "Zweck angehängt" "Konfiguration für Testtool" "$result"

# Mapping: rg → ripgrep
mkdir -p "$DOTFILES_DIR/terminal/.config/ripgrep"
cat > "$DOTFILES_DIR/terminal/.config/ripgrep/config" << 'FIXTURE'
# Pfad        : ~/.config/ripgrep/config
# Zweck       : Ripgrep Konfiguration
FIXTURE

result=$(find_config_path "rg")
assert_contains "Mapping rg → ripgrep" "~/.config/ripgrep/config" "$result"

# Tool ohne Config-Verzeichnis
result=$(find_config_path "nonexistenttool")
assert_empty "Kein Config-Verzeichnis" "$result"

# Tool mit Config-Verzeichnis aber ohne Pfad-Header
mkdir -p "$DOTFILES_DIR/terminal/.config/noheader"
echo "some_option = true" > "$DOTFILES_DIR/terminal/.config/noheader/config"

result=$(find_config_path "noheader")
assert_empty "Config ohne Pfad-Header" "$result"

DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

# ============================================================
# extract_alias_header_info()
# ============================================================
echo ""
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

# Pipe-Trennung prüfen (6 Felder: tool|zweck|docs|nutzt|config|hinweis)
local field_count
field_count=$(echo "$result" | tr '|' '\n' | wc -l)
assert_equals "6 Pipe-getrennte Felder" "6" "${field_count##* }"

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
# Config      : - (kein XDG-Support)
# Nutzt       : -
# ============================================================

# Guard
if ! command -v standalone >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(extract_alias_header_info "$_TEST_TMPDIR/standalone.alias")
assert_contains "Standalone: Strich-Felder normalisiert" "|https://example.com||" "$result"

# Header mit Hinweis
cat > "$_TEST_TMPDIR/hinweis.alias" << 'FIXTURE'
# ============================================================
# hinweis.alias - Tool mit Hinweis
# ============================================================
# Zweck       : Testet Hinweis-Extraktion
# Hinweis     : Automatischer Check alle 12h – zeigt
#               Benachrichtigung wenn Updates verfügbar sind.
# ============================================================

# Guard
if ! command -v hinweis >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(extract_alias_header_info "$_TEST_TMPDIR/hinweis.alias")
assert_contains "Hinweis erkannt" "Automatischer Check alle 12h" "$result"
assert_contains "Hinweis mehrzeilig" "Benachrichtigung wenn Updates" "$result"

# ============================================================
# extract_section_names()
# ============================================================
echo ""
echo "=== extract_section_names ==="

# Fixture mit mehreren Sektionen
cat > "$_TEST_TMPDIR/multi-section.alias" << 'FIXTURE'
# ============================================================
# multi.alias - Test
# ============================================================
# Zweck       : Test-Datei
# ============================================================

# ------------------------------------------------------------
# Erste Sektion
# ------------------------------------------------------------
alias foo='bar'

# ------------------------------------------------------------
# Zweite Sektion
# ------------------------------------------------------------
alias baz='qux'
FIXTURE

result=$(extract_section_names "$_TEST_TMPDIR/multi-section.alias")
assert_contains "Erste Sektion erkannt" "Erste Sektion" "$result"
assert_contains "Zweite Sektion erkannt" "Zweite Sektion" "$result"

# Reihenfolge prüfen
first_line=$(echo "$result" | head -1)
assert_equals "Reihenfolge: Erste zuerst" "Erste Sektion" "$first_line"

# Kein falscher Treffer durch Datei-Header (# ===)
result_lines=$(echo "$result" | wc -l | tr -d ' ')
assert_equals "Nur 2 Sektionen (Header ignoriert)" "2" "$result_lines"

# Fixture ohne Sektionen (nur Header)
cat > "$_TEST_TMPDIR/no-section.alias" << 'FIXTURE'
# ============================================================
# nosect.alias - Keine Sektionen
# ============================================================
# Zweck       : Test
# ============================================================

alias foo='bar'
FIXTURE

result=$(extract_section_names "$_TEST_TMPDIR/no-section.alias")
assert_empty "Keine Sektionen erkannt" "$result"

# Integration: brew.alias hat mindestens 5 Sektionen
result=$(extract_section_names "$ALIAS_DIR/brew.alias")
count=$(echo "$result" | wc -l | tr -d ' ')
if (( count >= 5 )); then
    echo "  ${C_GREEN:-}✔${C_RESET:-} brew.alias: >= 5 Sektionen ($count)"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} brew.alias: >= 5 Sektionen erwartet, $count gefunden"
    (( _TEST_FAILED++ )) || true
fi

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
