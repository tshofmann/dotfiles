#!/usr/bin/env zsh
# ============================================================
# test-common-parsers.sh - Tests für common/parsers.sh
# ============================================================
# Zweck       : Unit Tests für parse_description_comment()
#               und parse_alias_command()
# Pfad        : .github/scripts/tests/test-common-parsers.sh
# Aufruf      : ./.github/scripts/tests/test-common-parsers.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"
source "$SCRIPT_DIR/../generators/common/parsers.sh"

# ============================================================
# parse_description_comment()
# ============================================================
echo "=== parse_description_comment ==="

# Format: name|param|keybindings|description

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
# Zusammenfassung
# ============================================================
test_summary
