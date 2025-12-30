# Copilot Instructions für dotfiles

## Sprache

**Deutsch ist die erste Wahl** für alle Inhalte in diesem Repository:
- Kommentare im Code
- Header-Beschreibungen (`# Zweck   :`, `# Hinweis :`)
- Dokumentation (README, CONTRIBUTING, docs/)
- Commit-Messages (Conventional Commits Format)
- Issue-Beschreibungen und PR-Texte

**Ausnahmen** (Englisch erlaubt):
- Technische Begriffe ohne gängige Übersetzung: `Guard`, `Symlink`, `Config`
- Code-Bezeichner: Funktionsnamen (`brewup`), Variablen (`DOTFILES_DIR`)
- Tool-Namen und Referenzen: `fzf`, `bat`, `ripgrep`

## Git Commits

- **Niemals `--no-verify` verwenden** – Pre-Commit Hooks müssen durchlaufen
- Bei Hook-Fehlern: Problem beheben, dann erneut committen
- Commit-Messages auf Deutsch, Conventional Commits Format

## GitHub Issues

### Grundprinzip
**Gründlich recherchieren, sorgfältig strukturieren, dynamisch formulieren**

Jedes Issue erfordert **vor dem Schreiben**:
1. **Repository-Analyse**: Was existiert bereits? Welche Patterns werden verwendet?
2. **Offizielle Dokumentation**: Tool-Manuals, API-Docs, Best Practices
3. **Community-Patterns**: Wie lösen andere das Problem? (GitHub, StackOverflow)
4. **Gap-Analyse**: Was fehlt konkret? Warum ist es relevant?

### Issue-Typen und Symbole

| Symbol | Typ | Beschreibung | Labels |
|--------|-----|--------------|--------|
| 💡 | Idee | Zur Diskussion, nicht entschieden | `idea`, `enhancement` |
| ✨ | Feature | Konkrete Erweiterung, umsetzungsreif | `enhancement` |
| 🐛 | Bug | Fehler im bestehenden Code | `bug` |
| 📝 | Doku | Dokumentations-Verbesserung | `documentation` |
| 🔧 | Chore | Refactoring, Maintenance | `enhancement` |
| 🌿 | Theming | Catppuccin/Design-bezogen | `theming`, `enhancement` |

**Titel-Format**: `Symbol Typ: Kurzname` (z.B. `💡 Idee: uninstall.sh`)

### Struktur nach Typ

#### Ideen (`💡`)
```markdown
> 💡 **Dies ist eine Idee zur Diskussion** – [kurzer Kontext]

## Kontext
[Warum ist das relevant? Was ist der Auslöser?]

## Recherche
[Offizielle Doku, Community-Patterns, Quellen mit Links]

## Vorgeschlagenes Design
[Konkrete Vorschläge, Code-Beispiele, Diagramme]

## Scope
[Tabelle mit Bewertung – siehe unten]

## Offene Fragen
[Nummerierte Liste der zu klärenden Punkte]

## Verwandte Issues
[Cross-Links]
```

#### Features/Bugs/Chores (`✨`, `🐛`, `🔧`, `🌿`)
```markdown
## Problemstellung
[Was ist das Problem? Gap-Analyse, ggf. Tabelle]

## Recherche
[Offizielle Doku, Community-Patterns, Quellen]

## Umsetzung
[Konkreter Plan, Code-Beispiele, Empfehlung]

## Scope
[Tabelle mit Bewertung]

## Aufgaben
- [ ] Checkbox-Liste der konkreten Schritte

## Verwandte Issues
[Cross-Links]
```

### Scope-Tabelle (immer erforderlich)

```markdown
| Kriterium | Bewertung |
|-----------|-----------|
| Komplexität | 🟢 Gering / 🟡 Mittel / 🔴 Hoch |
| Wartungsaufwand | 🟢 Minimal / 🟡 Regelmäßig / 🔴 Aufwändig |
| Testbarkeit | 🟢 Automatisiert / 🟡 Manuell / 🔴 Schwierig |
| Abhängigkeiten | 🟢 Keine / 🟡 Wenige / 🔴 Viele |
| Breaking Risk | 🟢 Keins / 🟡 Minor / 🔴 Major |
```

