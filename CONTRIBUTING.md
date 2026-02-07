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

# 4. Konfiguration verlinken (bei Entwicklung ohne bootstrap.sh)
stow --adopt -R terminal editor && git reset --hard HEAD
```

Nach Schritt 3 wird bei jedem Commit automatisch geprüft, ob Dokumentation und Code synchron sind.

> **Hinweis:** Bei erneuter Ausführung von `bootstrap.sh` werden uncommitted Changes
> automatisch gestasht und nach Abschluss wiederhergestellt. Du verlierst keine Arbeit.

---

## Repository-Struktur

**Wichtigste Pfade:**

| Pfad | Zweck |
| ------ | ------- |
| `.github/scripts/generators/` | Dokumentations-Generatoren (Single Source of Truth) |
| `.github/hooks/` | Pre-Commit Hook für Validierung |
| `setup/` | Bootstrap-Orchestrator, Module, Brewfile, Terminal-Profil |
| `setup/modules/` | Modulare Bootstrap-Schritte (Validation, Homebrew, etc.) |
| `terminal/` | Dotfiles (werden nach `~` verlinkt via Stow) |
| `terminal/.config/alias/` | Tool-spezifische Aliase und Funktionen |
| `docs/` | Dokumentation für Endnutzer |

> **💡 Tipp:** Für die vollständige Verzeichnisstruktur nutze den GitHub Tree-View oder `eza --tree ~/dotfiles`.

---

## Architektur-Konzepte

### Unix-Philosophie

> *"Do One Thing and Do It Well"*

- **Ein Tool = Eine Aufgabe** – Jede `.alias`-Datei gehört zu genau einem Tool
- **Kleine, kombinierbare Einheiten** – Funktionen sind unabhängig und pipebar
- **Text als universelles Interface** – Konfiguration in lesbaren Dateien

### Modularität

| Prinzip | Umsetzung |
| ------- | --------- |
| **Isolation** | Jedes Tool hat eigene Config in `~/.config/tool/` |
| **Unabhängigkeit** | Guard-System erlaubt Teilinstallation |
| **Erweiterbarkeit** | Neue Tools durch Hinzufügen einer `.alias`-Datei |
| **Austauschbarkeit** | Aliase abstrahieren Tool-spezifische Syntax |

### Plattform-Support

Das Bootstrap-System unterstützt plattformspezifische Module:

```zsh
# In setup/bootstrap.sh – MODULES Array
readonly -a MODULES=(
    validation              # Alle Plattformen
    homebrew                # Alle Plattformen (Linuxbrew auf Linux)
    macos:terminal-profile  # Nur macOS
    macos:xcode-theme       # Nur macOS
    linux:packages          # Nur Linux (z.B. distro-spezifische Pakete)
)
```

| Prefix | Plattform | Erkennung |
| ------ | --------- | --------- |
| (ohne) | Alle | Immer ausführen |
| `macos:` | macOS | `$OSTYPE == darwin*` |
| `linux:` | Linux (alle Distros) | `$OSTYPE == linux*` |
| `fedora:` | Fedora | `/etc/os-release ID=fedora` |
| `debian:` | Debian/Ubuntu/Derivate | `/etc/os-release ID=debian\|ubuntu` oder `ID_LIKE=*debian*` |
| `arch:` | Arch/Manjaro/Derivate | `/etc/os-release ID=arch\|manjaro` oder `ID_LIKE=*arch*` |

> **Status:** macOS ist primär. Plattform-Abstraktionen (`platform.zsh`) und Linux-Bootstrap (`install.sh`) sind implementiert, aber noch nicht auf Linux getestet. Beiträge und Test-Reports sind willkommen!

### Cross-Platform Abstraktionen

`terminal/.config/platform.zsh` stellt plattformübergreifende Shell-Funktionen bereit:

| Funktion | macOS | Linux (Wayland) | Headless |
| -------- | ----- | --------------- | -------- |
| `clip` | `pbcopy` | `wl-copy` | No-Op |
| `clippaste` | `pbpaste` | `wl-paste` | No-Op |
| `xopen` | `open` | `xdg-open` | No-Op |
| `sedi` | `sed -i ''` | `sed -i` | `sed -i` |

**Wichtig für Contributor:**

- **Immer** `clip`/`clippaste` statt `pbcopy`/`pbpaste` verwenden
- **Immer** `xopen` statt `open` verwenden
- **Immer** `sedi` statt `sed -i` verwenden
- `platform.zsh` wird früh in `.zshrc` geladen und steht in allen Alias-Dateien zur Verfügung
- Linux-Clipboard: Nur Wayland (kein X11) – bewusste Design-Entscheidung
- Headless-Systeme: Clipboard/Open-Funktionen sind stille No-Ops

### Guard-System

Alle `.alias`-Dateien prüfen ob das jeweilige Tool installiert ist:

```zsh
# Guard am Anfang jeder .alias-Datei
if ! command -v tool >/dev/null 2>&1; then
    return 0
