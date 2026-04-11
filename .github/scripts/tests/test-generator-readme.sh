#!/usr/bin/env zsh
# ============================================================
# test-generator-readme.sh - Tests für generators/readme.sh
# ============================================================
# Zweck       : Unit Tests für generate_tool_replacements_table(),
#               extract_fzf_functions(), generate_fzf_workflows_table(),
#               generate_media_toolkit_table(),
#               generate_shell_keybindings_table(),
#               generate_utility_tools_table(),
#               heading_to_anchor(), generate_toc()
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
# extract_fzf_functions() – Fixture
# ============================================================
echo ""
echo "=== extract_fzf_functions (Fixture) ==="

# Alias-Datei mit gemischten Funktionen (einige mit fzf, einige ohne)
_FZF_FUNC_FILE="$_TEST_TMPDIR/mixed.alias"
cat > "$_FZF_FUNC_FILE" << 'FIXTURE'
# ============================================================
# mixed.alias - Gemischtes Tool
# ============================================================
# Nutzt       : fzf, bat
# Aliase      : func_with_fzf, func_plain, plain_alias
# ============================================================

alias plain_alias='echo hi'

func_with_fzf() {
    local selection
    selection=$(ls | fzf --preview 'cat {}')
    echo "$selection"
}

func_plain() {
    echo "kein fuzzy hier"
}
FIXTURE

# Nicht-fzf-Datei: nur Funktionen mit fzf-Aufruf
result=$(extract_fzf_functions "$_FZF_FUNC_FILE" "0")
assert_contains "fzf-Funktion erkannt" "func_with_fzf" "$result"
# func_plain hat kein fzf im Body
[[ "$result" != *func_plain* ]]
assert_equals "Ohne-fzf-Funktion ausgeschlossen" "0" "$?"
# plain_alias ist kein Funktionsdefinition (kein name() {)
[[ "$result" != *plain_alias* ]]
assert_equals "Alias ausgeschlossen" "0" "$?"

# fzf-Datei: alle Funktionen gelten als fzf-Workflows
result=$(extract_fzf_functions "$_FZF_FUNC_FILE" "1")
assert_contains "fzf-Datei: func_with_fzf" "func_with_fzf" "$result"
assert_contains "fzf-Datei: func_plain" "func_plain" "$result"

# Leere Datei: keine Funktionen
_FZF_EMPTY="$_TEST_TMPDIR/empty.alias"
cat > "$_FZF_EMPTY" << 'FIXTURE'
# ============================================================
# empty.alias - Leer
# ============================================================
# Aliase      :
# ============================================================
FIXTURE
result=$(extract_fzf_functions "$_FZF_EMPTY" "0")
assert_equals "Leerer Aliase-Header" "" "$result"

# ============================================================
# generate_fzf_workflows_table() – Fixture
# ============================================================
echo ""
echo "=== generate_fzf_workflows_table (Fixture) ==="

_ORIG_ALIAS_DIR2="$ALIAS_DIR"
ALIAS_DIR="$_TEST_TMPDIR/alias-fzf"
mkdir -p "$ALIAS_DIR"

# fzf.alias: ist selbst das fzf-Tool → alle Funktionen zählen
cat > "$ALIAS_DIR/fzf.alias" << 'FIXTURE'
# ============================================================
# fzf.alias - Fuzzy Finder
# ============================================================
# Aliase      : procs, envs
# ============================================================

procs() {
    ps aux | fzf
}

envs() {
    env | fzf
}
FIXTURE

# git.alias: nutzt fzf → Funktionen mit fzf-Aufruf zählen
cat > "$ALIAS_DIR/git.alias" << 'FIXTURE'
# ============================================================
# git.alias - Git Workflow
# ============================================================
# Nutzt       : fzf
# Aliase      : gco, gst
# ============================================================

gco() {
    git branch | fzf | xargs git checkout
}

gst() {
    git status
}
FIXTURE

