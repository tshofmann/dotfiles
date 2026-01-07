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

```zsh
# ============================================================
# tool.alias - Beschreibung
# ============================================================
# Zweck   : Was macht diese Datei
# Docs    : https://...
# ============================================================

# Guard
if ! command -v tool >/dev/null 2>&1; then return 0; fi

# Beschreibung für fa/tldr
alias x='command'
```

---

## Verweise

| Thema | Datei |
|-------|-------|
| Header-Format | `CONTRIBUTING.md` |
| Verzeichnisstruktur | `docs/architecture.md` |
| Installierte Tools | `setup/Brewfile` |
| Farb-Palette | [catppuccin.com/palette](https://catppuccin.com/palette) |
