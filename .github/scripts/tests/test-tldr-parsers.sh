#!/usr/bin/env zsh
# ============================================================
# test-tldr-parsers.sh - Tests für tldr/parsers.sh
# ============================================================
# Zweck       : Unit Tests für format_keybindings_for_tldr()
#               und format_param_for_tldr()
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
# Zusammenfassung
# ============================================================
test_summary