result=$(generate_fzf_workflows_table)
assert_contains "Tabellen-Header Bereich" "| Bereich" "$result"
assert_contains "Tabellen-Header Funktionen" "| Funktionen" "$result"
assert_contains "Git-Kategorie" "| Git |" "$result"
assert_contains "gco erkannt" '`gco`' "$result"
# gst hat kein fzf im Body → ausgeschlossen
[[ "$result" != *'`gst`'* ]]
assert_equals "gst (kein fzf) ausgeschlossen" "0" "$?"
assert_contains "System-Kategorie (fzf)" "| System |" "$result"
assert_contains "procs erkannt" '`procs`' "$result"
assert_contains "envs erkannt" '`envs`' "$result"

ALIAS_DIR="$_ORIG_ALIAS_DIR2"

# ============================================================
# generate_media_toolkit_table() – Fixture
# ============================================================
echo ""
echo "=== generate_media_toolkit_table (Fixture) ==="

_ORIG_ALIAS_DIR3="$ALIAS_DIR"
ALIAS_DIR="$_TEST_TMPDIR/alias-media"
mkdir -p "$ALIAS_DIR"

cat > "$ALIAS_DIR/ffmpeg.alias" << 'FIXTURE'
# ============================================================
# ffmpeg.alias - Video-Konverter
# ============================================================
# Aliase      : vid2gif, vidcompress
# ============================================================
FIXTURE

cat > "$ALIAS_DIR/magick.alias" << 'FIXTURE'
# ============================================================
# magick.alias - ImageMagick
# ============================================================
# Aliase      : imgresize
# ============================================================
FIXTURE

# exiftool ohne Aliase-Header → sollte übersprungen werden
cat > "$ALIAS_DIR/exiftool.alias" << 'FIXTURE'
# ============================================================
# exiftool.alias - EXIF Tool
# ============================================================
# Zweck       : Nur EXIF lesen
# ============================================================
FIXTURE

result=$(generate_media_toolkit_table)
assert_contains "Media: Tabellen-Header" "| Tool |" "$result"
assert_contains "Media: ffmpeg vorhanden" "| ffmpeg |" "$result"
assert_contains "Media: vid2gif" '`vid2gif`' "$result"
assert_contains "Media: vidcompress" '`vidcompress`' "$result"
assert_contains "Media: magick vorhanden" "| magick |" "$result"
assert_contains "Media: imgresize" '`imgresize`' "$result"
# exiftool hat leeren Aliase-Header → ausgeschlossen
[[ "$result" != *"| exiftool |"* ]]
assert_equals "Media: exiftool übersprungen" "0" "$?"

ALIAS_DIR="$_ORIG_ALIAS_DIR3"

# ============================================================
# generate_shell_keybindings_table() – Fixture
# ============================================================
echo ""
echo "=== generate_shell_keybindings_table (Fixture) ==="

_ORIG_FZF_DIR="$FZF_DIR"
FZF_DIR="$_TEST_TMPDIR/fzf-config"
mkdir -p "$FZF_DIR"

cat > "$FZF_DIR/init.zsh" << 'FIXTURE'
# fzf Keybindings
bindkey '^X1' fzf-history-widget         # Ctrl+X 1 = Befehlsverlauf durchsuchen
bindkey '^X2' fzf-file-widget            # Ctrl+X 2 = Dateien im Verzeichnis suchen
bindkey '^X3' fzf-cd-widget              # Ctrl+X 3 = In Unterverzeichnis wechseln
# Andere Zeilen (kein bindkey)
export FZF_DEFAULT_OPTS="--height 40%"
FIXTURE

result=$(generate_shell_keybindings_table)
assert_contains "Keybindings: Tabellen-Header" "| Keybinding |" "$result"
assert_contains "Keybindings: Ctrl+X 1" '`Ctrl+X 1`' "$result"
assert_contains "Keybindings: Befehlsverlauf" "Befehlsverlauf durchsuchen" "$result"
assert_contains "Keybindings: Ctrl+X 2" '`Ctrl+X 2`' "$result"
assert_contains "Keybindings: Ctrl+X 3" '`Ctrl+X 3`' "$result"
assert_contains "Keybindings: Unterverzeichnis" "In Unterverzeichnis wechseln" "$result"

