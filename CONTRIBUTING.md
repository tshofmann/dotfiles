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
git config core.hooksPath .githooks

# 4. Konfiguration verlinken
stow --adopt -R terminal && git reset --hard HEAD
```

Nach Schritt 3 wird bei jedem Commit automatisch geprüft, ob Dokumentation und Code synchron sind.

---

## Repository-Struktur

Siehe [architecture.md → Verzeichnisstruktur](docs/architecture.md#verzeichnisstruktur) für die vollständige Struktur.

**Kurzübersicht der wichtigsten Pfade:**

| Pfad | Zweck |
|------|-------|
| `scripts/generators/` | Dokumentations-Generatoren (Single Source of Truth) |
| `scripts/tests/` | Unit-Tests für Generatoren |
| `setup/` | Bootstrap, Brewfile, Terminal-Profil |
| `terminal/` | Dotfiles (werden nach `~` verlinkt) |
| `docs/` | Dokumentation für Endnutzer |

---

## Git Hooks

### Aktivierung

```zsh
git config core.hooksPath .githooks
```

### Verfügbare Hooks

| Hook | Zweck |
|------|-------|
| `pre-commit` | 1. ZSH-Syntax (`zsh -n`) für `.sh`, `.alias`, `.zshrc`, `.zshenv`, `.zprofile`, `.zlogin` |
|              | 2. Doku-Konsistenz bei `docs/`, `Brewfile`, `terminal/.config/`, `CONTRIBUTING.md`, `terminal/.zsh*` |

### Hook überspringen (Notfall)

```zsh
git commit --no-verify -m "..."
```

> ⚠️ Nur nutzen wenn du weißt was du tust – Docs sollten immer synchron sein.

---

## Dokumentations-Validierung

Die Dokumentation wird automatisch aus dem Code generiert (Single Source of Truth).

### Manuell ausführen

```zsh
# Prüfen ob Dokumentation aktuell ist
./scripts/generate-docs.sh --check

