#!/usr/bin/env zsh
# ============================================================
# run-tests.sh - Test-Runner für Validator-Bibliothek
# ============================================================
# Zweck   : Führt Unit-Tests für lib.sh und Validatoren aus
# Aufruf  : ./scripts/tests/run-tests.sh [--verbose]
# ============================================================

set -euo pipefail

# ============================================================
# ABSCHNITT 1: Konfiguration
# ============================================================
SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h:h}"
VALIDATORS_DIR="$ROOT_DIR/scripts/validators"
TESTS_DIR="$SCRIPT_DIR"

# Test-Zähler
typeset -gi TESTS_RUN=0
typeset -gi TESTS_PASSED=0
typeset -gi TESTS_FAILED=0

# Verbose-Mode
VERBOSE="${1:-}"

# Farben
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# ============================================================
# ABSCHNITT 2: Test-Framework Funktionen
# ============================================================

# Assertion: Wert ist gleich erwartetem Wert
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-assert_equals}"
    
    ((TESTS_RUN++)) || true
    
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++)) || true
        [[ "$VERBOSE" == "--verbose" ]] && print "${GREEN}✔${NC} $message"
        return 0
    else
        ((TESTS_FAILED++)) || true
        print "${RED}✖${NC} $message"
        print "    Expected: '$expected'"
        print "    Actual:   '$actual'"
        return 1
    fi
}

# Assertion: Wert ist nicht leer
assert_not_empty() {
    local actual="$1"
    local message="${2:-assert_not_empty}"
    
    ((TESTS_RUN++)) || true
    
    if [[ -n "$actual" ]]; then
        ((TESTS_PASSED++)) || true
        [[ "$VERBOSE" == "--verbose" ]] && print "${GREEN}✔${NC} $message"
        return 0
    else
        ((TESTS_FAILED++)) || true
        print "${RED}✖${NC} $message (value is empty)"
        return 1
    fi
}

# Assertion: Array enthält bestimmte Anzahl Elemente
assert_count() {
    local expected="$1"
    local actual="$2"
    local message="${3:-assert_count}"
    
    ((TESTS_RUN++)) || true
    
    if [[ "$expected" -eq "$actual" ]]; then
        ((TESTS_PASSED++)) || true
        [[ "$VERBOSE" == "--verbose" ]] && print "${GREEN}✔${NC} $message"
        return 0
    else
        ((TESTS_FAILED++)) || true
        print "${RED}✖${NC} $message"
        print "    Expected count: $expected"
        print "    Actual count:   $actual"
        return 1
    fi
}

# Assertion: Array enthält Wert
assert_contains() {
    local needle="$1"
    local haystack_name="$2"
    local message="${3:-assert_contains $needle}"
    
    ((TESTS_RUN++)) || true
    
    # Array aus Name holen
    local -a arr=("${(@P)haystack_name}")
    
    if (( ${arr[(Ie)$needle]} )); then
        ((TESTS_PASSED++)) || true
        [[ "$VERBOSE" == "--verbose" ]] && print "${GREEN}✔${NC} $message"
        return 0
    else
        ((TESTS_FAILED++)) || true
        print "${RED}✖${NC} $message (not found in array)"
        return 1
    fi
}

# Assertion: Befehl gibt Exit-Code 0 zurück
assert_success() {
    local message="${1:-assert_success}"
    shift
    local cmd=("$@")
    
    ((TESTS_RUN++)) || true
    
    if "${cmd[@]}" >/dev/null 2>&1; then
        ((TESTS_PASSED++)) || true
        [[ "$VERBOSE" == "--verbose" ]] && print "${GREEN}✔${NC} $message"
        return 0
    else
        ((TESTS_FAILED++)) || true
        print "${RED}✖${NC} $message (command failed)"
        return 1
    fi
}

# Test-Suite Header
describe() {
    print "\n${BOLD}━━━ $* ━━━${NC}"
}

# Test-Ergebnisse zusammenfassen
print_results() {
    print "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print "${BOLD}📊 Test-Ergebnisse${NC}"
    print "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print "   Tests:     $TESTS_RUN"
    print "   ${GREEN}Bestanden:${NC} $TESTS_PASSED"
    print "   ${RED}Fehlgeschlagen:${NC} $TESTS_FAILED"
    
    if (( TESTS_FAILED > 0 )); then
        print "\n${RED}❌ Tests fehlgeschlagen${NC}"
        return 1
    else
        print "\n${GREEN}✅ Alle Tests bestanden${NC}"
        return 0
    fi
}

# ============================================================
# ABSCHNITT 3: Test-Suite laden und ausführen
# ============================================================

print "${BOLD}🧪 Validator Test-Suite${NC}"
print "   Tests für lib.sh und Validatoren"

# Lade alle Test-Dateien
for test_file in "$TESTS_DIR"/test_*.sh(N); do
    [[ -f "$test_file" ]] || continue
    source "$test_file"
done

# Ergebnisse
print_results