# FZF_DIR ohne init.zsh → leere Ausgabe
FZF_DIR="$_TEST_TMPDIR/fzf-missing"
mkdir -p "$FZF_DIR"
result=$(generate_shell_keybindings_table)
assert_equals "Fehlende init.zsh: leer" "" "$result"

FZF_DIR="$_ORIG_FZF_DIR"

# ============================================================
# generate_utility_tools_table() – Fixture
# ============================================================
echo ""
echo "=== generate_utility_tools_table (Fixture) ==="

_ORIG_ALIAS_DIR4="$ALIAS_DIR"
ALIAS_DIR="$_TEST_TMPDIR/alias-utility"
mkdir -p "$ALIAS_DIR"

cat > "$ALIAS_DIR/markdownlint.alias" << 'FIXTURE'
# ============================================================
# markdownlint.alias - Markdown Linter
# ============================================================
# Aliase      : mdlint, mdfix
# ============================================================
FIXTURE

result=$(generate_utility_tools_table)
assert_contains "Utility: Tabellen-Header" "| Tool |" "$result"
assert_contains "Utility: markdownlint" "| markdownlint |" "$result"
assert_contains "Utility: mdlint" '`mdlint`' "$result"
assert_contains "Utility: mdfix" '`mdfix`' "$result"

# Ohne markdownlint.alias → keine Datenzeilen
ALIAS_DIR="$_TEST_TMPDIR/alias-empty"
mkdir -p "$ALIAS_DIR"
result=$(generate_utility_tools_table)
local line_count
line_count=$(echo "$result" | wc -l)
assert_equals "Utility: nur Header (2 Zeilen)" "2" "${line_count##* }"

ALIAS_DIR="$_ORIG_ALIAS_DIR4"

# ============================================================
# heading_to_anchor() – Unit Tests
# ============================================================
echo ""
echo "=== heading_to_anchor (Unit) ==="

# Emoji-Entfernung + Kleinschreibung + Leerzeichen → Bindestrich
assert_equals "Emoji-Anker (✨)" "-was-du-bekommst" "$(heading_to_anchor '✨ Was du bekommst')"
assert_equals "Emoji-Anker (🚀)" "-installation" "$(heading_to_anchor '🚀 Installation')"
assert_equals "Emoji-Anker (📖)" "-dokumentation" "$(heading_to_anchor '📖 Dokumentation')"
assert_equals "Emoji-Anker (🙏)" "-credits" "$(heading_to_anchor '🙏 Credits')"

# Ohne Emoji
assert_equals "Ohne Emoji" "deinstallation" "$(heading_to_anchor 'Deinstallation')"
assert_equals "Ohne Emoji (Lizenz)" "lizenz" "$(heading_to_anchor 'Lizenz')"

# Klammern und Sonderzeichen werden entfernt
assert_equals "Klammern entfernt" "interaktive-workflows-fzf" "$(heading_to_anchor 'Interaktive Workflows (fzf)')"

# Bindestrich bleibt erhalten
assert_equals "Bindestrich erhalten" "media-toolkit" "$(heading_to_anchor 'Media-Toolkit')"

# Umlaute bleiben erhalten (GitHub behält Unicode-Buchstaben)
assert_equals "Umlaute erhalten (ü)" "überblick" "$(heading_to_anchor 'Überblick')"
assert_equals "Umlaute erhalten (ä)" "änderungen" "$(heading_to_anchor 'Änderungen')"
assert_equals "Umlaute erhalten (ö)" "größe" "$(heading_to_anchor 'Größe')"

# ============================================================
# generate_toc() – Unit Tests
# ============================================================
echo ""
echo "=== generate_toc (Unit) ==="

# Einfacher Test mit bekannten Überschriften
_toc_input="## ✨ Erster Abschnitt

Normaler Text hier.

### Unter-Abschnitt

