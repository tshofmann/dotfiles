# Copilot Instructions für dotfiles

## ⛔ KRITISCHE REGELN

Diese Regeln gelten **immer** – keine Ausnahmen:

| Regel | Warum |
|-------|-------|
| **Niemals blind ändern** | Erst Repository-Zustand prüfen, dann handeln |
| **Niemals ohne Validierung** | Shell-Syntax und Doku-Konsistenz vor Commit prüfen |
| **Niemals `--no-verify`** | Pre-Commit Hooks müssen durchlaufen |
| **Niemals Annahmen treffen** | Im Terminal verifizieren, nicht vermuten |
| **Niemals statische Zahlen in Docs** | Veralten sofort – dynamische Verweise nutzen |
| **Niemals persönliche Daten in Issues/PRs** | Öffentlich sichtbar – `~` oder `$HOME` statt `/Users/<name>` |

### Arbeitsweise (Grundprinzip)

```
Sehen → Recherchieren → Denken → Verstehen → Handeln
```

- **Repository-Zustand ist die Wahrheit** – nicht Annahmen oder veraltete Dokumentation
- **Beweispflicht** – jede Aussage mit Beleg (Code, Terminal-Output, Doku)
- **Bei Unklarheiten**: Rückfrage statt Annahme

### Validierung

Vor Commits prüfen: **Shell-Syntax**, **Dokumentations-Konsistenz**, **Tests** (wo relevant).

Validierungs-Tools liegen in `scripts/` – selbst erkunden was zur Änderung passt. Nicht blind ausführen, sondern verstehen was geprüft wird und ob es für diese Änderung relevant ist.

---

## Sprache

**Deutsch ist die erste Wahl** für alle Inhalte:
- Kommentare im Code
- Header-Beschreibungen (`# Zweck   :`, `# Hinweis :`)
- Dokumentation (README, CONTRIBUTING, docs/)
- Commit-Messages (Conventional Commits Format)
- Issue-Beschreibungen und PR-Texte

**Ausnahmen** (Englisch erlaubt):
- Technische Begriffe ohne gängige Übersetzung: `Guard`, `Symlink`, `Config`
- Code-Bezeichner: Funktionsnamen (`brewup`), Variablen (`DOTFILES_DIR`)
- Tool-Namen und Referenzen: `fzf`, `bat`, `ripgrep`

---

## Code-Stil

