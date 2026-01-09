# Copilot Instructions für dotfiles

## DOs ✓

| Regel | Beispiel |
|-------|----------|
| **Erst prüfen, dann handeln** | `git status`, `ls`, `cat` vor Änderungen |
| **Terminal verifizieren** | Aussagen mit Output belegen |
| **ZSH-Features nutzen** | `[[ ]]`, `${var##pattern}`, Arrays |
| **Variablen quoten** | `"$var"` statt `$var` |
| **Deutsch schreiben** | Kommentare, Doku, Commits |
| **Pre-Commit durchlaufen** | Hooks validieren vor Commit |
| **Bei Unklarheit fragen** | Rückfrage statt Annahme |

## DON'Ts ✗

| Regel | Warum |
|-------|-------|
| **Niemals `--no-verify`** | Hooks existieren aus gutem Grund |
| **Niemals blind ändern** | Repository-Zustand ist die Wahrheit |
| **Niemals statische Zahlen** | "X Tools installiert" veraltet sofort |
| **Niemals Annahmen** | Erst recherchieren, dann handeln |
| **Niemals `/Users/<name>`** | Öffentlich sichtbar → `~` oder `$HOME` |
| **Niemals POSIX-Shell** | Dieses Projekt ist rein ZSH |

---

## ZSH-Fallen

```zsh
# Arithmetik mit set -e – FALSCH:
((count++))
# RICHTIG:
(( count++ )) || true

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
|--------|------|
| **Plattform** | macOS Apple Silicon (arm64) |
| **Shell** | ZSH (kein POSIX) |
| **Theme** | Catppuccin Mocha |
| **Symlinks** | GNU Stow mit `--no-folding` |
| **Configs** | `~/.config/` (XDG-konform) |
| **Modularität** | Ein Tool = Eine `.alias`-Datei |

### Dokumentation

Doku wird automatisch aus Code generiert (Single Source of Truth):
- `.alias`-Dateien → `docs/tools.md`, tldr-Patches
- `Brewfile` → Tool-Listen
- Verzeichnisse → `docs/architecture.md`

**Niemals Docs manuell editieren** – Änderungen im Code machen.

**Einstiegspunkt:** `dothelp` zeigt alle verfügbaren tldr-Seiten mit dotfiles-Erweiterungen.

### Farben

Zentrale Definition: `terminal/.config/shell-colors`

In Skripten nutzen:
```zsh
source "$DOTFILES_DIR/terminal/.config/shell-colors"
# Dann: $C_GREEN, $C_RED, $C_BLUE, etc.
```

---

## Alias-Dateien

Format für `terminal/.config/alias/*.alias`:

**Regel:** Ein Alias/Funktion gehört in die `.alias`-Datei des Tools, das er **primär** repräsentiert.
- `zf()` → `zoxide.alias` (zoxide-Workflow, fzf nur UI)
- `fkill()` → `fzf.alias` (generische fzf-Funktion)

```zsh
# ============================================================
# tool.alias - Beschreibung
# ============================================================
# Zweck   : Was macht diese Datei
# Pfad    : ~/.config/alias/tool.alias
# Docs    : https://...
# ============================================================

# Guard
if ! command -v tool >/dev/null 2>&1; then return 0; fi

# Beschreibung für fa/tldr
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
|-------|------------|
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
|-------|-------|
| Code-Konventionen | `CONTRIBUTING.md#code-konventionen` |
| Funktions-Syntax | `CONTRIBUTING.md#funktions-syntax` |
| Kommentar-Format | `CONTRIBUTING.md#beschreibungskommentar-format-für-fzf-funktionen` |
| **Labels** | `CONTRIBUTING.md#6-labels-setzen` |
| Verzeichnisstruktur | `docs/architecture.md#verzeichnisstruktur` |
| PR-Template | `.github/PULL_REQUEST_TEMPLATE.md` |
| Issue-Templates | `.github/ISSUE_TEMPLATE/` |
| Installierte Tools | `setup/Brewfile` |
| Farb-Palette | [catppuccin.com/palette](https://catppuccin.com/palette) |