Mehr Text.

## 🚀 Zweiter Abschnitt

### Noch ein Unter-Abschnitt

## Dritter"

result=$(generate_toc "$_toc_input")

assert_contains "ToC: H2 mit Emoji" "- [✨ Erster Abschnitt](#-erster-abschnitt)" "$result"
assert_contains "ToC: H3 eingerückt" "  - [Unter-Abschnitt](#unter-abschnitt)" "$result"
assert_contains "ToC: Zweiter H2" "- [🚀 Zweiter Abschnitt](#-zweiter-abschnitt)" "$result"
assert_contains "ToC: Zweiter H3" "  - [Noch ein Unter-Abschnitt](#noch-ein-unter-abschnitt)" "$result"
assert_contains "ToC: H2 ohne Emoji" "- [Dritter](#dritter)" "$result"

# H4 wird ignoriert
_toc_h4_input="## Hauptabschnitt

### Unter

#### Detail-Ebene"

result=$(generate_toc "$_toc_h4_input")
[[ "$result" != *"Detail-Ebene"* ]]
assert_equals "ToC: H4 ignoriert" "0" "$?"

# Anzahl der Einträge prüfen
local toc_lines
toc_lines=$(echo "$result" | wc -l)
assert_equals "ToC: 2 Einträge (H2+H3, kein H4)" "2" "${toc_lines##* }"

# Doppelte Überschriften werden dedupliziert (GitHub-kompatibel: -1, -2, …)
_toc_dup_input="## Titel

### Untertitel

## Titel

### Untertitel"

result=$(generate_toc "$_toc_dup_input")

assert_contains "ToC: Erstes H2" "- [Titel](#titel)" "$result"
assert_contains "ToC: Zweites H2 dedupliziert" "- [Titel](#titel-1)" "$result"
assert_contains "ToC: Erstes H3" "  - [Untertitel](#untertitel)" "$result"
assert_contains "ToC: Zweites H3 dedupliziert" "  - [Untertitel](#untertitel-1)" "$result"

# ============================================================
# Credits-Sektion – Integrations-Test
# ============================================================
echo ""
echo "=== Credits-Sektion (Integration) ==="

result=$(generate_readme_md)
assert_contains "Credits: Sektion vorhanden" "## 🙏 Credits" "$result"
assert_contains "Credits: Catppuccin" "Catppuccin Mocha" "$result"
assert_contains "Credits: Paketliste-Link" "[Installierte Pakete](docs/setup.md#installierte-pakete)" "$result"
assert_contains "Shell-Erlebnis: Paketliste-Link" "[Vollständige Paketliste](docs/setup.md#installierte-pakete)" "$result"

# Link-Target-Validierung: Anker muss in docs/setup.md existieren
grep -q '^## Installierte Pakete' "$DOCS_DIR/setup.md"
assert_equals "Link-Target: Anker #installierte-pakete existiert in setup.md" "0" "$?"

# Credits steht zwischen Dokumentation und Lizenz
local credits_pos doku_pos lizenz_pos
credits_pos=$(echo "$result" | grep -n '## 🙏 Credits' | head -1 | cut -d: -f1)
doku_pos=$(echo "$result" | grep -n '## 📖 Dokumentation' | head -1 | cut -d: -f1)
lizenz_pos=$(echo "$result" | grep -n '## Lizenz' | head -1 | cut -d: -f1)
[[ "$doku_pos" -lt "$credits_pos" && "$credits_pos" -lt "$lizenz_pos" ]]
assert_equals "Credits: nach Doku, vor Lizenz" "0" "$?"

# ============================================================
# ToC-Konsistenz – Integrations-Test
# ============================================================
echo ""
echo "=== ToC-Konsistenz (Integration) ==="

result=$(generate_readme_md)

# ToC-Sektion ist vorhanden
assert_contains "ToC: Inhalt-Überschrift" "## Inhalt" "$result"

# Überschriften aus Body extrahieren (ohne ToC-Block selbst)
assert_toc_consistency "$result"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
