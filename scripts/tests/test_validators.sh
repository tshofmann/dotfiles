#!/usr/bin/env zsh
# ============================================================
# test_validators.sh - Integration-Tests für Validatoren
# ============================================================
# Zweck   : Testet dass alle Validatoren ladbar und ausführbar sind
# Aufruf  : Wird von run-tests.sh gesourced
# ============================================================

# ============================================================
# TEST: Validator-Dateien laden
# ============================================================
describe "Validator-Dateien"

# Core-Validatoren
for validator in "$VALIDATORS_DIR/core"/*.sh(N); do
    [[ -f "$validator" ]] || continue
    local name="${validator:t}"
    assert_success "$name ist syntaktisch korrekt" zsh -n "$validator"
done

# Extended-Validatoren
for validator in "$VALIDATORS_DIR/extended"/*.sh(N); do
    [[ -f "$validator" ]] || continue
    local name="${validator:t}"
    assert_success "$name ist syntaktisch korrekt" zsh -n "$validator"
done

# ============================================================
# TEST: Alle Validatoren registriert
# ============================================================
describe "Validator-Registrierung"

# Reset und neu laden
REGISTERED_VALIDATORS=()
CORE_VALIDATORS=()
EXTENDED_VALIDATORS=()
VALIDATOR_LIB_LOADED=""

# lib.sh laden
source "$VALIDATORS_DIR/lib.sh"

# Alle Validatoren laden
for validator in "$VALIDATORS_DIR/core"/*.sh(N) "$VALIDATORS_DIR/extended"/*.sh(N); do
    [[ -f "$validator" ]] || continue
    source "$validator"
done

# Erwartete Core-Validatoren
local -a expected_core=(aliases bootstrap brewfile config healthcheck macos starship symlinks)
for name in "${expected_core[@]}"; do
    assert_contains "$name" CORE_VALIDATORS "Core-Validator '$name' registriert"
done

# Erwartete Extended-Validatoren
local -a expected_extended=(alias-names codeblocks copilot-instructions structure style-consistency terminal-profile)
for name in "${expected_extended[@]}"; do
    assert_contains "$name" EXTENDED_VALIDATORS "Extended-Validator '$name' registriert"
done

# ============================================================
# TEST: Validator-Funktionen ausführbar
# ============================================================
describe "Validator-Funktionen"

# Redirect Output für sauberere Test-Ausgabe
for entry in "${REGISTERED_VALIDATORS[@]}"; do
    local name="${entry%%:*}"
    local rest="${entry#*:}"
    local func="${rest%%:*}"
    
    # Prüfe ob Funktion existiert
    ((TESTS_RUN++)) || true
    if (( ${+functions[$func]} )); then
        ((TESTS_PASSED++)) || true
        [[ "$VERBOSE" == "--verbose" ]] && print "${GREEN}✔${NC} Funktion '$func' für '$name' existiert"
    else
        ((TESTS_FAILED++)) || true
        print "${RED}✖${NC} Funktion '$func' für '$name' nicht gefunden"
    fi
done

# ============================================================
# TEST: print_summary() Funktion
# ============================================================
describe "print_summary()"

# Test mit Errors - capture exit code safely
VALIDATOR_ERRORS=1
VALIDATOR_WARNINGS=0
VALIDATOR_PASSED=5

local exit_with_errors=0
print_summary >/dev/null 2>&1 || exit_with_errors=$?

assert_equals 1 "$exit_with_errors" "print_summary gibt 1 bei Errors zurück"

# Test ohne Errors, nur Warnings
VALIDATOR_ERRORS=0
VALIDATOR_WARNINGS=2
VALIDATOR_PASSED=5

local exit_with_warnings=0
print_summary >/dev/null 2>&1 || exit_with_warnings=$?

assert_equals 0 "$exit_with_warnings" "print_summary gibt 0 bei nur Warnings zurück"

# Reset
VALIDATOR_ERRORS=0
VALIDATOR_WARNINGS=0
VALIDATOR_PASSED=0
