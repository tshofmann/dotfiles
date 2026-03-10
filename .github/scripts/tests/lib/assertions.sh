#!/usr/bin/env zsh
# ============================================================
# assertions.sh - Test-Assertion-Bibliothek
# ============================================================
# Zweck       : Einfache Test-Assertions für ZSH Unit Tests
# Pfad        : .github/scripts/tests/lib/assertions.sh
# Nutzt       : theme-style (Farben, optional)
# Verwendung  :
#   source "${0:A:h}/lib/assertions.sh"
#   assert_equals "Beschreibung" "erwartet" "tatsächlich"
#   assert_contains "Beschreibung" "nadel" "heuhaufen"
#   assert_empty "Beschreibung" "$variable"
#   test_summary  # → return $_TEST_FAILED
# ============================================================

# Farben laden (optional – funktioniert auch ohne)
# HINWEIS: SCRIPT_DIR des aufrufenden Skripts bewusst nicht überschreiben
_ASSERTIONS_DIR="${0:A:h}"
_TEST_SHELL_COLORS="${_ASSERTIONS_DIR:h:h:h:h}/terminal/.config/theme-style"
[[ -f "$_TEST_SHELL_COLORS" ]] && source "$_TEST_SHELL_COLORS"
unset _ASSERTIONS_DIR _TEST_SHELL_COLORS

# Zähler
_TEST_PASSED=0
_TEST_FAILED=0

# ------------------------------------------------------------
# assert_equals(beschreibung, erwartet, tatsächlich)
# ------------------------------------------------------------
assert_equals() {
    local description="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  ${C_GREEN:-}✔${C_RESET:-} $description"
        (( _TEST_PASSED++ )) || true
    else
        echo "  ${C_RED:-}✖${C_RESET:-} $description"
        echo "    Erwartet: $(printf '%q' "$expected")"
        echo "    Erhalten: $(printf '%q' "$actual")"
        (( _TEST_FAILED++ )) || true
    fi
}

# ------------------------------------------------------------
# assert_contains(beschreibung, nadel, heuhaufen)
# ------------------------------------------------------------
assert_contains() {
    local description="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  ${C_GREEN:-}✔${C_RESET:-} $description"
        (( _TEST_PASSED++ )) || true
    else
        echo "  ${C_RED:-}✖${C_RESET:-} $description"
        echo "    '$needle' nicht in Ausgabe gefunden"
        echo "    Ausgabe: $(printf '%q' "$haystack")"
        (( _TEST_FAILED++ )) || true
    fi
}

# ------------------------------------------------------------
# assert_empty(beschreibung, wert)
# ------------------------------------------------------------
assert_empty() {
    local description="$1" value="$2"
    if [[ -z "$value" ]]; then
        echo "  ${C_GREEN:-}✔${C_RESET:-} $description"
        (( _TEST_PASSED++ )) || true
    else
        echo "  ${C_RED:-}✖${C_RESET:-} $description"
        echo "    Erwartet: (leer)"
        echo "    Erhalten: $(printf '%q' "$value")"
        (( _TEST_FAILED++ )) || true
    fi
}

# ------------------------------------------------------------
# test_summary() – Gibt Zusammenfassung aus, return = Fehleranzahl
# ------------------------------------------------------------
test_summary() {
    echo ""
    if (( _TEST_FAILED > 0 )); then
        echo "${C_RED:-}✖${C_RESET:-} $_TEST_PASSED bestanden, $_TEST_FAILED fehlgeschlagen"
    else
        echo "${C_GREEN:-}✔${C_RESET:-} $_TEST_PASSED bestanden, $_TEST_FAILED fehlgeschlagen"
    fi
    return "$_TEST_FAILED"
}
