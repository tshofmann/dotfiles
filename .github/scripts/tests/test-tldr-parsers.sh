#!/usr/bin/env zsh
# ============================================================
# test-tldr-parsers.sh - Tests für tldr/parsers.sh
# ============================================================
# Zweck       : Unit Tests für format_keybindings_for_tldr(),
#               format_param_for_tldr(), parse_yazi_keymap(),
#               find_main_config_file(), parse_config_file_header(),
#               parse_fzf_config_keybindings(), parse_shell_keybindings(),
#               parse_cross_references(), find_config_only_tools()
# Pfad        : .github/scripts/tests/test-tldr-parsers.sh
# Aufruf      : ./.github/scripts/tests/test-tldr-parsers.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# tldr/parsers.sh benötigt common.sh, wir brauchen aber nur die
# pure functions → Stub der Pfad-Variablen, dann direkt sourcen
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"
ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"
TEALDEER_DIR="$DOTFILES_DIR/terminal/.config/tealdeer/pages"

source "$SCRIPT_DIR/../generators/tldr/parsers.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# ============================================================
# format_keybindings_for_tldr()
# ============================================================
echo "=== format_keybindings_for_tldr ==="

# Standard-Keybindings
result=$(format_keybindings_for_tldr "Enter=Öffnen, Ctrl+Y=Kopieren")
assert_contains "Enter formatiert" '`<Enter>` Öffnen' "$result"
assert_contains "Ctrl+Y formatiert" '`<Ctrl y>` Kopieren' "$result"
assert_contains "In Klammern" "(" "$result"

# Einzelnes Keybinding
result=$(format_keybindings_for_tldr "Tab=Auswählen")
assert_equals "Tab einzeln" '(`<Tab>` Auswählen)' "$result"

# Esc-Taste
result=$(format_keybindings_for_tldr "Esc=Abbrechen")
assert_equals "Esc-Taste" '(`<Esc>` Abbrechen)' "$result"

# Shift+Kombination (Tab bleibt groß – nur Einzelbuchstaben werden lowercase)
result=$(format_keybindings_for_tldr "Shift+Tab=Zurück")
assert_contains "Shift+Tab formatiert" '`<Shift Tab>` Zurück' "$result"

# Alt+Kombination
result=$(format_keybindings_for_tldr "Alt+A=Alle")
assert_contains "Alt formatiert" '`<Alt a>` Alle' "$result"

# Leerer Input
result=$(format_keybindings_for_tldr "")
assert_empty "Leerer Input" "$result"

# Kein Keybinding-Pattern (nur Text)
result=$(format_keybindings_for_tldr "Zeigt alle Einträge")
assert_empty "Kein Keybinding" "$result"

# Mehrere Keybindings
result=$(format_keybindings_for_tldr "Enter=Öffnen, Ctrl+D=Diff, Tab=Toggle")
assert_contains "Drei Keybindings: Enter" '`<Enter>` Öffnen' "$result"
assert_contains "Drei Keybindings: Ctrl+D" '`<Ctrl d>` Diff' "$result"
assert_contains "Drei Keybindings: Tab" '`<Tab>` Toggle' "$result"

# ============================================================
# format_param_for_tldr()
# ============================================================
echo ""
echo "=== format_param_for_tldr ==="

# Einfacher Parameter
result=$(format_param_for_tldr "query")
assert_equals "Einfacher Param" "{{query}}" "$result"

# Optionaler Parameter
result=$(format_param_for_tldr "query?")
assert_equals "Optional-Marker entfernt" "{{query}}" "$result"

# Parameter mit Default
result=$(format_param_for_tldr "count=10")
assert_equals "Default entfernt" "{{count}}" "$result"

# Mehrere Parameter
result=$(format_param_for_tldr "query, dir?, depth=3")
assert_equals "Mehrere Params" "{{query, dir, depth}}" "$result"

# Leerer Input
result=$(format_param_for_tldr "")
assert_empty "Leerer Input" "$result"

