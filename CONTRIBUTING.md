# 🤝 Contributing

Anleitung für die Entwicklung an diesem dotfiles-Repository.

---

## Quick Setup (Entwickler)

```zsh
# 1. Repository klonen
git clone https://github.com/tshofmann/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Setup ausführen (installiert alle Tools)
./setup/bootstrap.sh

# 3. Git Hooks aktivieren
git config core.hooksPath .github/hooks

# 4. Konfiguration verlinken
stow --adopt -R terminal editor && git reset --hard HEAD
```

Nach Schritt 3 wird bei jedem Commit automatisch geprüft, ob Dokumentation und Code synchron sind.

---

## Repository-Struktur

Siehe [architecture.md → Verzeichnisstruktur](docs/architecture.md#verzeichnisstruktur) für die vollständige Struktur.

**Kurzübersicht der wichtigsten Pfade:**

| Pfad | Zweck |
| ------ | ------- |
| `.github/scripts/generators/` | Dokumentations-Generatoren (Single Source of Truth) |
| `.github/scripts/tests/` | Unit-Tests für Generatoren |
| `setup/` | Bootstrap, Brewfile, Terminal-Profil |
| `terminal/` | Dotfiles (werden nach `~` verlinkt) |
| `docs/` | Dokumentation für Endnutzer |

---

## Git Hooks

### Aktivierung

```zsh
git config core.hooksPath .github/hooks
```

### Verfügbare Hooks

| Hook | Zweck |
| ------ | ------- |
| `pre-commit` | 1. ZSH-Syntax (`zsh -n`) für `.github/scripts/**/*.sh`, `terminal/.config/alias/*.alias`, `setup/bootstrap.sh` |
| | 2. Doku-Konsistenz (vergleicht generierte mit aktuellen Docs) |
| | 3. Alias-Format (Header-Block, Guard-Check) |

### Hook schlägt fehl?

Wenn der Pre-Commit Hook fehlschlägt:

```zsh
# Dokumentation neu generieren
./.github/scripts/generate-docs.sh --generate

# Dann erneut committen
git add . && git commit -m "..."
```

> ⚠️ **Niemals** `--no-verify` verwenden – die Hooks existieren aus gutem Grund.

---

## Dokumentations-Validierung

Die Dokumentation wird automatisch aus dem Code generiert (Single Source of Truth).

### Manuell ausführen

```zsh
# Prüfen ob Dokumentation aktuell ist
./.github/scripts/generate-docs.sh --check

# Dokumentation neu generieren
./.github/scripts/generate-docs.sh --generate
```

### Unit-Tests für Generatoren

```zsh
# Tests ausführen
./.github/scripts/tests/test_generators.sh
```

Die Test-Suite prüft:

- Pfad-Konfiguration (DOTFILES_DIR, etc.)
- Extraktions-Funktionen (Aliase, Funktionen, Docs)
- Logging und Zähler (ok, warn, err)

### Was wird generiert?

Siehe [architecture.md → Single Source of Truth](docs/architecture.md#single-source-of-truth) für die vollständige Übersicht.

### Bei Fehlern

1. Öffne die gemeldete Dokumentationsdatei
2. Aktualisiere den veralteten Abschnitt **im Code** (nicht in der Doku!)
3. Führe `./.github/scripts/generate-docs.sh --generate` aus
4. Committe die Änderung

---

## Sprach- und Kommentar-Richtlinie

### Sprache: Deutsch als erste Wahl

**Deutsch** ist die bevorzugte Sprache für alle Inhalte in diesem Repository:

| Bereich | Sprache | Beispiel |
| --------- | --------- | ---------- |
| **Kommentare im Code** | Deutsch | `# Nur wenn bat installiert ist` |
| **Header-Beschreibungen** | Deutsch | `# Zweck   : Aliase für bat` |
| **Dokumentation** | Deutsch | README, CONTRIBUTING, docs/ |
| **Commit-Messages** | Deutsch | `feat: fzf-Preview für git log` |
| **Issue-Beschreibungen** | Deutsch | GitHub Issues & PRs |

**Ausnahmen** (Englisch erlaubt):

- **Technische Begriffe** ohne gängige Übersetzung: `Guard`, `Symlink`, `Config`
- **Code-Bezeichner**: Funktionsnamen (`brewup`), Variablen (`DOTFILES_DIR`)
- **Tool-Namen und Referenzen**: `fzf`, `bat`, `ripgrep`
- **URLs und Pfade**: `~/.config/alias/`

### Header-Block Format

Alle Shell-Dateien (`.alias`, `.sh`, `.zsh*`) beginnen mit einem standardisierten Header-Block:

```zsh
# ============================================================
# dateiname.alias - Kurzbeschreibung (max. 50 Zeichen)
# ============================================================
# Zweck   : Ausführliche Beschreibung des Datei-Zwecks
# Pfad    : ~/.config/alias/dateiname.alias
# Docs    : https://github.com/tool/tool (offizielle Doku)
# ============================================================
# Hinweis : Optionale Zusatzinformationen (mehrzeilig erlaubt)
#           z.B. Abhängigkeiten, Config-Pfade, Besonderheiten
# ============================================================
```

**Metadaten-Felder** (8 Zeichen breit, linksbündig):

| Feld | Pflicht | Beschreibung |
| ------ | --------- | -------------- |
| `Zweck` | ✅ | Was macht diese Datei? |
| `Pfad` | ✅ | Wo liegt die Datei nach Stow? |
| `Docs` | ✅ | Link zur offiziellen Dokumentation |
| `Hinweis` | ⚪ | Optionale Zusatzinfos |
| `Aufruf` | ⚪ | Für Skripte: Wie wird es aufgerufen? |

### Funktions- und Alias-Kommentare

**Jede Funktion und jeder Alias** benötigt einen Beschreibungskommentar direkt darüber:

```zsh
# Kompakte Liste, Verzeichnisse zuerst
alias ls='eza --group-directories-first'

# Man/tldr Browser – Ctrl+S=Modus wechseln, Enter=je nach Modus öffnen
fman() {
    # ... Implementation
}
```

**Private Funktionen** (mit `_` Präfix) sind von dieser Regel ausgenommen.

#### Beschreibungskommentar-Format für fzf-Funktionen

Funktionen mit fzf-UI nutzen ein erweitertes Format:

```text
# Name(param?) – Key=Aktion, Key=Aktion
```

**Parameter-Notation:**

| Notation | Bedeutung | Beispiel |
| ---------- | ----------- | ---------- |
| `(param)` | Pflichtparameter | `# Suche(query)` |
| `(param?)` | Optionaler Parameter | `# Suche(query?)` |
| `(param=default)` | Optional mit Default | `# Wechseln(pfad=.)` |

**Keybinding-Format:**

- `Enter=Aktion` – Einzelne Taste
- `Ctrl+S=Aktion` – Modifier-Kombination
- Mehrere Keybindings durch `,` getrennt

**Beispiele:**

```zsh
# zoxide Browser – Enter=Wechseln, Ctrl+D=Löschen, Ctrl+Y=Kopieren
zf() { ... }  # in zoxide.alias (Tool-Zuordnung!)

# Verzeichnis wechseln(pfad=.) – Enter=Wechseln, Ctrl+Y=Pfad kopieren
cdf() { ... }

# Live-Grep(suche?) – Enter=Datei öffnen, Ctrl+Y=Pfad kopieren
rgf() { ... }
```

> **Wichtig:** Diese Kommentare sind die Single Source of Truth für tldr-Patches.
> Der Generator `.github/scripts/generators/tldr.sh` erzeugt automatisch:
>
> - `.patch.md` – wenn eine offizielle tldr-Seite existiert (erweitert diese)
> - `.page.md` – wenn keine offizielle tldr-Seite existiert (ersetzt diese)
>
> Der Generator prüft den tealdeer-Cache (`~/Library/Caches/tealdeer/tldr-pages/`)
> und wählt automatisch das richtige Format.

### Ausnahmen vom Header-Format

Einige Dateien folgen **nicht** dem Standard-Header-Format:

| Datei | Grund |
| ------- | ------- |
| `btop/btop.conf` | Wird von btop generiert – `btop --write-config` überschreibt Änderungen |
| `btop/themes/catppuccin_mocha.theme` | Third-Party Theme (Catppuccin) – bei Updates überschrieben |
| `bat/themes/Catppuccin Mocha.tmTheme` | Third-Party Theme (Catppuccin) – bei Updates überschrieben |
| `zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh` | Third-Party Theme (Catppuccin) – bei Updates überschrieben |
| `terminal/.config/tealdeer/pages/*.patch.md` | Erweitert offizielle tldr-Seiten – automatisch generiert |
| `terminal/.config/tealdeer/pages/*.page.md` | Ersetzt fehlende tldr-Seiten – automatisch generiert |

Diese Dateien werden vom Pre-Commit Hook nicht auf Header-Format geprüft.

---

## Code-Konventionen

### Shell-Scripts

```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Logging-Helper verwenden (siehe lib.sh)
log()  { echo -e "${C_BLUE}→${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}✔${C_RESET} $*"; }
err()  { echo -e "${C_RED}✖${C_RESET} $*" >&2; }
warn() { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }
```

### Alias-Dateien

- **Guard-Check** am Anfang: `if ! command -v tool >/dev/null 2>&1; then return 0; fi`
- **Kommentar** über jeder Alias-Gruppe
- **Konsistente Benennung**: `tool.alias`
- **Private Funktionen**: Mit `_` Präfix (z.B. `_helper_func()`)
  - Werden von Validatoren ignoriert
  - Müssen nicht dokumentiert werden
  - Für interne Helper, Parser, etc.

### Funktions-Syntax

**Verwende diese Form (von `fa()` erkannt):**

```zsh
name() {
    # ...
}
```

**Nicht verwenden:**

```zsh
function name {   # ❌ Korn-Shell-Style – nicht von fa() erkannt
}
function name() { # ❌ Hybrid-Style – redundant
}
```

| Syntax | Status | Grund |
| -------- | -------- | ------- |
| `name() {` | ✅ Verwenden | Von `fa()` erkannt, konsistent |
| `function name {` | ❌ Nicht verwenden | Nicht von `fa()` erkannt |
| `function name() {` | ❌ Nicht verwenden | Redundant, inkonsistent |

> **Hinweis:** Die `fa()`-Funktion (Alias-Browser) erkennt nur `name() {`-Syntax.
> Diese Einschränkung ist beabsichtigt – Konsistenz im gesamten Projekt.

### Stil-Regeln

Diese Regeln gelten für alle Shell-Dateien:

| Regel | Format | Beispiel |
| ------- | -------- | ---------- |
| **Metadaten-Felder** | 8 Zeichen + `:` | `# Docs    :`, `# Guard   :` |
| **Guard-Kommentar** | Mit Tool-Name | `# Guard   : Nur wenn X installiert ist` |
| **Sektions-Trenner** | `----` (60 Zeichen) | `# --------------------------------------------------------` |
| **Header-Block** | `====` nur oben | Erste Zeilen der Datei |
| **fzf-Header** | `Enter:` zuerst | `--header='Enter: Aktion'` |
| **Header Pipe-Zeichen** | ASCII | Kein Unicode in `--header` |

### Dokumentation

- **Zielgruppe beachten**: `docs/` = Endnutzer, `CONTRIBUTING.md` = Entwickler
- **Cross-References** nutzen: `[Link](datei.md#anker)`
- **Tabellen** für Übersichten
- **Code-Blöcke** mit Sprache: ` ```zsh `

---

## Pull Request Workflow

### 1. Branch erstellen

```zsh
git checkout -b feature/beschreibung
```

### 2. Änderungen vornehmen

- Code ändern
- Dokumentation aktualisieren (falls relevant)
- `./.github/scripts/generate-docs.sh --check` ausführen

### 3. Testen

```zsh
# Installation prüfen
./.github/scripts/health-check.sh

# Bei Shell-Änderungen: neue Session starten
exec zsh
```

### 4. Committen

```zsh
git add .
git commit -m "type: beschreibung"
```

**Commit-Typen:**

- `feat:` – Neue Funktion
- `fix:` – Bugfix
- `docs:` – Nur Dokumentation
- `refactor:` – Code-Umstrukturierung
- `chore:` – Maintenance (deps, configs)

### 5. Push & PR

```zsh
git push -u origin feature/beschreibung
gh pr create
```

### 6. Labels setzen

Nach PR-Erstellung das passende Label hinzufügen:

| Label | Verwendung |
| ------- | ------------ |
| `bug` | Fehler, etwas funktioniert nicht |
| `enhancement` | Neues Feature oder Verbesserung |
| `documentation` | Nur Doku-Änderungen |
| `refactoring` | Code-Verbesserung ohne Funktionsänderung |
| `chore` | Routineaufgaben, Wartung |
| `configuration` | Config-Änderungen |
| `theming` | Catppuccin, visuelle Anpassungen |
| `setup` | Installation, Bootstrap |

**Zusatz-Labels bei Bedarf:**

- `breaking-change` – Ändert bestehendes Verhalten
- `needs-review` – Bereit für Review
- `blocked` – Wartet auf externe Abhängigkeit

> 💡 **Tipp:** Bei Issues werden Labels automatisch durch Templates gesetzt.

---

## Häufige Aufgaben

### Neues Tool hinzufügen

1. **Brewfile** erweitern: `setup/Brewfile`
2. **Alias-Datei** erstellen: `terminal/.config/alias/tool.alias`
3. `./.github/scripts/generate-docs.sh --generate` ausführen (generiert tldr-Patch automatisch)
4. Änderungen prüfen und committen

### Dokumentation ändern

> ⚠️ **Wichtig:** Dokumentation wird aus Code generiert! Änderungen direkt in `docs/` werden überschrieben.

1. Änderung im **Quellcode** vornehmen (`.alias`, `Brewfile`, Configs, oder `generators/*.sh`)
2. `./.github/scripts/generate-docs.sh --generate` ausführen
3. Generierte Änderungen prüfen und committen

### Terminal-Profil ändern

1. Terminal.app → Einstellungen → Profil anpassen
2. Rechtsklick → "Exportieren…"
3. Als `setup/catppuccin-mocha.terminal` speichern (überschreiben)

> ⚠️ **Niemals** die `.terminal`-Datei direkt editieren – enthält binäre Daten.

### Tealdeer-Patches (Auto-Generiert)

Die tldr-Patches in `terminal/.config/tealdeer/pages/` werden **automatisch** aus den Beschreibungskommentaren in `.alias`-Dateien generiert (siehe [Beschreibungskommentar-Format](#beschreibungskommentar-format-für-fzf-funktionen)).

**Workflow:**

1. Kommentar über Alias/Funktion in `.alias`-Datei schreiben
2. `./.github/scripts/generate-docs.sh --generate` ausführen
3. Patch wird automatisch erstellt/aktualisiert

> ⚠️ **Niemals** Patch-Dateien manuell editieren – Änderungen werden überschrieben!

**Automatische Erkennung:**

Der Generator prüft, ob eine offizielle tldr-Seite im Cache existiert:

- Offizielle Seite vorhanden → `tool.patch.md` (erweitert die offizielle Seite)
- Keine offizielle Seite → `tool.page.md` (ersetzt die fehlende Seite)

> 💡 Cache aktualisieren: `tldr --update`
>
> 💡 **Tipp:** `dothelp` zeigt alle verfügbaren tldr-Seiten mit dotfiles-Erweiterungen.

---

## Hilfe

- **Docs stimmen nicht mit Code überein?** → `./.github/scripts/generate-docs.sh --check` zeigt Details
- **Hook blockiert Commit?** → `./.github/scripts/generate-docs.sh --generate` ausführen, dann committen
- **Installation kaputt?** → `./.github/scripts/health-check.sh` zur Diagnose
- **Copilot/KI-Assistenten?** → Siehe [.github/copilot-instructions.md](.github/copilot-instructions.md) für projektspezifische Regeln

---

[← Zurück zur Übersicht](README.md)
