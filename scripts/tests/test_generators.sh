#!/usr/bin/env zsh
# ============================================================
# test_generators.sh - Unit-Tests für Generator-Bibliothek
# ============================================================
# Zweck   : Testet Parser-Funktionen aus scripts/generators/lib.sh
# Pfad    : scripts/tests/test_generators.sh
# Ausführung: ./scripts/tests/test_generators.sh [--verbose]
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h}"
LIB_FILE="$DOTFILES_DIR/scripts/generators/lib.sh"
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-colors"

# Farben (Catppuccin Mocha) – zentral definiert
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

# Statistik
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
VERBOSE=false

[[ "${1:-}" == "--verbose" || "${1:-}" == "-v" ]] && VERBOSE=true

# ------------------------------------------------------------
# Test-Framework
# ------------------------------------------------------------
pass() {
    (( TESTS_PASSED++ )) || true
    $VERBOSE && echo -e "  ${C_GREEN}✔${C_RESET} $1" || true
}

fail() {
    (( TESTS_FAILED++ )) || true
    echo -e "  ${C_RED}✖${C_RESET} $1"
    [[ -n "${2:-}" ]] && echo -e "    ${C_OVERLAY0}Erwartet: $2${C_RESET}" || true
    [[ -n "${3:-}" ]] && echo -e "    ${C_OVERLAY0}Erhalten: $3${C_RESET}" || true
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    (( TESTS_RUN++ )) || true

    if [[ "$expected" == "$actual" ]]; then
        pass "$message"
    else
        fail "$message" "$expected" "$actual"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    (( TESTS_RUN++ )) || true

    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$message"
    else
        fail "$message" "enthält '$needle'" "$haystack"
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-}"
    (( TESTS_RUN++ )) || true

    if [[ -n "$value" ]]; then
        pass "$message"
    else
        fail "$message" "nicht leer" "(leer)"
    fi
}

# ------------------------------------------------------------
# Source lib.sh (mit Guard gegen Output)
# ------------------------------------------------------------
source "$LIB_FILE"

# ------------------------------------------------------------
# Test: parse_header_field
# ------------------------------------------------------------
test_parse_header_field() {
    echo -e "${C_BLUE}→${C_RESET} parse_header_field"

    # Erstelle temporäre Testdatei
    local tmpfile=$(mktemp)
    cat > "$tmpfile" << 'EOF'
# ============================================================
# test.alias - Test-Datei
# ============================================================
# Zweck   : Das ist der Zweck
# Pfad    : terminal/.config/alias/test.alias
# Docs    : https://example.com
# Hinweis : Mehrzeilig
#           Zweite Zeile
#           Dritte Zeile
# ============================================================

# Guard Check
if ! command -v test >/dev/null 2>&1; then return 0; fi
EOF

    # Test: Einfaches Feld
    local zweck=$(parse_header_field "$tmpfile" "Zweck")
    assert_equals "Das ist der Zweck" "$zweck" "Einfaches Feld"

    # Test: URL-Feld
    local docs=$(parse_header_field "$tmpfile" "Docs")
    assert_equals "https://example.com" "$docs" "URL-Feld"

    # Test: Mehrzeiliges Feld
    local hinweis=$(parse_header_field "$tmpfile" "Hinweis")
    assert_contains "$hinweis" "Mehrzeilig" "Mehrzeilig: erste Zeile"
    assert_contains "$hinweis" "Zweite Zeile" "Mehrzeilig: zweite Zeile"
    assert_contains "$hinweis" "Dritte Zeile" "Mehrzeilig: dritte Zeile"

    # Test: Nicht existierendes Feld
    local missing=$(parse_header_field "$tmpfile" "NichtVorhanden")
    assert_equals "" "$missing" "Nicht existierendes Feld"

    # Test: Leere Datei
    local emptyfile=$(mktemp)
    local empty_result=$(parse_header_field "$emptyfile" "Zweck")
    assert_equals "" "$empty_result" "Leere Datei"

    rm -f "$tmpfile" "$emptyfile"
}

