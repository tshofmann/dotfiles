#!/usr/bin/env zsh
# ============================================================
# test_lib.sh - Unit-Tests für validators/lib.sh
# ============================================================
# Zweck   : Testet alle Funktionen aus lib.sh
# Aufruf  : Wird von run-tests.sh gesourced
# ============================================================

# Source lib.sh wenn noch nicht geladen
[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "$VALIDATORS_DIR/lib.sh"

# ============================================================
# TEST: Pfad-Konfiguration
# ============================================================
describe "Pfad-Konfiguration"

assert_not_empty "$DOTFILES_DIR" "DOTFILES_DIR ist gesetzt"
assert_not_empty "$DOCS_DIR" "DOCS_DIR ist gesetzt"
assert_not_empty "$TERMINAL_DIR" "TERMINAL_DIR ist gesetzt"
assert_not_empty "$ALIAS_DIR" "ALIAS_DIR ist gesetzt"

assert_success "DOTFILES_DIR existiert" test -d "$DOTFILES_DIR"
assert_success "DOCS_DIR existiert" test -d "$DOCS_DIR"
assert_success "TERMINAL_DIR existiert" test -d "$TERMINAL_DIR"
assert_success "ALIAS_DIR existiert" test -d "$ALIAS_DIR"

# ============================================================
# TEST: extract_aliases_from_file()
# ============================================================
describe "extract_aliases_from_file()"

# Erstelle temporäre Test-Datei
local test_alias_file=$(mktemp)
cat > "$test_alias_file" << 'EOF'
# Test-Aliase
alias foo='echo foo'
alias bar='echo bar'
  alias baz='echo baz'
# alias commented='out'
function notanalias() { echo test; }
EOF

local -a extracted=($(extract_aliases_from_file "$test_alias_file"))
assert_count 3 "${#extracted[@]}" "Extrahiert 3 Aliase"
assert_contains "foo" extracted "Enthält 'foo'"
assert_contains "bar" extracted "Enthält 'bar'"
assert_contains "baz" extracted "Enthält 'baz' (mit Einrückung)"

rm -f "$test_alias_file"

# ============================================================
# TEST: extract_functions_from_file()
# ============================================================
describe "extract_functions_from_file()"

local test_func_file=$(mktemp)
cat > "$test_func_file" << 'EOF'
# Test-Funktionen
myfunc() {
    echo "test"
}

otherfunc() {
    echo "other"
}

  indented() { echo "indented"; }

_private_func() {
    # Sollte ignoriert werden (beginnt mit _)
    echo "private"
}
EOF

local -a funcs=($(extract_functions_from_file "$test_func_file"))
assert_count 3 "${#funcs[@]}" "Extrahiert 3 öffentliche Funktionen"
assert_contains "myfunc" funcs "Enthält 'myfunc'"
assert_contains "otherfunc" funcs "Enthält 'otherfunc'"
assert_contains "indented" funcs "Enthält 'indented'"

rm -f "$test_func_file"

# ============================================================
# TEST: extract_aliases_from_docs()
# ============================================================
describe "extract_aliases_from_docs()"

local test_docs_file=$(mktemp)
cat > "$test_docs_file" << 'EOF'
# Dokumentation

### Aliase

| Alias | Beschreibung |
|-------|--------------|
| `foo` | Macht foo |
| `bar` | Macht bar |
| `baz`, `qux` | Multi-alias |

### Andere Sektion

Hier steht anderes.
EOF

local -a doc_aliases=($(extract_aliases_from_docs "$test_docs_file" "Aliase"))
assert_count 4 "${#doc_aliases[@]}" "Extrahiert 4 Aliase aus Docs"
assert_contains "foo" doc_aliases "Enthält 'foo'"
assert_contains "bar" doc_aliases "Enthält 'bar'"
assert_contains "baz" doc_aliases "Enthält 'baz'"
assert_contains "qux" doc_aliases "Enthält 'qux' (Multi-Alias)"

rm -f "$test_docs_file"

# ============================================================
# TEST: Zähler-Funktionen
# ============================================================
describe "Logging und Zähler"

# Reset Zähler
VALIDATOR_ERRORS=0
VALIDATOR_WARNINGS=0
VALIDATOR_PASSED=0

# Teste ok()
ok "Test-OK" >/dev/null
assert_equals 1 "$VALIDATOR_PASSED" "ok() erhöht VALIDATOR_PASSED"

# Teste warn()
warn "Test-Warning" >/dev/null
assert_equals 1 "$VALIDATOR_WARNINGS" "warn() erhöht VALIDATOR_WARNINGS"

# Teste err()
err "Test-Error" >/dev/null
assert_equals 1 "$VALIDATOR_ERRORS" "err() erhöht VALIDATOR_ERRORS"

# Reset für weitere Tests
VALIDATOR_ERRORS=0
VALIDATOR_WARNINGS=0
VALIDATOR_PASSED=0

# ============================================================
# TEST: Validator-Registry
# ============================================================
describe "Validator-Registry"

# Backup bestehender Registrierungen
local -a backup_validators=("${REGISTERED_VALIDATORS[@]}")
local -a backup_core=("${CORE_VALIDATORS[@]}")
local -a backup_extended=("${EXTENDED_VALIDATORS[@]}")

# Reset Registry
REGISTERED_VALIDATORS=()
CORE_VALIDATORS=()
EXTENDED_VALIDATORS=()

# Test-Validator registrieren
_test_validator() { echo "test"; }
register_validator "test_val" "_test_validator" "Test Validator" "core"

assert_count 1 "${#REGISTERED_VALIDATORS[@]}" "Ein Validator registriert"
assert_count 1 "${#CORE_VALIDATORS[@]}" "Ein Core-Validator"

# Noch einen Extended-Validator
_test_ext_validator() { echo "extended"; }
register_validator "test_ext" "_test_ext_validator" "Extended Test" "extended"

assert_count 2 "${#REGISTERED_VALIDATORS[@]}" "Zwei Validatoren registriert"
assert_count 1 "${#EXTENDED_VALIDATORS[@]}" "Ein Extended-Validator"

# Registry wiederherstellen
REGISTERED_VALIDATORS=("${backup_validators[@]}")
CORE_VALIDATORS=("${backup_core[@]}")
EXTENDED_VALIDATORS=("${backup_extended[@]}")

# ============================================================
# TEST: load_all_definitions()
# ============================================================
describe "load_all_definitions()"

# Funktion aufrufen
load_all_definitions

assert_not_empty "${ALL_ALIASES[*]:-}" "ALL_ALIASES wurde gefüllt"
assert_not_empty "${ALL_FUNCTIONS[*]:-}" "ALL_FUNCTIONS wurde gefüllt"

# Stichproben-Prüfung bekannter Aliase
assert_contains "ls" ALL_ALIASES "Enthält 'ls' Alias (aus eza.alias)"
assert_contains "cat" ALL_ALIASES "Enthält 'cat' Alias (aus bat.alias)"
assert_contains "glog" ALL_FUNCTIONS "Enthält 'glog' Funktion (aus git.alias)"
