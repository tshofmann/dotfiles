# Copilot Instructions für dotfiles

## Vor größeren Änderungen

**Lies zuerst `CONTRIBUTING.md`** bei:

- Neue `.alias`-Datei erstellen
- Neues Tool zum Brewfile hinzufügen
- Änderungen an `.zshrc` oder `.zshenv`
- fzf-Funktionen mit Preview/Bindings

---

## DOs ✓

| Regel | Beispiel |
| ------- | ---------- |
| **Erst prüfen, dann handeln** | `git status`, `ls`, `cat` vor Änderungen |
| **Terminal verifizieren** | Aussagen mit Output belegen |
| **ZSH-Features nutzen** | `[[ ]]`, `${var##pattern}`, Arrays |
| **Variablen quoten** | `"$var"` statt `$var` |
| **Deutsch schreiben** | Kommentare, Doku, Commits |
| **Pre-Commit durchlaufen** | Hooks validieren vor Commit |
| **Projekt-Config nutzen** | Linter/Checks nur mit `--config` oder via Hook |
| **Bei Unklarheit fragen** | Rückfrage statt Annahme |

## DON'Ts ✗

| Regel | Warum |
| ------- | ------- |
| **Niemals `--no-verify`** | Hooks existieren aus gutem Grund |
| **Niemals blind ändern** | Repository-Zustand ist die Wahrheit |
| **Niemals statische Zahlen** | "X Tools installiert" veraltet sofort |
| **Niemals Annahmen** | Erst recherchieren, dann handeln |
| **Niemals nackte Linter** | Immer Projekt-Config verwenden, nie `npx tool datei` ohne `--config` |
| **Niemals `/Users/<name>`** | Öffentlich sichtbar → `~` oder `$HOME` |
| **Keine Offensichtlichkeits-Kommentare** | Header-Block und Beschreibungskommentare sind Pflicht (Generator-Input) — aber `# Setze Variable` über einer Zuweisung ist Rauschen |
| **ZSH ist die Ziel-Shell** | POSIX sh nur in `setup/install.sh` und `setup/lib/logging.sh` (weil zsh auf frischen Linux-Systemen fehlen kann) |

---

## Architektur

> **Unix-Philosophie:** *"Do One Thing and Do It Well"*

| Aspekt | Wert |
| -------- | ------ |
| **Plattform** | macOS (primär), Linux vorbereitet (Fedora, Debian, Arch) |
| **Shell** | ZSH (POSIX sh nur für `setup/install.sh` + `setup/lib/logging.sh`) |
| **Theme** | Catppuccin Mocha |
| **Symlinks** | GNU Stow mit `--no-folding` |
| **Configs** | `~/.config/` (XDG-konform) |
| **Modularität** | Ein Tool = Eine `.alias`-Datei |
| **Bootstrap** | Modulare Schritte in `setup/modules/*.sh` |

**Einstiegspunkt:** `dothelp` zeigt alle verfügbaren tldr-Seiten mit dotfiles-Erweiterungen.

> **Bereichsspezifische Konventionen** sind in [`.github/instructions/`](instructions/) als `.instructions.md`-Dateien hinterlegt und werden automatisch geladen wenn passende Dateien bearbeitet werden.
>
> **Bei Aufgaben ohne offene Datei** (z.B. „prüfe die fzf-Aliase"): Zuerst die relevante Instructions-Datei aus der Verweise-Tabelle lesen, bevor du loslegst.

---

## GitHub PRs (KRITISCH)

**PRs niemals eigenständig mergen** – immer den User fragen!

**PRs niemals eigenständig erstellen** – immer den User fragen!

---

## Verweise

| Thema | Datei |
| ------- | ------- |
| Code-Konventionen | `CONTRIBUTING.md#code-konventionen` |
| Header-Format | `CONTRIBUTING.md#header-block-format` |
| Funktions-Syntax | `CONTRIBUTING.md#funktions-syntax` |
| Kommentar-Format | `CONTRIBUTING.md#beschreibungskommentar-format-für-fzf-funktionen` |
| **Labels** | `CONTRIBUTING.md#6-labels-setzen` |
| Alias-Konventionen | `.github/instructions/alias-conventions.instructions.md` |
| ZSH Shell-Konventionen | `.github/instructions/shell-zsh.instructions.md` |
| Theming | `.github/instructions/theming.instructions.md` |
| Setup-Module | `.github/instructions/setup-modules.instructions.md` |
| GitHub Workflow | `.github/instructions/github-workflow.instructions.md` |
| Generatoren | `.github/instructions/generators.instructions.md` |
| PR-Template | `.github/PULL_REQUEST_TEMPLATE.md` |
| Issue-Templates | `.github/ISSUE_TEMPLATE/` |
| Installierte Tools | `setup/Brewfile` |
| Hilfe/Schnellreferenz | `dothelp` (zeigt alle tldr-Seiten mit dotfiles-Erweiterungen) |
| Farb-Palette | [catppuccin.com/palette](https://catppuccin.com/palette) |