### Grundprinzipien
- **DRY (Don't Repeat Yourself)** – Wiederholte Logik in Funktionen/Bibliotheken auslagern
- **Single Source of Truth** – Eine Quelle für jede Information (Dateiname = Befehlsname = tldr-Seite)

### Shell-Dateien (ausschließlich ZSH)
- **Kein POSIX** – dieses Projekt ist rein ZSH (macOS Standard-Shell)
- ZSH-Features nutzen: `[[ ]]`, Parameter Expansion `${var##pattern}`, Arrays (1-indexed!)
- `set -euo pipefail` wo sinnvoll (nicht in Alias-Dateien)
- Variablen immer quoten: `"$var"` statt `$var`

### Alias-Dateien (`terminal/.config/alias/*.alias`)
- **Header-Block** am Dateianfang (siehe CONTRIBUTING.md → "Header-Block Format")
- **Guard-Check**: `if ! command -v tool >/dev/null 2>&1; then return 0; fi`
- **Beschreibungskommentar** vor jeder Funktion/Alias für `fa` und tldr-Patches
- Lokale Variablen mit `local` deklarieren
- Private Funktionen mit `_` Prefix (z.B. `_my_helper`)
- **Detaillierte Stil-Regeln**: Siehe CONTRIBUTING.md → "Stil-Regeln (automatisch geprüft)"

### fzf-Integration
- **Shell-Verhalten**: fzf nutzt `$SHELL -c` für Preview-Commands (also zsh auf macOS)
- Preview-Commands mit **ZSH-Syntax** sollten mit `zsh -c '...'` gewrappt werden
- Einfache externe Befehle (`bat`, `eza`, `gh`) brauchen kein Wrapping
- ZSH Parameter Expansion statt `sed`/`cut` für Performance
- Catppuccin Mocha Farben (definiert in `fzf/config` und `shell-colors`)
- `--header=` für Keybinding-Hinweise im Format `Key: Aktion | Key: Aktion`

### Bekannte Patterns

**Arithmetik mit `set -e`:**
```zsh
# FALSCH – bricht bei 0 ab:
((count++))

# RICHTIG:
(( count++ )) || true
count=$((count + 1))
```

**fzf Preview mit ZSH:**
```zsh
# Einfache Befehle – kein Wrapping nötig:
--preview='bat --color=always {}'

# ZSH-Syntax (Parameter Expansion etc.) – explizit wrappen:
--preview='zsh -c '\''[[ -f "$1" ]] && cat "$1"'\'' -- {}'
```

**Regex für Befehle/Funktionsnamen:**
```zsh
# IMMER Bindestriche erlauben (z.B. bat-theme):
[a-z][a-z0-9_-]*

# FALSCH – findet bat-theme nicht:
[a-z][a-z0-9_]*
```

**Array-Iteration (IFS-unabhängig):**
```zsh
# RICHTIG – robust bei beliebigem IFS:
local -a items=("${(@f)$(command)}")
for item in "${items[@]}"; do
    echo "$item"
done

# FRAGIL – abhängig von IFS-Einstellung:
local items_str=$(command | tr '\n' ' ')
for item in ${=items_str}; do
    echo "$item"
done
```

---

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

---

## Architektur-Entscheidungen

- **Plattform**: macOS mit Apple Silicon (arm64) – Bootstrap blockiert andere Architekturen
- **Designprinzip**: So dynamisch wie möglich, so statisch wie nötig
- **Modularität**: Ein Tool = Eine Alias-Datei (z.B. `bat.alias`, `fd.alias`)
- **Symlinks**: Via GNU Stow mit `--no-folding` (keine Verzeichnis-Symlinks)
- **Design**: Catppuccin Mocha als einheitliches Farbschema
- **XDG Base Directory**: Alle Configs in `~/.config/` (XDG-konform)

### Catppuccin Mocha Farben

**Vollständige Palette**: [catppuccin.com/palette](https://catppuccin.com/palette)

#### Semantische Verwendung

| Konzept | Farbe | Hex | RGB |
|---------|-------|-----|-----|
| Hintergrund | Base | `#1E1E2E` | `30, 30, 46` |
| Auswahl-Hintergrund | Surface0 | `#313244` | `49, 50, 68` |
| Rahmen | Overlay0 | `#6C7086` | `108, 112, 134` |
| Gedimmt | Overlay0 | `#6C7086` | `108, 112, 134` |
| Text | Text | `#CDD6F4` | `205, 214, 244` |
| Fehler | Red | `#F38BA8` | `243, 139, 168` |
| Erfolg | Green | `#A6E3A1` | `166, 227, 161` |
| Warnung | Yellow | `#F9E2AF` | `249, 226, 175` |
| Info | Blue | `#89B4FA` | `137, 180, 250` |
| Akzent/Header | Mauve | `#CBA6F7` | `203, 166, 247` |

#### Shell-Escape-Codes (ZSH)

Für farbige Terminal-Ausgaben in Shell-Funktionen:

```zsh
# Catppuccin Mocha – ANSI 24-bit True Color
# Format: \033[38;2;R;G;Bm (Vordergrund) oder \e[38;2;R;G;Bm
C_RESET='\033[0m'
C_MAUVE='\033[38;2;203;166;247m'   # Akzent, Header
C_GREEN='\033[38;2;166;227;161m'   # Erfolg, Aliase
C_BLUE='\033[38;2;137;180;250m'    # Info, Funktionen
C_YELLOW='\033[38;2;249;226;175m'  # Warnung, Hervorhebung
C_RED='\033[38;2;243;139;168m'     # Fehler
C_TEXT='\033[38;2;205;214;244m'    # Normaler Text
C_DIM='\033[38;2;108;112;134m'     # Gedimmter Text
```

#### Platzierung im Repository

| Kontext | Datei | Format |
|---------|-------|--------|
| **Shell-Variablen (zentral)** | `terminal/.config/shell-colors` | `$C_MAUVE` etc. |
| fzf globale Optionen | `terminal/.config/fzf/config` | `--color=name:#RRGGBB` |
| eza Dateitypen | `terminal/.config/eza/theme.yml` | `foreground: "#rrggbb"` |
| tealdeer Syntax | `terminal/.config/tealdeer/config.toml` | `rgb = { r, g, b }` |
| lazygit UI | `terminal/.config/lazygit/config.yml` | `'#RRGGBB'` |
| btop Monitoring | `terminal/.config/btop/themes/` | Theme-Datei |
| bat Syntax | `terminal/.config/bat/themes/` | tmTheme XML |
| zsh-syntax-highlighting | `terminal/.config/zsh/` | ZSH-Variablen |

> **Shell-Funktionen**: Nutze die globalen `$C_*` Variablen aus `shell-colors` statt lokaler Definitionen.

### Verweise

- **Verzeichnisstruktur**: Siehe `docs/architecture.md`
- **Installierte Tools**: Siehe `setup/Brewfile`
- **Header-Format**: Siehe CONTRIBUTING.md → "Header-Block Format"
- **Stil-Regeln**: Siehe CONTRIBUTING.md → "Stil-Regeln (automatisch geprüft)"
- **XDG Details**: Siehe `docs/architecture.md` → "XDG Base Directory Specification"