# Dokumentation neu generieren
./scripts/generate-docs.sh --generate
```

### Unit-Tests für Generatoren

```zsh
# Tests ausführen
./scripts/tests/test_generators.sh
```

Die Test-Suite prüft:
- Pfad-Konfiguration (DOTFILES_DIR, etc.)
- Extraktions-Funktionen (Aliase, Funktionen, Docs)
- Logging und Zähler (ok, warn, err)

### Was wird generiert?

| Datei | Quelle |
|-------|--------|
| `README.md` | Template in `generators/readme.sh` |
| `docs/tools.md` | `.alias`-Dateien + `Brewfile` |
| `docs/installation.md` | `bootstrap.sh` |
| `docs/architecture.md` | Verzeichnisstruktur + Configs |
| `docs/configuration.md` | Config-Dateien |
| `tealdeer/pages/*.patch.md` | Alias-Kommentare |

### Bei Fehlern

1. Öffne die gemeldete Dokumentationsdatei
2. Aktualisiere den veralteten Abschnitt **im Code** (nicht in der Doku!)
3. Führe `./scripts/generate-docs.sh --generate` aus
4. Committe die Änderung

---

## Sprach- und Kommentar-Richtlinie

### Sprache: Deutsch als erste Wahl

**Deutsch** ist die bevorzugte Sprache für alle Inhalte in diesem Repository:

| Bereich | Sprache | Beispiel |
|---------|---------|----------|
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
|------|---------|--------------|
| `Zweck` | ✅ | Was macht diese Datei? |
| `Pfad` | ✅ | Wo liegt die Datei nach Stow? |
| `Docs` | ✅ | Link zur offiziellen Dokumentation |
| `Hinweis` | ⚪ | Optionale Zusatzinfos |
| `Aufruf` | ⚪ | Für Skripte: Wie wird es aufgerufen? |

### Funktions- und Alias-Kommentare

**Jede Funktion und jeder Alias** benötigt einen Beschreibungskommentar direkt darüber:

```zsh
# Verzeichnisse zuerst anzeigen mit Icons
alias ls='eza --group-directories-first'

# Man/tldr Browser – Ctrl+S=Modus wechseln, Enter=je nach Modus öffnen
fman() {
    # ... Implementation
}
```

**Private Funktionen** (mit `_` Präfix) sind von dieser Regel ausgenommen.

#### Beschreibungskommentar-Format für fzf-Funktionen

Funktionen mit fzf-UI nutzen ein erweitertes Format:

```
# Name(param?) – Key=Aktion, Key=Aktion
```

**Parameter-Notation:**
| Notation | Bedeutung | Beispiel |
|----------|-----------|----------|
| `(param)` | Pflichtparameter | `# Suche(query)` |
| `(param?)` | Optionaler Parameter | `# Suche(query?)` |
| `(param=default)` | Optional mit Default | `# Wechseln(pfad=.)` |

**Keybinding-Format:**
- `Enter=Aktion` – Einzelne Taste
- `Ctrl+S=Aktion` – Modifier-Kombination
- Mehrere Keybindings durch `, ` getrennt

**Beispiele:**
```zsh
# zoxide Browser – Enter=Wechseln, Ctrl+D=Löschen, Ctrl+Y=Kopieren
zf() { ... }

# Verzeichnis wechseln(pfad=.) – Enter=Wechseln, Ctrl+Y=Pfad kopieren
cdf() { ... }

# Live-Grep(suche?) – Enter=Datei öffnen, Ctrl+Y=Pfad kopieren
rgf() { ... }
```

> **Wichtig:** Diese Kommentare sind die Single Source of Truth für tldr-Patches.
> Der Generator `scripts/generators/tldr.sh` erzeugt die `.patch.md` Dateien
> automatisch aus diesen Kommentaren.

### tldr-Patches generieren

Die `.patch.md` Dateien in `terminal/.config/tealdeer/pages/` werden **automatisch generiert**:

```bash
# Prüfen ob Patches aktuell sind (Teil von generate-docs.sh)
./scripts/generate-docs.sh --check

# Alle Docs inkl. Patches neu generieren
./scripts/generate-docs.sh --generate
```

Der Pre-Commit Hook prüft automatisch ob die Patches aktuell sind.

### Ausnahmen vom Header-Format

Einige Dateien folgen **nicht** dem Standard-Header-Format:

| Datei | Grund |
|-------|-------|
| `btop/btop.conf` | Wird von btop generiert – `btop --write-config` überschreibt Änderungen |
| `btop/themes/*.theme` | Third-Party Theme (Catppuccin) – bei Updates überschrieben |
| `bat/themes/*.tmTheme` | Third-Party Theme (Catppuccin) – bei Updates überschrieben |
| `zsh/catppuccin_*.zsh` | Third-Party Theme (Catppuccin) – bei Updates überschrieben |
| `tealdeer/pages/*.patch.md` | Markdown-Format für tldr-Patches – eigenes Schema |

Diese Dateien werden vom Pre-Commit Hook nicht auf Header-Format geprüft.

---

## Code-Konventionen

### Shell-Scripts

```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Logging-Helper verwenden
log()  { print "→ $*"; }
ok()   { print "✔ $*"; }
err()  { print "✖ $*" >&2; }
warn() { print "⚠ $*"; }
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

**Verwende die POSIX-kompatible Form:**

```zsh
name() {
    # ...
}
```

**Nicht verwenden:**

```zsh
function name {   # ❌ ksh-Style – nicht POSIX
function name() { # ❌ Hybrid-Style
```

| Syntax | Status | Grund |
|--------|--------|-------|
| `name() {` | ✅ Verwenden | POSIX-konform, von `fa()` erkannt |
| `function name {` | ❌ Nicht verwenden | Nicht POSIX, von `fa()` nicht erkannt |
| `function name() {` | ❌ Nicht verwenden | Redundant, Inkonsistenz |

> **Hinweis:** Die `fa()`-Funktion (Alias-Browser) erkennt nur die POSIX-Syntax.
> Diese Einschränkung ist beabsichtigt – siehe [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html#function-names):
> *"The keyword `function` is optional, but must be used consistently throughout a project."*

### Stil-Regeln (automatisch geprüft)

Diese Regeln werden durch `style-consistency.sh` automatisch validiert:

| Regel | Format | Beispiel |
|-------|--------|----------|
| **Metadaten-Felder** | 8 Zeichen + `:` | `# Docs    :`, `# Guard   :` |
| **Guard-Kommentar** | Kurze Version | `# Guard   : Nur wenn X installiert ist` |
| **Sektions-Trenner** | `----` (60 Zeichen) | `# ------------------------------------------------------------` |
| **Header-Block** | `====` nur oben | Erste Zeilen der Datei |
| **fzf-Header** | `Enter:` zuerst | `--header='Enter: Aktion \| Key: Aktion'` |
| **Pipe-Zeichen** | ASCII `\|` | Kein Unicode `│` |

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
- `./scripts/generate-docs.sh --check` ausführen

### 3. Testen

```zsh
# Installation prüfen
./scripts/health-check.sh

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

---

## Häufige Aufgaben

### Neues Tool hinzufügen

1. **Brewfile** erweitern: `setup/Brewfile`
2. **Alias-Datei** erstellen: `terminal/.config/alias/tool.alias`
3. Dokumentation wird automatisch generiert (tldr-Patch, tools.md, etc.)
4. `./scripts/generate-docs.sh --generate` ausführen
5. Änderungen prüfen und committen

### Dokumentation ändern

> ⚠️ **Wichtig:** Dokumentation wird aus Code generiert! Änderungen direkt in `docs/` werden überschrieben.

1. Änderung im **Quellcode** vornehmen (`.alias`, `Brewfile`, Configs, oder `generators/*.sh`)
2. `./scripts/generate-docs.sh --generate` ausführen
3. Generierte Änderungen prüfen und committen

### Terminal-Profil ändern

1. Terminal.app → Einstellungen → Profil anpassen
2. Rechtsklick → "Exportieren…"
3. Als `setup/catppuccin-mocha.terminal` speichern (überschreiben)

> ⚠️ **Niemals** die `.terminal`-Datei direkt editieren – enthält binäre Daten.

### Tealdeer-Patch erstellen

Patches erweitern die offizielle `tldr` Dokumentation mit dotfiles-spezifischen Aliasen und Funktionen.

**1. Neue Patch-Datei anlegen:**

```zsh
# Dateiname = Tool-Name (nicht Alias-Name!)
touch ~/.config/tealdeer/pages/tool.patch.md
```

**2. Format:**

```markdown
# dotfiles: Beschreibung der Kategorie

- dotfiles: Was macht dieser Befehl:

`befehlsname`

- dotfiles: Mit Argument:

`befehlsname {{argument}}`

- dotfiles: Interaktiv mit fzf (`<Tab>` Mehrfach, `<Ctrl />` Vorschau):

`funktionsname`
```

**3. Namenskonvention:**

Alias-Dateiname = Patch-Dateiname = tldr-Befehlsname (z.B. `brew.alias` → `brew.patch.md` → `tldr brew`)

**4. Tastenkürzel-Syntax:**

| Taste | Syntax |
|-------|--------|
| Modifier + Taste | `<Ctrl c>`, `<Alt x>` |
| Einzelne Taste | `<Tab>`, `<Enter>`, `<Esc>` |

> **Wichtig**: Leerzeichen zwischen Modifier und Taste: `<Ctrl c>` (nicht `<Ctrl-c>`)

**5. Validieren:**

```zsh
./scripts/generate-docs.sh --check
```

**6. Was wird validiert?**

| Kategorie | Automatisch geprüft | Hinweis |
|-----------|---------------------|---------|
| Aliase | ✅ Ja | `alias name=...` aus `.alias` |
| Funktionen | ✅ Ja | `name() {` aus `.alias` |
| Tastenkürzel | ❌ Nein | Manuell pflegen in `fzf.patch.md` |

> ⚠️ **Tastenkürzel-Einschränkung**: Globale fzf-Keybindings (`--bind` Optionen) werden nicht automatisch validiert. Die Dokumentation in `fzf.patch.md` muss manuell synchron gehalten werden. Das Parsen verschachtelter Shell-Strings in `--bind` ist fehleranfällig und der Aufwand übersteigt den Nutzen.

---

## Hilfe

- **Docs stimmen nicht mit Code überein?** → `./scripts/generate-docs.sh --check` zeigt Details
- **Hook blockiert Commit?** → `./scripts/generate-docs.sh --generate` ausführen, dann committen
- **Installation kaputt?** → `./scripts/health-check.sh` zur Diagnose

---

[← Zurück zur Übersicht](README.md)