fi
```

So bleiben Original-Befehle (`ls`, `cat`) erhalten wenn ein Tool fehlt.

### Pfad-Pattern

Zwei Umgebungsvariablen für unterschiedliche Pfade:

```zsh
# Für Dateien im Repository (setup/, .github/, etc.)
"${DOTFILES_DIR:-$HOME/dotfiles}/setup/Brewfile"

# Für User-Configs nach Stow (~/.config/)
"${XDG_CONFIG_HOME:-$HOME/.config}/fzf/config"
```

| Variable | Verwendung | Beispiel-Pfade |
| -------- | ---------- | -------------- |
| `$DOTFILES_DIR` | Repository-Dateien | `setup/`, `.github/scripts/`, `terminal/` |
| `$XDG_CONFIG_HOME` | Installierte Configs | `~/.config/fzf/`, `~/.config/bat/` |

> **Wichtig:** Immer mit Fallback `:-$HOME/...` verwenden für Robustheit.

### fzf Helper-Skripte

Wiederverwendbare Skripte für fzf-Previews und -Aktionen in `~/.config/fzf/`:

| Skript | Zweck | Verwendet von |
| ------ | ----- | ------------- |
| `preview file` | Datei-Vorschau mit bat (Fallback: cat) | `rg.alias`, `fd.alias` |
| `preview dir` | Verzeichnis-Vorschau mit eza (Fallback: ls) | `zoxide.alias`, `fd.alias` |
| `action` | Sichere Aktionen (copy, copy-env, edit, git-diff) – nutzt `clip` für Cross-Platform | Mehrere `.alias`-Dateien |
| `help` | Helper für `help()` (list, preview, toggle) | `fzf.alias` |
| `cmds` | Helper für `cmds()` (preview) | `fzf.alias` |
| `procs` | Helper für `procs()` (list) | `fzf.alias` |

**Warum Helper statt Inline-Code?**

- Shell-Injection-sicher (Argumente statt String-Interpolation)
- Wiederverwendbar über mehrere `.alias`-Dateien
- Testbar und wartbar

```zsh
# RICHTIG: Helper-Skript aufrufen
--preview "$helper/preview file {1}"

