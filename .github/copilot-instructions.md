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
| **ZSH ist die Ziel-Shell** | POSIX sh nur in `setup/install.sh` und `setup/lib/logging.sh` (weil zsh auf frischen Linux-Systemen fehlen kann) |

---

## ZSH-Fallen

```zsh
# Arithmetik mit set -e – FALSCH:
((count++))
# RICHTIG:
(( count++ )) || true

# WARUM? Post-Inkrement gibt den ALTEN Wert zurück:
# count=0 → (( count++ )) evaluiert zu 0 → Exit-Code 1 → set -e bricht ab!
# Der Trick: || true fängt Exit-Code 1 ab, count wird trotzdem erhöht.

# Bei Vergleichen ist || true NICHT nötig:
(( count >= max )) && break  # OK – Vergleich gibt true/false

# fzf Preview mit ZSH-Syntax – explizit wrappen:
--preview='zsh -c '\''[[ -f "$1" ]] && cat "$1"'\'' -- {}'

# Regex für Befehle – Bindestriche erlauben:
[a-z][a-z0-9_-]*   # RICHTIG (findet bat-theme)
[a-z][a-z0-9_]*    # FALSCH
```

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

### Dokumentation

Doku wird automatisch aus Code generiert (Single Source of Truth):

- `.alias`-Dateien → tldr-Patches/Pages (`.patch.md` oder `.page.md`), README.md (Tool-Ersetzungen)
- `Brewfile` → `docs/setup.md` (Tool-Listen)
- `bootstrap.sh` → README.md (macOS-Versionen), `docs/setup.md` (Bootstrap-Schritte)
- `theme-style` → `docs/customization.md` (Farbpalette), `terminal/.config/tealdeer/pages/catppuccin.page.md`

**tldr-Format:** Der Generator prüft automatisch ob eine offizielle tldr-Seite existiert:

- Offizielle Seite vorhanden → `.patch.md` (erweitert diese)
- Keine offizielle Seite → `.page.md` (ersetzt diese)

**Niemals Docs manuell editieren** – Änderungen im Code machen.

**Einstiegspunkt:** `dothelp` zeigt alle verfügbaren tldr-Seiten mit dotfiles-Erweiterungen.

### Farben & Theming

**Zentrale Definition:** `terminal/.config/theme-style`

**Bei neuen Tool-Konfigurationen:**

1. **Prüfe Theme-Quellen-Tabelle** in `theme-style` (Zeile 15-42)
2. **Nutze semantische Farben** aus der Dokumentation in `theme-style`:
   - Selection Background → Surface1 `#45475A`
   - Accent/Border → Mauve `#CBA6F7`
   - Marker → Lavender `#B4BEFE`
   - Success → Green, Error → Red, Warning → Yellow
3. **Aktualisiere Status** in Theme-Quellen-Tabelle wenn Tool hinzugefügt wird
4. **Bevorzuge Upstream-Themes** von [github.com/catppuccin](https://github.com/catppuccin)

In Skripten nutzen:

```zsh
source "$DOTFILES_DIR/terminal/.config/theme-style"
# Dann: $C_GREEN, $C_RED, $C_BLUE, etc.
```

---

## Alias-Dateien

Format für `terminal/.config/alias/*.alias`:

**Regel:** Ein Alias/Funktion gehört in die `.alias`-Datei des Tools, das er **primär** repräsentiert.

- `zj()` → `zoxide.alias` (zoxide-Workflow, fzf nur UI)
- `procs()` → `fzf.alias` (generische fzf-Funktion)

```zsh
# ============================================================
# tool.alias - Beschreibung
# ============================================================
# Zweck       : Was macht diese Datei
# Pfad        : ~/.config/alias/tool.alias
# Docs        : https://...
# Config      : ~/.config/tool/config (wenn lokale Config existiert)
# Nutzt       : fzf, bat (optionale Abhängigkeiten)
# Ersetzt     : original-cmd (was es ersetzt)
# Aliase      : cmd1, cmd2
# ============================================================

# Guard
if ! command -v tool >/dev/null 2>&1; then return 0; fi

# Beschreibung für cmds/tldr
alias x='command'

# Funktion(param?) – Enter=Aktion, Ctrl+Y=Kopieren
func() {
    # Implementation
}
```

**Wichtig:** Funktionen als `name() {` schreiben – nicht `function name`!

---

## GitHub PRs

### Merge-Workflow (KRITISCH)

**PRs niemals eigenständig mergen** – immer den User fragen!

**PRs niemals eigenständig erstellen** – immer den User fragen!

**VOR jedem Merge diese Schritte ausführen:**

```zsh
# 1. CI-Status prüfen
gh pr checks <nr>

# 2. Auf Copilot-Review WARTEN (erscheint nach ~30-60 Sek)
gh pr view <nr> --json reviews | jq '.reviews[] | select(.author.login | contains("copilot"))'

# 3. Review-Kommentare LESEN und BEHEBEN
gh api repos/{owner}/{repo}/pulls/<nr>/reviews
# oder: mcp_io_github_git_pull_request_read mit method=get_review_comments

# 4. Erst wenn alle Kommentare adressiert sind: Mergen
```

**Niemals blind mergen** nur weil CI grün ist – Copilot-Reviews enthalten wertvolles Feedback!

### Review-Thread-Handling

| Regel | Begründung |
| ------- | ------------ |
| **Review-Threads einzeln beantworten** | Erklärung im Thread dokumentiert, nicht nur global |
| **Dann erst resolven** | Thread-Historie bleibt nachvollziehbar |
| **Alle Kommentare prüfen** | `get_review_comments` nicht nur `get_reviews` |
| **Outdated ≠ Resolved** | Auch veraltete Threads explizit auflösen |

```zsh
# Review-Threads auflösen via gh CLI:
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "PRRT_..."}) { thread { isResolved } } }'
```

### Issues und PRs erstellen

**Bei Issue-Erstellung:** Templates aus `.github/ISSUE_TEMPLATE/` verwenden:

- `bug_report.md` – für Bugs (inkl. Health-Check Ausgabe)
- `feature_request.md` – für Feature Requests

**Bei PR-Erstellung:** Template aus `.github/PULL_REQUEST_TEMPLATE.md` verwenden:

- Checkliste durchgehen (generate-docs, health-check)
- Art der Änderung markieren
- Zusammenhängende Issues verlinken
- **Label setzen** (siehe CONTRIBUTING.md)

> 💡 Issue-Labels werden automatisch durch Templates gesetzt. PR-Labels manuell hinzufügen.

---

## Verweise

| Thema | Datei |
| ------- | ------- |
| Code-Konventionen | `CONTRIBUTING.md#code-konventionen` |
| Header-Format | `CONTRIBUTING.md#header-block-format` |
| Funktions-Syntax | `CONTRIBUTING.md#funktions-syntax` |
| Kommentar-Format | `CONTRIBUTING.md#beschreibungskommentar-format-für-fzf-funktionen` |
| **Labels** | `CONTRIBUTING.md#6-labels-setzen` |
| Verzeichnisstruktur | GitHub Tree-View oder `eza --tree` |
| PR-Template | `.github/PULL_REQUEST_TEMPLATE.md` |
| Issue-Templates | `.github/ISSUE_TEMPLATE/` |
| Installierte Tools | `setup/Brewfile` |
| Hilfe/Schnellreferenz | `dothelp` (zeigt alle tldr-Seiten mit dotfiles-Erweiterungen) |
| Farb-Palette | [catppuccin.com/palette](https://catppuccin.com/palette) |
