# Copilot Instructions für dotfiles

## Git Commits

- **Niemals `--no-verify` verwenden** – Pre-Commit Hooks müssen durchlaufen
- Bei Hook-Fehlern: Problem beheben, dann erneut committen
- Commit-Messages auf Deutsch, Conventional Commits Format

## Arbeitsweise

### Grundprinzip
**Sehen → Recherchieren → Denken → Verstehen → Handeln**

Gilt für **jede** Änderung – Features, Bugfixes, Refactoring, Dokumentation:

- **Repository-Zustand ist die Wahrheit** – nicht Annahmen oder veraltete Dokumentation
- **Annahmen explizit validieren** – bevor darauf aufgebaut wird
- **Beweispflicht** – jede Aussage mit Beleg (Code, Terminal-Output, Doku)
- **Keine Änderungen ohne vorherige Analyse**
- **Nach jeder Änderung manuell verifizieren** – nicht nur Tests laufen lassen

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
- **Guard-Check**: `if ! command -v tool >/dev/null 2>&1; then return 0; fi`
- **Beschreibungskommentar** vor jeder Funktion/Alias für Help-System
- Lokale Variablen mit `local` deklarieren
- Private Funktionen mit `_` Prefix (z.B. `_help_format`)
- **Detaillierte Stil-Regeln**: Siehe CONTRIBUTING.md → "Stil-Regeln (automatisch geprüft)"

### fzf-Integration
- **Shell-Verhalten**: fzf nutzt `$SHELL -c` für Preview-Commands (also zsh auf macOS)
- Preview-Commands mit **ZSH-Syntax** sollten dennoch mit `zsh -c '...'` gewrappt werden:
  - Explizite Dokumentation der Shell-Abhängigkeit
  - Portabilität falls jemand `SHELL=/bin/bash` hat
- Einfache externe Befehle (`bat`, `eza`, `gh`) brauchen kein Wrapping
- ZSH Parameter Expansion statt `sed`/`cut` für Performance
- Catppuccin Mocha Farben (definiert in `help.alias`, Zeile 166+)
- `--header=` für Keybinding-Hinweise im Format `Key: Aktion | Key: Aktion`

## Architektur-Entscheidungen

- **Plattform**: macOS mit Apple Silicon (arm64) – Bootstrap blockiert andere Architekturen
- **Homebrew-Pfade**: Dynamisch erkannt in `.zprofile` (für potenzielle Zukunft: Intel/Linux)
- **Designprinzip**: So dynamisch wie möglich, so statisch wie nötig
- **Modularität**: Ein Tool = Eine Alias-Datei (z.B. `bat.alias`, `fd.alias`)
- **Symlinks**: Via GNU Stow mit `--no-folding` (keine Verzeichnis-Symlinks)

## Validierung vor Änderungen

**Konsistenz-Prinzip**: Code = Help = Doku = Copilot-Instructions
- Jede Änderung muss in **allen** betroffenen Stellen reflektiert werden
- Patterns/Syntax müssen überall identisch dokumentiert sein

1. `zsh -n <datei>` – Syntax-Check
2. `./scripts/tests/run-tests.sh` – Unit-Tests bei Validator-Änderungen
3. `./scripts/health-check.sh` – System-Health bei Tool-Änderungen
4. `./scripts/validate-docs.sh` – Dokumentations-Sync prüfen

**Validatoren sind Rettungsseile, nicht Wahrheit:**
- **Niemals blind vertrauen** – Validatoren können selbst Bugs haben
- **Jeden Check manuell verifizieren** – `grep`, `cat`, `diff` verwenden
- **Gegenprobe machen** – Fehlerhafte Eingabe muss Fehler auslösen
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
# fzf nutzt $SHELL -c (also zsh auf macOS)
# Aber ZSH-Syntax sollte explizit gewrappt werden für Klarheit/Portabilität:

# Einfache Befehle – kein Wrapping nötig:
--preview='bat --color=always {}'

# ZSH-Syntax (Parameter Expansion etc.) – explizit wrappen:
--preview='zsh -c '\''[[ -f "$1" ]] && cat "$1"'\'' -- {}'
```