# ------------------------------------------------------------
# Test: parse_alias_command
# ------------------------------------------------------------
test_parse_alias_command() {
    echo -e "${C_BLUE}→${C_RESET} parse_alias_command"

    # Test: Single-quoted alias
    local cmd1=$(parse_alias_command "alias ls='eza --icons'")
    assert_equals "eza --icons" "$cmd1" "Single-quoted"

    # Test: Double-quoted alias
    local cmd2=$(parse_alias_command 'alias home="cd $HOME"')
    assert_equals 'cd $HOME' "$cmd2" "Double-quoted"

    # Test: Alias mit Kommentar
    local cmd3=$(parse_alias_command "alias cat='bat'  # besser")
    assert_equals "bat" "$cmd3" "Mit Trailing-Kommentar"

    # Test: Komplexer Befehl
    local cmd4=$(parse_alias_command "alias ll='eza -la --icons --git'")
    assert_equals "eza -la --icons --git" "$cmd4" "Komplexer Befehl"

    # Test: Pipe im Befehl
    local cmd5=$(parse_alias_command "alias ports='lsof -i -P | grep LISTEN'")
    assert_equals "lsof -i -P | grep LISTEN" "$cmd5" "Mit Pipe"

    # Test: Escaped single quotes ('\'' Pattern)
    local cmd6=$(parse_alias_command "alias esc='echo '\\''hello'\\'' world'")
    assert_equals "echo 'hello' world" "$cmd6" "Escaped single quotes"

    # Test: Escaped double quotes (\" Pattern)
    local cmd7=$(parse_alias_command 'alias say="echo \"hello world\""')
    assert_equals 'echo "hello world"' "$cmd7" "Escaped double quotes"

    # Test: Mehrfache escaped single quotes
    local cmd8=$(parse_alias_command "alias multi='it'\\''s a '\\''test'\\'''")
    assert_equals "it's a 'test'" "$cmd8" "Mehrfache escaped single quotes"

    # Edge-Cases für komplexe Quote-Patterns (Copilot Review Issue #3)
    # Test: Leerer Single-Quoted String
    local cmd9=$(parse_alias_command "alias empty=''")
    assert_equals "" "$cmd9" "Leerer Single-Quoted String"

    # Test: Nur Leerzeichen
    local cmd10=$(parse_alias_command "alias space='   '")
    assert_equals "   " "$cmd10" "Nur Leerzeichen"

    # Test: Nested double quotes in single quotes (häufig bei fzf --preview)
    local cmd11=$(parse_alias_command "alias fzf-preview='fzf --preview \"cat {}\"'")
    assert_equals 'fzf --preview "cat {}"' "$cmd11" "Double quotes innerhalb single quotes"

    # Test: Backslash ohne Quote (für Pfade)
    local cmd12=$(parse_alias_command "alias path='echo /some/path'")
    assert_equals "echo /some/path" "$cmd12" "Pfad ohne spezielle Zeichen"
}

# ------------------------------------------------------------
# Test: parse_description_comment
# ------------------------------------------------------------
test_parse_description_comment() {
    echo -e "${C_BLUE}→${C_RESET} parse_description_comment"

    # Test: Einfacher Alias
    local result1=$(parse_description_comment "# ll – Langes Listing")
    assert_contains "$result1" "ll" "Einfacher Name"

    # Test: Mit Parameter
    local result2=$(parse_description_comment "# brewi(formula) – Brew install")
    assert_contains "$result2" "brewi" "Name mit Parameter"
    assert_contains "$result2" "formula" "Parameter extrahiert"

    # Test: Mit Keybindings
    local result3=$(parse_description_comment "# glog – Enter=diff, Ctrl-Y=SHA")
    assert_contains "$result3" "glog" "Name mit Keybindings"
    assert_contains "$result3" "Enter=diff" "Keybinding extrahiert"
}

# ------------------------------------------------------------
# Test: parse_brewfile_entry
# ------------------------------------------------------------
test_parse_brewfile_entry() {
    echo -e "${C_BLUE}→${C_RESET} parse_brewfile_entry"

    # Test: brew Formel
    local result1=$(parse_brewfile_entry 'brew "fzf"                                # Fuzzy Finder')
    assert_contains "$result1" "fzf" "brew Name"
    assert_contains "$result1" "Fuzzy Finder" "brew Beschreibung"
    assert_contains "$result1" "brew" "brew Typ"

    # Test: cask
    local result2=$(parse_brewfile_entry 'cask "visual-studio-code"                 # Code Editor')
    assert_contains "$result2" "visual-studio-code" "cask Name"
    assert_contains "$result2" "cask" "cask Typ"

    # Test: mas (ohne Beschreibung)
    local result3=$(parse_brewfile_entry 'mas "Xcode", id: 497799835')
    assert_contains "$result3" "Xcode" "mas Name"
    assert_contains "$result3" "mas" "mas Typ"

    # Test: Ohne Kommentar
    local result4=$(parse_brewfile_entry 'brew "ripgrep"')
    assert_contains "$result4" "ripgrep" "Ohne Beschreibung: Name"
}

