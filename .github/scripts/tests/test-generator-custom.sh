#!/usr/bin/env zsh
# ============================================================
# test-generator-custom.sh - Tests für generators/customization.sh
# ============================================================
# Zweck       : Unit Tests für collect_theme_configs(),
#               generate_color_palette_table(), extract_fzf_colors(),
#               extract_fzf_keybindings()
# Pfad        : .github/scripts/tests/test-generator-custom.sh
# Aufruf      : ./.github/scripts/tests/test-generator-custom.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# customization.sh → common.sh → config.sh + parsers.sh (alles in einem Source-Durchlauf)
# Guard: Nur Funktionen laden, nicht den Generator ausführen
_SOURCED_BY_GENERATOR=1
source "$SCRIPT_DIR/../generators/customization.sh"

# Pfade aus common.sh sind jetzt gesetzt (DOTFILES_DIR, ALIAS_DIR etc.)

# ============================================================
# collect_theme_configs() – mit echtem theme-style
# ============================================================
echo "=== collect_theme_configs (Integration) ==="

result=$(collect_theme_configs)

# Tabellen-Header prüfen
assert_contains "Tabellen-Header Tool" "| Tool" "$result"
assert_contains "Tabellen-Header Theme-Datei" "| Theme-Datei" "$result"
assert_contains "Tabellen-Header Status" "| Status" "$result"
assert_contains "Header-Separator" "| ----" "$result"

# Bekannte Tools in der Tabelle (aus echtem theme-style)
assert_contains "bat in Theme-Tabelle" "bat" "$result"
assert_contains "fzf in Theme-Tabelle" "fzf" "$result"
assert_contains "kitty in Theme-Tabelle" "kitty" "$result"

# Deployment-Status vorhanden
assert_contains "Stow-Deployment" "Via Stow" "$result"

# theme-style selbst sollte NICHT als Tool in der Tabelle sein
# (jq nutzt theme-style als Config-Pfad, das ist OK)
local theme_tool_lines
theme_tool_lines=$(echo "$result" | grep -cF '**theme-style**' || true)
assert_equals "theme-style nicht als Tool" "0" "$theme_tool_lines"

# ============================================================
# collect_theme_configs() – mit Fixture
# ============================================================
echo ""
echo "=== collect_theme_configs (Fixture) ==="

# Eigenes DOTFILES_DIR mit kontrolliertem theme-style
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles"
mkdir -p "$DOTFILES_DIR/terminal/.config"
mkdir -p "$DOTFILES_DIR/setup"

cat > "$DOTFILES_DIR/terminal/.config/theme-style" << 'FIXTURE'
# Theme-Quellen:
# Format: tool | config-pfad | upstream-repo | status
#   testtool     | ~/.config/testtool/theme.toml     | github.com/catppuccin/testtool    | upstream
#   theme-style  | ~/.config/theme-style              | manual                             | manual
FIXTURE

result=$(collect_theme_configs)

assert_contains "Fixture: testtool erkannt" "testtool" "$result"
assert_contains "Fixture: Pfad korrekt" "terminal/.config/testtool/theme.toml" "$result"
assert_contains "Fixture: Stow-Deployment" "Via Stow verlinkt" "$result"

# theme-style sollte sich selbst überspringen
theme_style_lines=$(echo "$result" | grep -c "theme-style" || true)
assert_equals "Fixture: theme-style übersprungen" "0" "$theme_style_lines"

# DOTFILES_DIR zurücksetzen
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

# ============================================================
# generate_color_palette_table() – Integration
# ============================================================
echo ""
echo "=== generate_color_palette_table (Integration) ==="

result=$(generate_color_palette_table)

# Tabellen-Header
assert_contains "Tabellen-Header Farbe" "| Farbe" "$result"
assert_contains "Tabellen-Header Hex" "| Hex" "$result"
assert_contains "Tabellen-Header Variable" "| Variable" "$result"

# Mindestens Catppuccin Mocha Base-Farben vorhanden
assert_contains "Rosewater vorhanden" "Rosewater" "$result"
assert_contains "Mauve vorhanden" "Mauve" "$result"
assert_contains "Blue vorhanden" "Blue" "$result"

# Hex-Format prüfen (#XXXXXX)
assert_contains "Hex-Format" '`#' "$result"

# Variable-Format prüfen (C_NAME)
assert_contains "Variable-Format" '`C_' "$result"

# ============================================================
# generate_color_palette_table() – Fixture
# ============================================================
echo ""
echo "=== generate_color_palette_table (Fixture) ==="

_ORIG_DOTFILES_DIR2="$DOTFILES_DIR"
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles-color"
mkdir -p "$DOTFILES_DIR/terminal/.config"

cat > "$DOTFILES_DIR/terminal/.config/theme-style" << 'FIXTURE'
#!/usr/bin/env zsh
# Catppuccin Mocha Test
typeset -gx C_RED=$'\033[38;2;243;139;168m'
typeset -gx C_GREEN=$'\033[38;2;166;227;161m'
typeset -gx C_BLUE=$'\033[38;2;137;180;250m'
FIXTURE

result=$(generate_color_palette_table)
assert_contains "Fixture: Red erkannt" "Red" "$result"
assert_contains "Fixture: Green erkannt" "Green" "$result"
assert_contains "Fixture: Blue erkannt" "Blue" "$result"
assert_contains "Fixture: Hex für Red" "#F38BA8" "$result"
assert_contains "Fixture: Hex für Green" "#A6E3A1" "$result"
assert_contains "Fixture: Variable C_RED" "C_RED" "$result"

DOTFILES_DIR="$_ORIG_DOTFILES_DIR2"

# ============================================================
# extract_fzf_colors() – Integration
# ============================================================
echo ""
echo "=== extract_fzf_colors (Integration) ==="

result=$(extract_fzf_colors)
assert_contains "Code-Block Start" '```zsh' "$result"
assert_contains "Catppuccin Kommentar" "Catppuccin" "$result"
assert_contains "--color= vorhanden" "--color=" "$result"
assert_contains "Layout-Auszug" "Layout" "$result"

# ============================================================
# extract_fzf_keybindings() – Integration
# ============================================================
echo ""
echo "=== extract_fzf_keybindings (Integration) ==="

result=$(extract_fzf_keybindings)
assert_contains "Code-Block Start" '```zsh' "$result"
assert_contains "Ctrl+X Prefix" "Ctrl+X" "$result"
assert_contains "bindkey vorhanden" "bindkey" "$result"

# ============================================================
# ToC-Konsistenz (Integration) – customization.md
# ============================================================
echo ""
echo "=== ToC-Konsistenz (Integration) ==="

result=$(generate_customization_md)

# ToC-Überschrift vorhanden
assert_contains "ToC: Inhalt-Überschrift" "## Inhalt" "$result"

assert_toc_consistency "$result"

# Bekannte Überschriften im ToC
assert_contains "ToC: Catppuccin Mocha Theme" "[Catppuccin Mocha Theme]" "$result"
assert_contains "ToC: Starship-Prompt" "[Starship-Prompt]" "$result"
assert_contains "ToC: ZSH-Ladereihenfolge" "[ZSH-Ladereihenfolge]" "$result"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