# FALSCH: Inline-Code (Shell-Injection-Risiko)
--preview 'bat {}'
```

---

## Git Hooks

### Aktivierung

```zsh
git config core.hooksPath .github/hooks
```

### Verfügbare Hooks

| Hook | Zweck |
| ------ | ------- |
| `pre-commit` | 1. ZSH-Syntax (`zsh -n`) für `.github/scripts/**/*.sh`, `terminal/.config/alias/*.alias`, `terminal/.config/zsh/*.zsh`, `terminal/.zsh*`, `terminal/.zprofile`, `terminal/.zlogin`, `setup/*.sh`, `setup/modules/*.sh` |
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

### Was wird generiert?

| Quelle | Generiert |
| ------ | --------- |
| `.alias`-Dateien | tldr-Patches/Pages, README.md (Tool-Ersetzungen) |
| `Brewfile` | docs/setup.md (Tool-Listen) |
| `bootstrap.sh` | README.md (macOS-Versionen), docs/setup.md (Bootstrap-Schritte) |
| `setup/modules/*.sh` | docs/setup.md (Bootstrap-Schritte via STEP-Metadaten) |
| `theme-style` | docs/customization.md (Farbpalette), terminal/.config/tealdeer/pages/catppuccin.page.md |
| Config-Dateien | docs/customization.md |

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
| **Header-Beschreibungen** | Deutsch | `# Zweck       : Aliase für bat` |
| **Dokumentation** | Deutsch | README, CONTRIBUTING, docs/ |
| **Commit-Messages** | Deutsch | `feat: fzf-Preview für git log` |
| **Issue-Beschreibungen** | Deutsch | GitHub Issues & PRs |

**Ausnahmen** (Englisch erlaubt):

- **Technische Begriffe** ohne gängige Übersetzung: `Guard`, `Symlink`, `Config`
- **Code-Bezeichner**: Funktionsnamen (`brew-up`), Variablen (`DOTFILES_DIR`)
- **Tool-Namen und Referenzen**: `fzf`, `bat`, `ripgrep`
- **URLs und Pfade**: `~/.config/alias/`

### Header-Block Format

Alle Shell-Dateien (`.alias`, `.sh`, `.zsh*`) beginnen mit einem standardisierten Header-Block:

```zsh
# ============================================================
# dateiname.alias - Kurzbeschreibung (max. 50 Zeichen)
# ============================================================
# Zweck       : Ausführliche Beschreibung des Datei-Zwecks
# Pfad        : ~/.config/alias/dateiname.alias
# Docs        : https://github.com/tool/tool (offizielle Doku)
# Nutzt       : fzf (Preview), bat (Syntax-Highlighting)
# Ersetzt     : cat (mit Syntax-Highlighting)
# Aliase      : cmd, cmd2, cmd3
# ============================================================
```

**Metadaten-Felder** (Format: `# <Feldname> :` – Feldname wird auf 12 Zeichen gepaddet, dann Leerzeichen + `:`):

| Feld | Pflicht | Beschreibung |
| ------ | --------- | -------------- |
| `Zweck` | ✅ | Was macht diese Datei? |
| `Pfad` | ✅ | Wo liegt die Datei nach Stow? |
| `Docs` | ✅ | Link zur offiziellen Dokumentation |
| `Generiert` | ⚪ | Welche Doku wird aus dieser Datei generiert? |
| `Nutzt` | ⚪ | Abhängigkeiten zu anderen Tools (fzf, bat, etc.) |
| `Ersetzt` | ⚪ | Welchen Befehl ersetzt das Tool? (cat, find, ls) |
| `Aliase` | ⚪ | Liste der definierten Aliase |
| `Aufruf` | ⚪ | Für Skripte: Wie wird es aufgerufen? |
| `Lizenz` | ⚪ | Lizenz für externe/upstream Dateien (z.B. MIT) |
| `Hinweis` | ⚪ | Nur für **einzigartige** kontextuelle Info (siehe SSOT) |
| `Config` | ⚪ | Nur wenn Config-Datei keine Header unterstützt |

### Config-Pfad Ermittlung (SSOT)

Die `.alias`-Datei ist der zentrale Dokumentations-Hub für jedes Tool.

```text
Hat das Tool eine .alias-Datei?
├─ JA → Config-Pfad gehört dort: `# Config : ~/.config/tool/config`
│       (Single Source of Truth für Tool-Dokumentation)
│
└─ NEIN → Config-Datei in ~/.config/<tool>/ suchen
          ├─ Datei mit `# Pfad :` Header?
          │  └─ JA → Config-Pfad gefunden + tldr-Patch generierbar ✓
          └─ NEIN → Kein Config-Pfad, keine tldr-Dokumentation
```

**Regel:** `# Config :` in Alias-Datei ist Pflicht, wenn das Tool eine lokale Config hat.
Der Fallback (`# Pfad :` in Config-Dateien) ist für Tools ohne `.alias`-Datei.

### tldr-Dokumentation für Tools ohne Aliase

Einige Tools (z.B. `kitty`) haben keine sinnvollen Shell-Aliase, aber eine umfangreiche Config.
Der tldr-Generator unterstützt **Config-basierte Patches**:

```text
tldr-Generator Quellen:
├─ .alias-Dateien (Primär)
│   └─ Aliase, Funktionen, Keybindings → .patch.md / .page.md
│
└─ Config-Verzeichnisse (Sekundär, ohne .alias)
    └─ ~/.config/<tool>/ mit Header-Block
        ├─ # Zweck, # Pfad, # Docs → tldr-Header
        ├─ # Reload, # Theme, etc. → dotfiles-spezifische Einträge
        └─ Wichtige Shortcuts aus Kommentaren
```

**Anforderungen für Config-basierte Patches:**

| Feld | Pflicht | Beispiel |
| ---- | ------- | -------- |
| `# Zweck` | ✅ | `# Zweck : GPU-Terminal mit Image-Support` |
| `# Pfad` | ✅ | `# Pfad : ~/.config/kitty/kitty.conf` |
| `# Docs` | ✅ | `# Docs : https://sw.kovidgoyal.net/kitty/` |
| `# Reload` | ⚪ | `# Reload : Ctrl+Shift+F5` |
| `# Theme` | ⚪ | `# Theme : current-theme.conf (via Stow)` |

Diese Header werden vom Generator automatisch in tldr-Patches umgewandelt.

### Funktions- und Alias-Kommentare

**Jede Funktion und jeder Alias** benötigt einen Beschreibungskommentar direkt darüber:

```zsh
# Kompakte Liste, Verzeichnisse zuerst
alias ls='eza --group-directories-first'

# Man/tldr Browser – Ctrl+S=Modus wechseln, Enter=je nach Modus öffnen
help() {
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

> **Warum optionale Parameter bei fzf-Browsern?**
>
> Alle fzf-Browser sollten `(suche?)` Parameter haben:
>
> 1. **tldr-Sichtbarkeit:** Im tldr wird `{{suche}}` in mauve gefärbt – sofort erkennbar als interaktiv
> 2. **Vorfilterung:** `brew-add docker` startet fzf mit Vorfilter statt alles zu zeigen
> 3. **Konsistenz:** Einheitliches UX-Pattern über alle Browser
>
> Implementierung: `local query="${1:-}"` und `fzf --query="$query"`

**Keybinding-Format:**

- `Enter=Aktion` – Einzelne Taste
- `Ctrl+S=Aktion` – Modifier-Kombination
- Mehrere Keybindings durch `,` getrennt

**Beispiele:**

```zsh
# zoxide Browser – Enter=Wechseln, Ctrl+D=Löschen, Ctrl+Y=Kopieren
zj() { ... }  # in zoxide.alias (Tool-Zuordnung!)

# Verzeichnis wechseln(pfad=.) – Enter=Wechseln, Ctrl+Y=Pfad kopieren
jump() { ... }

# Live-Grep(suche?) – Enter=Datei öffnen, Ctrl+Y=Pfad kopieren
rg-live() { ... }
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
| `zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh` | Third-Party Theme (Catppuccin) – lokal angepasst (comment → Overlay0), Header dokumentiert Abweichung |
| `terminal/.config/tealdeer/pages/*.patch.md` | Erweitert offizielle tldr-Seiten – automatisch generiert |
| `terminal/.config/tealdeer/pages/*.page.md` | Ersetzt fehlende tldr-Seiten – automatisch generiert |

Diese Dateien werden vom Pre-Commit Hook nicht auf Header-Format geprüft.

---

## Theming (Catppuccin Mocha)

### Grundregeln

1. **Alle Tools** nutzen Catppuccin Mocha als Theme
2. **Zentrale Referenz:** `terminal/.config/theme-style`
3. **Upstream bevorzugen:** Offizielle Themes von [github.com/catppuccin](https://github.com/catppuccin) verwenden

### Bei neuen Tool-Konfigurationen

1. **Prüfe** ob ein offizielles Catppuccin-Theme existiert
2. **Dokumentiere** den Status in der Theme-Quellen-Tabelle (`theme-style` Zeile 13-42)
3. **Nutze semantische Farben** konsistent:

| Verwendung | Farbe | Hex |
| ------ | ------- | ------- |
| Selection Background | Surface1 | `#45475A` |
| Active Border/Accent | Mauve | `#CBA6F7` |
| Multi-Select Marker | Lavender | `#B4BEFE` |
| Success/Valid | Green | `#A6E3A1` |
| Error/Invalid | Red | `#F38BA8` |
| Warning/Modified | Yellow | `#F9E2AF` |
| Directory | Mauve | `#CBA6F7` |
| Symlink/Info | Blue | `#89B4FA` |

### Status-Dokumentation

Die Theme-Quellen-Tabelle in `theme-style` dokumentiert den Zustand jeder Tool-Konfiguration:

```text
upstream        = Unverändert aus offiziellem Repo
upstream+X      = Mit Anpassung (X = was geändert)
upstream-X      = Mit Entfernung (X = was entfernt)
manual          = Manuell basierend auf catppuccin.com/palette
```

**Bei Änderungen:** Status aktualisieren und Abweichungen begründen.

---

## Code-Konventionen

### Shell-Scripts

```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Logging-Helper verwenden (siehe common.sh)
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

#### Namenskonvention für Aliase und Funktionen

**Schema:** `<tool>-<aktion>` – intuitiv, merkbar, Tab-Completion-freundlich.

| Kategorie | Schema | Beispiele |
| --------- | ------ | --------- |
| **Tool-Wrapper** | `<tool>-<aktion>` | `git-log`, `git-branch`, `gh-pr`, `brew-add` |
| **Browser/Interaktiv** | Beschreibend | `help`, `cmds`, `procs`, `vars` |
| **Navigation** | Kurze Verben | `go`, `edit`, `zj` |
| **Bewusste Ersetzungen** | Original-Name | `cat`, `ls`, `top` (→ bat, eza, btop) |

**Regeln:**

1. **Keine Kollisionen** mit System-Befehlen (außer bewusste Ersetzungen)
2. **Bindestriche** (`-`) statt Unterstriche für Lesbarkeit
3. **Tool-Präfix** ermöglicht Tab-Completion: `git-<TAB>` zeigt alle git-Funktionen
4. **Kurze Namen** nur für sehr häufig genutzte Befehle (`y`, `z`, `ls`)

**Tab-Completion Beispiel:**

```zsh
$ git-<TAB>
git-add     git-branch  git-cm      git-diff    git-log
git-pull    git-push    git-stage   git-stash   git-status

$ brew-<TAB>
brew-add    brew-list   brew-rm     brew-up
```

**Kollisionsprüfung vor neuen Namen:**

```zsh
# Prüfe ob Name frei ist
command -v mein-alias && echo "KOLLISION!" || echo "Frei"
```

#### Sektionen für automatische Dokumentation

Bestimmte Sektionen in `.alias`-Dateien werden automatisch in `tldr dotfiles` dokumentiert:

| Datei | Sektion | Erscheint in |
| ------- | ------- | ------- |
| `brew.alias` | `# Update & Wartung` | Homebrew |
| `brew.alias` | `# Versionsübersicht` | Homebrew |
| `dotfiles.alias` | `# Dotfiles Wartung` | Dotfiles-Wartung |

> **Wichtig:** Neue Aliase und Funktionen müssen **innerhalb** der entsprechenden Sektion stehen,
> nicht am Dateiende. Der Generator `extract_section_items()` extrahiert nur Items zwischen
> Sektionsheader und nächster Sektion.

### Funktions-Syntax

**Verwende diese Form (von `cmds()` erkannt):**

```zsh
name() {
    # ...
}
```

**Nicht verwenden:**

```zsh
function name {   # ❌ Korn-Shell-Style – nicht von cmds() erkannt
}
function name() { # ❌ Hybrid-Style – redundant
}
```

| Syntax | Status | Grund |
| -------- | -------- | ------- |
| `name() {` | ✅ Verwenden | Von `cmds()` erkannt, konsistent |
| `function name {` | ❌ Nicht verwenden | Nicht von `cmds()` erkannt |
| `function name() {` | ❌ Nicht verwenden | Redundant, inkonsistent |

> **Hinweis:** Die `cmds()`-Funktion (Alias-Browser) erkennt nur `name() {`-Syntax.
> Diese Einschränkung ist beabsichtigt – Konsistenz im gesamten Projekt.

### Stil-Regeln

Diese Regeln gelten für alle Shell-Dateien:

| Regel | Format | Beispiel |
| ------- | -------- | ---------- |
| **Metadaten-Felder** | Feldname auf 12 Zeichen padden + Leerzeichen + `:` | `# Zweck       :`, `# Alternativen :` |
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
3. **Falls Tool Shell-Init braucht:** `terminal/.zshrc` erweitern (siehe unten)
4. `./.github/scripts/generate-docs.sh --generate` ausführen (generiert tldr-Patch automatisch)
5. Änderungen prüfen und committen

#### Tool-Initialisierung in .zshrc

Manche Tools benötigen Shell-Integration (Completions, Prompts, etc.):

```zsh
# Pattern: Guard + Init
if command -v newtool >/dev/null 2>&1; then
    eval "$(newtool init zsh)"  # oder: source <(newtool completion zsh)
fi
```

**Wann ist .zshrc-Init nötig?**

| Tool-Typ | Beispiele | .zshrc nötig? |
| -------- | --------- | ------------- |
| Shell-Integration | zoxide, starship, fzf | ✅ Ja |
| Completions | gh, docker | ✅ Ja |
| Nur Aliase | bat, eza, fd | ❌ Nein |

> **Reihenfolge beachten:** In `.zshrc` werden Tools nach den Alias-Dateien initialisiert.

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
