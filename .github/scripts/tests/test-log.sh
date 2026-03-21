#!/usr/bin/env zsh
# ============================================================
# test-log.sh - Unit Tests für geteilte Logging-Library
# ============================================================
# Zweck       : Prüft log.sh Funktionen, Guard und Fallback
# Pfad        : .github/scripts/tests/test-log.sh
# Aufruf      : zsh ./.github/scripts/tests/test-log.sh
# Nutzt       : assertions.sh (Test-Framework)
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# ── Test 1: Funktionen existieren nach source ──────────────
unset _LOG_SH_LOADED 2>/dev/null || true
source "$SCRIPT_DIR/../lib/log.sh"

assert_equals "log ist definiert" "log: function" "$(type -w log)"
assert_equals "ok ist definiert" "ok: function" "$(type -w ok)"
assert_equals "warn ist definiert" "warn: function" "$(type -w warn)"
assert_equals "err ist definiert" "err: function" "$(type -w err)"

# ── Test 2: Guard verhindert Mehrfach-Laden ────────────────
typeset _loaded_before="$_LOG_SH_LOADED"
source "$SCRIPT_DIR/../lib/log.sh"
assert_equals "Guard verhindert Doppel-Load" "$_loaded_before" "$_LOG_SH_LOADED"

# ── Test 3: err schreibt nach stderr ───────────────────────
typeset stderr_output
stderr_output="$(err 'testfehler' 2>&1 1>/dev/null)"
assert_contains "err schreibt nach stderr" "testfehler" "$stderr_output"

# ── Test 4: ok schreibt nach stdout ────────────────────────
typeset stdout_output
stdout_output="$(ok 'testerfolg' 2>/dev/null)"
assert_contains "ok schreibt nach stdout" "testerfolg" "$stdout_output"

# ── Test 5: %-Zeichen werden NICHT expandiert ──────────────
# (Unterschied zu print -P, wo %B → Bold etc.)
typeset pct_output
pct_output="$(log '50% fertig' 2>/dev/null)"
assert_contains "Prozentzeichen bleiben erhalten" "50% fertig" "$pct_output"

# ── Test 6: Ohne theme-style (graceful degradation) ────────
unset C_BLUE C_GREEN C_YELLOW C_RED C_RESET _LOG_SH_LOADED 2>/dev/null || true
DOTFILES_DIR="/nonexistent"
source "$SCRIPT_DIR/../lib/log.sh"
typeset fallback_output
fallback_output="$(log 'farblos' 2>/dev/null)"
assert_contains "Funktioniert ohne Farben" "farblos" "$fallback_output"

# ── Zusammenfassung ────────────────────────────────────────
test_summary