# ============================================================
# parse_yazi_keymap()
# ============================================================
echo ""
echo "=== parse_yazi_keymap ==="

# Keymap mit Bookmarks und Quick Look
cat > "$_TEST_TMPDIR/keymap.toml" << 'FIXTURE'
# ------------------------------------------------------------
# Bookmarks (g → Ziel)
# ------------------------------------------------------------
[[mgr.prepend_keymap]]
on = ["g", "d"]
run = "cd ~/Downloads"
desc = "Downloads"

[[mgr.prepend_keymap]]
on = ["g", "D"]
run = "cd ~/Desktop"
desc = "Desktop"

# ------------------------------------------------------------
# Quick Look (macOS native Preview)
# ------------------------------------------------------------
[[mgr.prepend_keymap]]
on = ["<C-p>"]
run = "shell -- qlmanage -p %s &>/dev/null"
desc = "Quick Look"
FIXTURE

result=$(parse_yazi_keymap "$_TEST_TMPDIR/keymap.toml")

assert_contains "Bookmark g d" "g d" "$result"
assert_contains "Bookmark Downloads" "Downloads" "$result"
assert_contains "Bookmark g D" "g D" "$result"
assert_contains "Bookmark Desktop" "Desktop" "$result"
assert_contains "Ctrl+p konvertiert" "Ctrl+p" "$result"
assert_contains "Quick Look" "Quick Look" "$result"
assert_contains "Sektionsheader Bookmarks" "Bookmarks" "$result"

# Leere/nichtexistente Datei
result=$(parse_yazi_keymap "$_TEST_TMPDIR/nonexistent.toml")
assert_empty "Nichtexistente Datei" "$result"

# ============================================================
# find_main_config_file()
# ============================================================
echo ""
echo "=== find_main_config_file ==="

# Verzeichnis mit tool.conf
mkdir -p "$_TEST_TMPDIR/kitty"
cat > "$_TEST_TMPDIR/kitty/kitty.conf" << 'FIXTURE'
# ============================================================
# kitty.conf - Kitty Terminal
# ============================================================
# Pfad        : ~/.config/kitty/kitty.conf
# Zweck       : Kitty Konfiguration
# ============================================================
font_size 12
FIXTURE

result=$(find_main_config_file "$_TEST_TMPDIR/kitty")
assert_equals "kitty.conf gefunden" "$_TEST_TMPDIR/kitty/kitty.conf" "$result"

# Verzeichnis mit config (generisch)
mkdir -p "$_TEST_TMPDIR/generic-dir"
cat > "$_TEST_TMPDIR/generic-dir/config" << 'FIXTURE'
# Pfad        : ~/.config/generic/config
# Zweck       : Test
FIXTURE

result=$(find_main_config_file "$_TEST_TMPDIR/generic-dir")
assert_equals "config (generisch) gefunden" "$_TEST_TMPDIR/generic-dir/config" "$result"

# Verzeichnis mit config.toml
mkdir -p "$_TEST_TMPDIR/toml-dir"
cat > "$_TEST_TMPDIR/toml-dir/config.toml" << 'FIXTURE'
# Pfad        : ~/.config/toml/config.toml
# Zweck       : TOML Config
FIXTURE

result=$(find_main_config_file "$_TEST_TMPDIR/toml-dir")
assert_equals "config.toml gefunden" "$_TEST_TMPDIR/toml-dir/config.toml" "$result"

# Verzeichnis ohne Config-Datei
mkdir -p "$_TEST_TMPDIR/empty-dir"
result=$(find_main_config_file "$_TEST_TMPDIR/empty-dir")
assert_empty "Leeres Verzeichnis" "$result"

# Config ohne gültigen Header
mkdir -p "$_TEST_TMPDIR/noheader-dir"
echo "option = value" > "$_TEST_TMPDIR/noheader-dir/config"
result=$(find_main_config_file "$_TEST_TMPDIR/noheader-dir")
assert_empty "Config ohne Header" "$result"