# ------------------------------------------------------------
# Test: compare_content
# ------------------------------------------------------------
test_compare_content() {
    echo -e "${C_BLUE}→${C_RESET} compare_content"

    local tmpfile=$(mktemp)
    echo "Test-Inhalt" > "$tmpfile"

    # Test: Gleicher Inhalt
    (( TESTS_RUN++ )) || true
    if compare_content "$tmpfile" "Test-Inhalt"; then
        pass "Gleicher Inhalt erkannt"
    else
        fail "Gleicher Inhalt erkannt"
    fi

    # Test: Unterschiedlicher Inhalt
    (( TESTS_RUN++ )) || true
    if ! compare_content "$tmpfile" "Anderer Inhalt"; then
        pass "Unterschiedlicher Inhalt erkannt"
    else
        fail "Unterschiedlicher Inhalt erkannt"
    fi

    # Test: Nicht existierende Datei
    (( TESTS_RUN++ )) || true
    if ! compare_content "/nicht/vorhanden" "Test"; then
        pass "Nicht existierende Datei erkannt"
    else
        fail "Nicht existierende Datei erkannt"
    fi

    rm -f "$tmpfile"
}

# ------------------------------------------------------------
# Test: extract_usage_codeblock
# ------------------------------------------------------------
test_extract_usage_codeblock() {
    echo -e "${C_BLUE}→${C_RESET} extract_usage_codeblock"

    # Erstelle temporäre Alias-Datei
    local tmpfile=$(mktemp)
    cat > "$tmpfile" << 'EOF'
# ============================================================
# test.alias
# ============================================================
# Zweck : Test

# Guard
if ! command -v test >/dev/null 2>&1; then return 0; fi

# ----
# Basis-Befehle
# ----

# Langes Listing
alias ll='eza -la'

# Mit Icons
alias lli='eza -la --icons'

# ----
# Erweitert
# ----

# Baum-Ansicht
alias lt='eza --tree'
EOF

    local output=$(extract_usage_codeblock "$tmpfile")

    # Prüfe Sektionen
    assert_contains "$output" "Basis-Befehle" "Sektion erkannt"
    assert_contains "$output" "Erweitert" "Zweite Sektion erkannt"

    # Prüfe Aliase
    assert_contains "$output" "ll" "Alias ll"
    assert_contains "$output" "lli" "Alias lli"
    assert_contains "$output" "lt" "Alias lt"

    # Prüfe Beschreibungen
    assert_contains "$output" "Langes Listing" "Beschreibung 1"
    assert_contains "$output" "Baum-Ansicht" "Beschreibung 2"

    rm -f "$tmpfile"
}

# ------------------------------------------------------------
# Test: Echte Alias-Dateien
# ------------------------------------------------------------
test_real_alias_files() {
    echo -e "${C_BLUE}→${C_RESET} Echte Alias-Dateien"

    local alias_dir="$DOTFILES_DIR/terminal/.config/alias"

    # Mindestens eine Alias-Datei muss existieren
    local file_count=$(find "$alias_dir" -name "*.alias" 2>/dev/null | wc -l)
    (( TESTS_RUN++ )) || true
    if (( file_count > 0 )); then
        pass "$file_count Alias-Dateien gefunden"
    else
        fail "Alias-Dateien existieren" ">0" "$file_count"
        return
    fi

    # Jede Alias-Datei muss parsebar sein
    for file in "$alias_dir"/*.alias; do
        [[ -f "$file" ]] || continue
        local name=$(basename "$file")

        # Zweck muss existieren
        local zweck=$(parse_header_field "$file" "Zweck")
        (( TESTS_RUN++ )) || true
        if [[ -n "$zweck" ]]; then
            pass "$name: Zweck vorhanden"
        else
            fail "$name: Zweck vorhanden" "nicht leer" "(leer)"
        fi
    done
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
main() {
    echo ""
    echo -e "${C_BLUE}Generator-Tests${C_RESET}"
    echo ""

    test_parse_header_field
    test_parse_alias_command
    test_parse_description_comment
    test_parse_brewfile_entry
    test_compare_content
    test_extract_usage_codeblock
    test_real_alias_files

    echo ""
    echo -e "${C_OVERLAY0}────────────────────────────────────────${C_RESET}"

    if (( TESTS_FAILED == 0 )); then
        echo -e "${C_GREEN}✔ Alle $TESTS_RUN Tests bestanden${C_RESET}"
        exit 0
    else
        echo -e "${C_RED}✖ $TESTS_FAILED von $TESTS_RUN Tests fehlgeschlagen${C_RESET}"
        exit 1
    fi
}

main "$@"
