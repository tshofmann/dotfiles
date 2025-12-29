# Copilot Instructions für dotfiles

## Git Commits

- **Niemals `--no-verify` verwenden** – Pre-Commit Hooks müssen durchlaufen
- Bei Hook-Fehlern: Problem beheben, dann erneut committen
- Commit-Messages auf Deutsch, Conventional Commits Format

## Arbeitsweise

### Grundprinzip
**Sehen → Recherchieren → Denken → Verstehen → Handeln**

- **Repository-Zustand ist die Wahrheit** – nicht Annahmen oder veraltete Dokumentation
- **Annahmen explizit validieren** – bevor darauf aufgebaut wird
- **Beweispflicht** – jede Aussage mit Beleg (Code, Terminal-Output, Doku)
- **Keine Änderungen ohne vorherige Analyse**

### Bei Unklarheiten
1. **Offizielle Dokumentation** des Tools konsultieren
2. **Man-Pages** (`man <tool>`)
3. **Im Terminal verifizieren** – testen statt vermuten
4. Bei Bedarf: Rückfrage statt Annahme

## Code-Stil

### Shell-Dateien (ausschließlich ZSH)
- **Kein POSIX** – dieses Projekt ist rein ZSH (macOS Standard-Shell)
- ZSH-Features nutzen: `[[ ]]`, Parameter Expansion `${var##pattern}`, Arrays (1-indexed!)
- `set -euo pipefail` wo sinnvoll (nicht in Alias-Dateien)
- Variablen immer quoten: `"$var"` statt `$var`

### Alias-Dateien (`terminal/.config/alias/*.alias`)
- **Header-Block** am Dateianfang (siehe fzf.alias als Template)
- **Guard-Check**: `command -v tool >/dev/null 2>&1 || return 0`
- **Beschreibungskommentar** vor jeder Funktion/Alias für Help-System
- Lokale Variablen mit `local` deklarieren
- Private Funktionen mit `_` Prefix (z.B. `_help_format`)

### fzf-Integration
- Preview-Commands **müssen** mit `zsh -c '...'` gewrappt werden (fzf nutzt /bin/sh!)
- ZSH Parameter Expansion statt `sed`/`cut` für Performance
- Catppuccin Mocha Farben (24-bit) für konsistentes Design
- `--header=` für Keybinding-Hinweise im Format `Key: Aktion | Key: Aktion`

## Architektur-Entscheidungen

- **Plattform**: macOS mit Apple Silicon (arm64) – Bootstrap blockiert andere Architekturen
- **Homebrew-Pfade**: Dynamisch erkannt (Apple Silicon → Intel → Linux)
- **Designprinzip**: So dynamisch wie möglich, so statisch wie nötig
- **Modularität**: Ein Tool = Eine Alias-Datei (z.B. `bat.alias`, `fd.alias`)
- **Symlinks**: Via GNU Stow mit `--no-folding` (keine Verzeichnis-Symlinks)

## Validierung vor Änderungen

1. `zsh -n <datei>` – Syntax-Check
2. `./scripts/tests/run-tests.sh` – Unit-Tests bei Validator-Änderungen
3. `./scripts/health-check.sh` – System-Health bei Tool-Änderungen
4. `./scripts/validate-docs.sh` – Dokumentations-Sync prüfen

**Wichtig:** Validatoren können selbst fehlerhaft sein. Bei Änderungen:
- **Nicht blind vertrauen** – Ergebnisse manuell verifizieren
- **Zeile für Zeile prüfen** – `grep`, `cat`, `diff` verwenden
- **Vor UND nach** Änderungen testen – Regression erkennen
- **Bei Validator-Fehlern**: Erst Validator fixen, dann Änderung validieren

## Bekannte Patterns

### Arithmetik mit `set -e`
```zsh
# FALSCH – bricht bei 0 ab:
((count++))

# RICHTIG:
(( count++ )) || true
count=$((count + 1))
```

### fzf Preview mit ZSH
```zsh
# FALSCH – läuft in /bin/sh:
--preview='[[ -f {} ]] && cat {}'

# RICHTIG – explizit zsh:
--preview='zsh -c '\''[[ -f "$1" ]] && cat "$1"'\'' -- {}'
```
