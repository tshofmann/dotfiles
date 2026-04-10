#!/usr/bin/env zsh
# ============================================================
# test-generator-setup.sh - Tests für generators/setup.sh
# ============================================================
# Zweck       : Unit Tests für extract_bootstrap_steps(),
#               generate_uninstall_section()
# Pfad        : .github/scripts/tests/test-generator-setup.sh
# Aufruf      : ./.github/scripts/tests/test-generator-setup.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# setup.sh → common.sh → config.sh + parsers.sh (alles in einem Source-Durchlauf)
_SOURCED_BY_GENERATOR=1
source "$SCRIPT_DIR/../generators/setup.sh"

# Originalpfade sichern
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"
_ORIG_BOOTSTRAP="$BOOTSTRAP"
_ORIG_BOOTSTRAP_MODULES="${BOOTSTRAP_MODULES:-}"

# ============================================================
# extract_bootstrap_steps() – Integration
# ============================================================
echo "=== extract_bootstrap_steps (Integration) ==="

result=$(extract_bootstrap_steps)
# Muss eine Zahl > 0 sein (echte Module vorhanden)
[[ "$result" =~ ^[0-9]+$ ]]
assert_equals "Gibt Zahl zurück" "0" "$?"
[[ "$result" -gt 0 ]]
assert_equals "Schrittanzahl > 0" "0" "$?"

# ============================================================
# extract_bootstrap_steps() – Fixture (Legacy-Pfad)
# ============================================================
echo ""
echo "=== extract_bootstrap_steps (Legacy-Fixture) ==="

# Simuliere Setup ohne Module → Legacy-Pfad
BOOTSTRAP_MODULES="$_TEST_TMPDIR/no-modules"
BOOTSTRAP="$_TEST_TMPDIR/bootstrap.sh"
mkdir -p "$_TEST_TMPDIR/no-modules"

cat > "$BOOTSTRAP" << 'FIXTURE'
#!/bin/bash
CURRENT_STEP="Pakete installieren"
do_stuff
CURRENT_STEP="Konfiguration anwenden"
do_more
CURRENT_STEP="Initialisierung"
setup_init
CURRENT_STEP="Shell konfigurieren"
FIXTURE

result=$(extract_bootstrap_steps)
# Initialisierung wird ausgeschlossen → 3 Schritte
assert_equals "Legacy: 3 Schritte (ohne Initialisierung)" "3" "$result"

# Leeres bootstrap.sh → 0 Schritte
cat > "$BOOTSTRAP" << 'FIXTURE'
#!/bin/bash
echo "keine Schritte"
FIXTURE
result=$(extract_bootstrap_steps)
assert_equals "Legacy: 0 bei fehlenden CURRENT_STEP" "0" "$result"

BOOTSTRAP="$_ORIG_BOOTSTRAP"
BOOTSTRAP_MODULES="$_ORIG_BOOTSTRAP_MODULES"

# ============================================================
# generate_uninstall_section() – Integration
# ============================================================
echo ""
echo "=== generate_uninstall_section (Integration) ==="

result=$(generate_uninstall_section)
assert_contains "Überschrift vorhanden" "## Deinstallation" "$result"
assert_contains "restore.sh Befehl" "restore.sh" "$result"
assert_contains "Symlinks Aktion" "Symlinks" "$result"
assert_contains "Dry-Run Option" "--dry-run" "$result"
assert_contains "Cleanup Option" "--cleanup" "$result"
assert_contains "Backup-Hinweis" "Backup" "$result"

# ============================================================
# generate_uninstall_section() – fehlende restore.sh
# ============================================================
echo ""
echo "=== generate_uninstall_section (ohne restore.sh) ==="

_ORIG_DOTFILES_DIR2="$DOTFILES_DIR"
DOTFILES_DIR="$_TEST_TMPDIR/no-restore"
mkdir -p "$DOTFILES_DIR/setup"
# Kein restore.sh erstellen → Early Return

result=$(generate_uninstall_section)
assert_equals "Ohne restore.sh: leere Ausgabe" "" "$result"

DOTFILES_DIR="$_ORIG_DOTFILES_DIR2"

# ============================================================
# ToC-Konsistenz (Integration) – setup.md
# ============================================================
echo ""
echo "=== ToC-Konsistenz (Integration) ==="

result=$(generate_setup_md)

# ToC-Überschrift vorhanden
assert_contains "ToC: Inhalt-Überschrift" "## Inhalt" "$result"

# ToC-Vollständigkeit: Zähle ToC-Einträge vs. ## Überschriften im Body
# State-Machine: in_toc / past_toc
local toc_count=0 heading_count=0 in_toc=false past_toc=false
while IFS= read -r _line; do
    if [[ "$_line" == "## Inhalt" ]]; then
        in_toc=true
        continue
    fi
    if $in_toc && ! $past_toc; then
        if [[ "$_line" == '- ['* || "$_line" == '  - ['* ]]; then
            (( toc_count++ )) || true
        elif [[ "$_line" == '## '* || "$_line" == "---" ]]; then
            past_toc=true
            [[ "$_line" == '## '* ]] && (( heading_count++ )) || true
        fi
    elif $past_toc; then
        [[ "$_line" == '## '* || "$_line" == '### '* ]] && (( heading_count++ )) || true
    fi
done <<< "$result"
assert_equals "ToC-Vollständigkeit: Einträge == Überschriften" "$heading_count" "$toc_count"

# Bekannte Überschriften im ToC
assert_contains "ToC: Voraussetzungen" "[Voraussetzungen]" "$result"
assert_contains "ToC: Installierte Pakete" "[Installierte Pakete]" "$result"
assert_contains "ToC: Deinstallation" "[Deinstallation" "$result"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
