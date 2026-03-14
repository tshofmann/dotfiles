#!/usr/bin/env zsh
# ============================================================
# test-generator-custom.sh - Tests für generators/customization.sh
# ============================================================
# Zweck       : Unit Tests für collect_theme_configs()
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
# Zusammenfassung
# ============================================================
test_summary