# ============================================================
# parse_config_file_header()
# ============================================================
echo ""
echo "=== parse_config_file_header ==="

cat > "$_TEST_TMPDIR/headerfile.conf" << 'FIXTURE'
# ============================================================
# headerfile.conf - Test Config
# ============================================================
# Pfad        : ~/.config/headerfile/headerfile.conf
# Zweck       : Eine Testkonfiguration
# Theme       : Catppuccin Mocha
# Reload      : ctrl+shift+f5
# ============================================================

# Guard
option = value
FIXTURE

result=$(parse_config_file_header "$_TEST_TMPDIR/headerfile.conf")
assert_contains "Pfad extrahiert" "Pfad|~/.config/headerfile/headerfile.conf" "$result"
assert_contains "Zweck extrahiert" "Zweck|Eine Testkonfiguration" "$result"
assert_contains "Theme extrahiert" "Theme|Catppuccin Mocha" "$result"
assert_contains "Reload extrahiert" "Reload|ctrl+shift+f5" "$result"

# Feldanzahl prüfen
local field_count
field_count=$(echo "$result" | grep -c "|" || true)
assert_equals "4 Header-Felder" "4" "$field_count"

# Nichtexistente Datei
result=$(parse_config_file_header "$_TEST_TMPDIR/nonexistent.conf" 2>&1)
assert_empty "Nichtexistente Config-Datei" "$result"

# ============================================================
# parse_fzf_config_keybindings()
# ============================================================
echo ""
echo "=== parse_fzf_config_keybindings ==="

cat > "$_TEST_TMPDIR/fzf-config" << 'FIXTURE'
# Layout
--height=80%
--layout=reverse

# Ctrl+Y : In die Zwischenablage kopieren
--bind=ctrl-y:execute-silent(echo -n {+} | pbcopy)

# Ctrl+E : In Editor öffnen
--bind=ctrl-e:execute($EDITOR {})

# Normaler Kommentar (kein Keybinding)
--color=bg+:#313244
FIXTURE

result=$(parse_fzf_config_keybindings "$_TEST_TMPDIR/fzf-config")
assert_contains "Ctrl+Y erkannt" "In die Zwischenablage kopieren" "$result"
assert_contains "Ctrl+Y Taste" '<Ctrl y>' "$result"
assert_contains "Ctrl+E erkannt" "In Editor öffnen" "$result"
assert_contains "Ctrl+E Taste" '<Ctrl e>' "$result"

# Kein falscher Treffer für normalen Kommentar
local color_count
color_count=$(echo "$result" | grep -c "bg+" || true)
assert_equals "Kein falscher Treffer für Farb-Kommentar" "0" "$color_count"

# Tab-Keybinding
cat > "$_TEST_TMPDIR/fzf-config-tab" << 'FIXTURE'
# Tab : Eintrag auswählen
--bind=tab:toggle
FIXTURE

result=$(parse_fzf_config_keybindings "$_TEST_TMPDIR/fzf-config-tab")
assert_contains "Tab erkannt" "Eintrag auswählen" "$result"

# Dokumentierter Default ohne --bind
cat > "$_TEST_TMPDIR/fzf-config-default" << 'FIXTURE'
# Ctrl+R : Shell-History durchsuchen
# (kein --bind nötig, fzf-Default)
FIXTURE

result=$(parse_fzf_config_keybindings "$_TEST_TMPDIR/fzf-config-default")
assert_contains "Default ohne --bind" "Shell-History durchsuchen" "$result"

# ============================================================
# parse_shell_keybindings()
# ============================================================
echo ""
echo "=== parse_shell_keybindings ==="

cat > "$_TEST_TMPDIR/fzf.alias" << 'FIXTURE'
# ============================================================
# Some header
# ============================================================

# ------------------------------------------------------------
# Shell-Keybindings (Ctrl+X Prefix)
# ------------------------------------------------------------
# Ctrl+X 1: Dateien in Editor öffnen
# Ctrl+X 2: In Verzeichnis wechseln

