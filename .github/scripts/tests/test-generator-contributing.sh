#!/usr/bin/env zsh
# ============================================================
# test-generator-contributing.sh - Tests für generators/contributing.sh
# ============================================================
# Zweck       : Unit Tests für generate_contributing_md()
# Pfad        : .github/scripts/tests/test-generator-contributing.sh
# Aufruf      : ./.github/scripts/tests/test-generator-contributing.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# contributing.sh → common.sh (alles in einem Source-Durchlauf)
_SOURCED_BY_GENERATOR=1
source "$SCRIPT_DIR/../generators/contributing.sh"

# Originalpfade sichern
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"

# ============================================================
# generate_contributing_md() – Integration
# ============================================================
echo "=== generate_contributing_md (Integration) ==="

result=$(generate_contributing_md)

# ToC-Überschrift vorhanden
assert_contains "ToC: Inhalt-Überschrift" "## Inhalt" "$result"

# Bekannte Überschriften im ToC
assert_contains "ToC: Quick Setup" "[Quick Setup (Entwickler)]" "$result"
assert_contains "ToC: Code-Konventionen" "[Code-Konventionen]" "$result"
assert_contains "ToC: Häufige Aufgaben" "[Häufige Aufgaben]" "$result"
assert_contains "ToC: Dokumentation" "[Dokumentation]" "$result"

# ============================================================
# ToC-Konsistenz (Integration)
# ============================================================
echo ""
echo "=== ToC-Konsistenz (Integration) ==="

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

# ============================================================
# Idempotenz – zweimaliger Durchlauf identisch
# ============================================================
echo ""
echo "=== Idempotenz ==="

result_first=$(generate_contributing_md)
# Schreibe erste Ausgabe als Eingabe-Datei
DOTFILES_DIR="$_TEST_TMPDIR/idem"
mkdir -p "$DOTFILES_DIR"
printf '%s\n' "$result_first" > "$DOTFILES_DIR/CONTRIBUTING.md"

result_second=$(generate_contributing_md)
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

assert_equals "Idempotenz: zweiter Durchlauf identisch" "$result_first" "$result_second"

# ============================================================
# Code-Block-Robustheit
# ============================================================
echo ""
echo "=== Code-Block-Robustheit ==="

DOTFILES_DIR="$_TEST_TMPDIR/codeblock"
mkdir -p "$DOTFILES_DIR"
cat > "$DOTFILES_DIR/CONTRIBUTING.md" << 'FIXTURE'
# Test-Projekt

Header-Text hier.

## Setup

Einleitung.

```zsh
## Das ist KEIN Heading
echo "test"
```

## Zweiter Abschnitt

Inhalt.
FIXTURE

result=$(generate_contributing_md)
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

assert_contains "Code-Block: Setup im ToC" "[Setup]" "$result"
assert_contains "Code-Block: Zweiter Abschnitt im ToC" "[Zweiter Abschnitt]" "$result"

# ToC darf nur 2 Einträge haben (Code-Block-Heading ignoriert)
local cb_toc_count=0
while IFS= read -r _line; do
    [[ "$_line" == '- ['* || "$_line" == '  - ['* ]] && (( cb_toc_count++ )) || true
done <<< "$(echo "$result" | sed -n '/^## Inhalt$/,/^## /{ /^## Inhalt$/d; /^## /q; p; }')"
assert_equals "Code-Block: Genau 2 ToC-Einträge" "2" "$cb_toc_count"

# ============================================================
# Fixture: Fehlende CONTRIBUTING.md
# ============================================================
echo ""
echo "=== Fehlende CONTRIBUTING.md ==="

DOTFILES_DIR="$_TEST_TMPDIR/missing"
mkdir -p "$DOTFILES_DIR"

result=$(generate_contributing_md 2>/dev/null)
local rc=$?
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

assert_equals "Fehlende Datei: Exit-Code 1" "1" "$rc"
assert_empty "Fehlende Datei: Keine Ausgabe" "$result"

# ============================================================
# Fixture: Bestehender ToC wird ersetzt
# ============================================================
echo ""
echo "=== Bestehender ToC wird ersetzt ==="

DOTFILES_DIR="$_TEST_TMPDIR/replace-toc"
mkdir -p "$DOTFILES_DIR"
cat > "$DOTFILES_DIR/CONTRIBUTING.md" << 'FIXTURE'
# Mein Projekt

Beschreibung.

## Inhalt

- [Alter Eintrag](#alter-eintrag)

## Erster Abschnitt

Text.

## Zweiter Abschnitt

Mehr Text.
FIXTURE

result=$(generate_contributing_md)
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

# Alter Eintrag darf nicht in der Ausgabe sein
local old_toc_present=false
[[ "$result" == *"[Alter Eintrag]"* ]] && old_toc_present=true
assert_equals "ToC-Ersetzung: Alter Eintrag entfernt" "false" "$old_toc_present"

# Neue Einträge müssen vorhanden sein
assert_contains "ToC-Ersetzung: Erster Abschnitt" "[Erster Abschnitt]" "$result"
assert_contains "ToC-Ersetzung: Zweiter Abschnitt" "[Zweiter Abschnitt]" "$result"

# Kein doppeltes ## Inhalt
local inhalt_count
inhalt_count=$(echo "$result" | grep -c '^## Inhalt$')
assert_equals "ToC-Ersetzung: Genau ein ## Inhalt" "1" "$inhalt_count"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
