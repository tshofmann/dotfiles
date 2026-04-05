#!/usr/bin/env zsh
# ============================================================
# test-common-brewfile.sh - Tests für common/brewfile.sh
# ============================================================
# Zweck       : Unit Tests für parse_brewfile_entry(),
#               extract_installed_nerd_font(), font_display_name(),
#               generate_brewfile_section()
# Pfad        : .github/scripts/tests/test-common-brewfile.sh
# Aufruf      : ./.github/scripts/tests/test-common-brewfile.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# brewfile.sh braucht config.sh (für BREWFILE Pfad-Variable)
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"
BREWFILE="$DOTFILES_DIR/setup/Brewfile"

source "$SCRIPT_DIR/../generators/common/brewfile.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# ============================================================
# parse_brewfile_entry()
# ============================================================
echo "=== parse_brewfile_entry ==="

# brew mit Beschreibung und URL
result=$(parse_brewfile_entry 'brew "bat"                     # cat-Alternative mit Syntax-Highlighting | https://github.com/sharkdp/bat')
assert_contains "brew Name" "bat|" "$result"
assert_contains "brew Beschreibung" "cat-Alternative" "$result"
assert_contains "brew Typ" "|brew|" "$result"
assert_contains "brew URL" "https://github.com/sharkdp/bat" "$result"

# cask
result=$(parse_brewfile_entry 'cask "kitty"                   # GPU-basiertes Terminal | https://sw.kovidgoyal.net/kitty/')
assert_contains "cask Name" "kitty|" "$result"
assert_contains "cask Typ" "|cask|" "$result"

# mas mit ID (URL automatisch generiert)
result=$(parse_brewfile_entry 'mas "Amphetamine", id: 937984704  # Display wach halten')
assert_contains "mas Name" "Amphetamine|" "$result"
assert_contains "mas Typ" "|mas|" "$result"
assert_contains "mas URL aus ID" "https://apps.apple.com/app/id937984704" "$result"
assert_contains "mas Beschreibung" "Display wach halten" "$result"

# brew ohne Kommentar
result=$(parse_brewfile_entry 'brew "curl"')
assert_contains "Ohne Kommentar: Name" "curl|" "$result"
assert_contains "Ohne Kommentar: Typ" "|brew|" "$result"

# Ungültige Zeile
result=$(parse_brewfile_entry '# Kommentar-Zeile')
assert_empty "Kommentar-Zeile ignoriert" "$result"

# tap-Zeile (nicht unterstützt)
result=$(parse_brewfile_entry 'tap "homebrew/cask"')
assert_empty "tap ignoriert" "$result"

# ============================================================
# extract_installed_nerd_font()
# ============================================================
echo ""
echo "=== extract_installed_nerd_font ==="

# Fixture Brewfile
_ORIG_BREWFILE="$BREWFILE"
BREWFILE="$_TEST_TMPDIR/Brewfile"
cat > "$BREWFILE" << 'FIXTURE'
# ============================================================
# Brewfile
# ============================================================
# Zweck       : Test
# ============================================================

# CLI Tools
brew "bat"

# Fonts
cask "font-meslo-lg-nerd-font"     # Terminal-Font
cask "font-symbols-only-nerd-font" # Kein Nerd Font
FIXTURE

result=$(extract_installed_nerd_font)
assert_equals "Erster Nerd Font" "font-meslo-lg-nerd-font" "$result"

# Brewfile ohne Nerd Font
cat > "$BREWFILE" << 'FIXTURE'
brew "bat"
cask "kitty"
FIXTURE

result=$(extract_installed_nerd_font)
assert_empty "Kein Nerd Font → leer" "$result"

# Integration: Echtes Brewfile
BREWFILE="$_ORIG_BREWFILE"
result=$(extract_installed_nerd_font)
assert_contains "Echte Brewfile: Nerd Font" "nerd-font" "$result"

# ============================================================
# font_display_name()
# ============================================================
echo ""
echo "=== font_display_name ==="

assert_equals "MesloLG" "MesloLG Nerd Font Mono" "$(font_display_name "font-meslo-lg-nerd-font")"
assert_equals "JetBrainsMono" "JetBrainsMono Nerd Font Mono" "$(font_display_name "font-jetbrains-mono-nerd-font")"
assert_equals "FiraCode" "FiraCode Nerd Font Mono" "$(font_display_name "font-fira-code-nerd-font")"

# Fallback für unbekannte Fonts
result=$(font_display_name "font-cascadia-code-nerd-font")
assert_contains "Unbekannter Font: Nerd Font Mono" "Nerd Font Mono" "$result"

# Leerer Input
assert_equals "Leerer Input" "Nerd Font" "$(font_display_name "")"

# ============================================================
# generate_brewfile_section()
# ============================================================
echo ""
echo "=== generate_brewfile_section ==="

BREWFILE="$_TEST_TMPDIR/Brewfile-section"
cat > "$BREWFILE" << 'FIXTURE'
# ============================================================
# Brewfile - Test
# ============================================================
# Zweck       : Test
# Docs        : https://example.com
# ============================================================
# Format:
#   brew: # Beschreibung | URL
# ============================================================

# CLI Tools
brew "bat"                     # cat-Ersatz | https://github.com/sharkdp/bat
brew "fd"                      # find-Ersatz | https://github.com/sharkdp/fd

# Anwendungen
cask "kitty"                   # Terminal | https://sw.kovidgoyal.net/kitty/
FIXTURE

result=$(generate_brewfile_section)
# Kategorien als H3
assert_contains "Kategorie CLI Tools" "### CLI Tools" "$result"
assert_contains "Kategorie Anwendungen" "### Anwendungen" "$result"

# Tabellen-Header
assert_contains "Tabellen-Header" "| Paket | Beschreibung |" "$result"

# Pakete mit Links
assert_contains "bat mit Link" "[\`bat\`](https://github.com/sharkdp/bat)" "$result"
assert_contains "fd mit Link" "[\`fd\`](https://github.com/sharkdp/fd)" "$result"
assert_contains "kitty mit Link" "[\`kitty\`](https://sw.kovidgoyal.net/kitty/)" "$result"

# App Store Hinweis
assert_contains "App Store Hinweis" "App Store" "$result"

# XDG-Sektion
assert_contains "XDG-Sektion" "XDG Base Directory" "$result"

BREWFILE="$_ORIG_BREWFILE"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