### Dynamische Formulierungen

**NIEMALS statische Angaben die veralten:**
- ❌ "123 Sterne", "Letztes Update: Dezember 2025"
- ❌ "Version 1.2.3 ist aktuell"

**STATTDESSEN relative/prüfbare Aussagen:**
- ✅ "Aktiv gepflegt" (Link zum Repo)
- ✅ "MIT-lizenziert"
- ✅ "Verfügbar via Homebrew" (prüfbar mit `brew info`)

### Labels

| Label | Verwendung |
|-------|------------|
| `idea` | Ideen zur Diskussion (mit `💡`) |
| `enhancement` | Features und Verbesserungen |
| `bug` | Fehler |
| `documentation` | Doku-Änderungen |
| `theming` | Catppuccin/Design |
| `low-priority` | Nice-to-have, nicht dringend |

### Qualitäts-Checkliste vor Submit

- [ ] Titel hat korrektes Symbol und Format
- [ ] Recherche mit verlinkten Quellen
- [ ] Scope-Tabelle vorhanden
- [ ] Keine statischen Angaben die veralten können
- [ ] Labels gesetzt
- [ ] Verwandte Issues verlinkt
- [ ] Bei Ideen: Offene Fragen formuliert
- [ ] Bei Features: Aufgaben-Checkboxen

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
- Catppuccin Mocha Farben (definiert in `fzf/config` und `help.alias`)
- `--header=` für Keybinding-Hinweise im Format `Key: Aktion | Key: Aktion`

### Catppuccin Mocha – Designrichtlinie
Catppuccin Mocha ist das **verbindliche Farbschema** für alle Tools.

**Theme-Konfigurationen:** Siehe `docs/architecture.md` → "Verzeichnisstruktur"

**Hauptfarben** (für eigene Erweiterungen):
| Konzept | Farbe | Hex |
|---------|-------|-----|
| Hintergrund | Base | `#1E1E2E` |
| Text | Text | `#CDD6F4` |
| Fehler | Red | `#F38BA8` |
| Erfolg | Green | `#A6E3A1` |
| Warnung | Yellow | `#F9E2AF` |
| Info | Blue | `#89B4FA` |
| Akzent | Mauve | `#CBA6F7` |

Vollständige Palette: [catppuccin.com/palette](https://catppuccin.com/palette)

## Architektur-Entscheidungen

- **Plattform**: macOS mit Apple Silicon (arm64) – Bootstrap blockiert andere Architekturen
- **Homebrew-Pfade**: Dynamisch erkannt in `.zprofile` (für potenzielle Zukunft: Intel/Linux)
- **Designprinzip**: So dynamisch wie möglich, so statisch wie nötig
- **Modularität**: Ein Tool = Eine Alias-Datei (z.B. `bat.alias`, `fd.alias`)
- **Symlinks**: Via GNU Stow mit `--no-folding` (keine Verzeichnis-Symlinks)
- **Design**: Catppuccin Mocha als einheitliches Farbschema
- **XDG Base Directory**: Alle Configs in `~/.config/` (XDG-konform)

### XDG Base Directory Specification

Alle Tool-Konfigurationen folgen der [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/).

**Wichtig für macOS:**
- `dirs::config_dir()` in Rust gibt `~/Library/Application Support` zurück, **nicht** `~/.config`
- Tools wie `eza` respektieren `XDG_CONFIG_HOME` nicht – daher explizit `EZA_CONFIG_DIR` setzen
- XDG-Variablen sind in `.zshenv` definiert

Details: Siehe `docs/architecture.md` → "XDG Base Directory Specification"

### Verzeichnisstruktur & Tools

**Aktuelle Struktur:** Siehe `docs/architecture.md` → "Verzeichnisstruktur"  
**Installierte Tools:** Siehe `setup/Brewfile`

### Help-System
- `help` – Interaktive Suche aller Aliase/Funktionen mit fzf
- Jede Funktion/Alias braucht Beschreibungskommentar darüber
- Private Helper mit `_` Prefix werden ignoriert

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