# ZOXIDE Einstellungen
export _ZO_DATA_DIR="~/.local/share/zoxide"
FIXTURE

result=$(parse_shell_keybindings "$_TEST_TMPDIR/fzf.alias")
assert_contains "Shell-Keybinding 1" "Dateien in Editor öffnen" "$result"
assert_contains "Shell-Keybinding Taste 1" '<Ctrl x> 1' "$result"
assert_contains "Shell-Keybinding 2" "In Verzeichnis wechseln" "$result"
assert_contains "Shell-Keybinding Taste 2" '<Ctrl x> 2' "$result"

# Stoppt bei ZOXIDE
local zoxide_count
zoxide_count=$(echo "$result" | grep -c "ZOXIDE" || true)
assert_equals "Stoppt vor ZOXIDE" "0" "$zoxide_count"

# ============================================================
# parse_cross_references()
# ============================================================
echo ""
echo "=== parse_cross_references ==="

cat > "$_TEST_TMPDIR/crossref.alias" << 'FIXTURE'
# ============================================================
# crossref.alias - Test
# ============================================================
# Zweck       : Test Cross-References
# Nutzt       : fzf (Preview)
#               - git.alias → git-log(), git-branch()
#               - brew.alias → brew-add
# ============================================================

# Guard
if ! command -v crossref >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(parse_cross_references "$_TEST_TMPDIR/crossref.alias")
assert_contains "git Cross-Ref" "git|" "$result"
assert_contains "brew Cross-Ref" "brew|" "$result"
assert_contains "git-log Funktion" "git-log" "$result"

# ============================================================
# find_config_only_tools()
# ============================================================
echo ""
echo "=== find_config_only_tools ==="

# Eigene Fixture-Umgebung
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"
_ORIG_ALIAS_DIR="$ALIAS_DIR"
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles-fc"
ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"
mkdir -p "$ALIAS_DIR"
mkdir -p "$DOTFILES_DIR/terminal/.config"

# Tool mit .alias → sollte NICHT als config-only erscheinen
mkdir -p "$DOTFILES_DIR/terminal/.config/bat"
cat > "$DOTFILES_DIR/terminal/.config/bat/config" << 'FIXTURE'
# Pfad : ~/.config/bat/config
# Zweck : bat Config
FIXTURE
cat > "$ALIAS_DIR/bat.alias" << 'FIXTURE'
# bat.alias
FIXTURE

# Tool ohne .alias → sollte als config-only erscheinen
mkdir -p "$DOTFILES_DIR/terminal/.config/kitty"
cat > "$DOTFILES_DIR/terminal/.config/kitty/kitty.conf" << 'FIXTURE'
# Pfad : ~/.config/kitty/kitty.conf
# Zweck : Kitty Config
FIXTURE

# Tool ohne Header → sollte NICHT erscheinen
mkdir -p "$DOTFILES_DIR/terminal/.config/noheader"
echo "option = true" > "$DOTFILES_DIR/terminal/.config/noheader/config"

# Spezial-Verzeichnisse → übersprungen
mkdir -p "$DOTFILES_DIR/terminal/.config/alias"
mkdir -p "$DOTFILES_DIR/terminal/.config/tealdeer"
mkdir -p "$DOTFILES_DIR/terminal/.config/zsh"

result=$(find_config_only_tools)
assert_contains "kitty als config-only" "kitty" "$result"

local bat_count
bat_count=$(echo "$result" | grep -c "^bat$" || true)
assert_equals "bat hat .alias → nicht config-only" "0" "$bat_count"

local noheader_count
noheader_count=$(echo "$result" | grep -c "noheader" || true)
assert_equals "noheader ohne Header → nicht config-only" "0" "$noheader_count"

DOTFILES_DIR="$_ORIG_DOTFILES_DIR"
ALIAS_DIR="$_ORIG_ALIAS_DIR"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
