---
name: add-tool
description: 'Schritt-für-Schritt Workflow um ein neues CLI-Tool zum dotfiles-Repository hinzuzufügen: Brewfile, Linux-Mapping, Alias-Datei, Shell-Init und Doku-Generierung.'
argument-hint: '<toolname>'
---

# Neues Tool hinzufügen

Folge diesen Schritten **in Reihenfolge** um ein neues Tool korrekt ins Repository zu integrieren.

## Schritt 1: Brewfile erweitern

Füge das Tool in `setup/Brewfile` ein — in der passenden Sektion (Formulae, Casks, MAS):

```ruby
brew "toolname"   # Beschreibung | https://docs-url
```

**Format:** Kommentar mit `# Beschreibung | URL` (wird vom Generator gelesen).

## Schritt 2: Linux-Mapping (BREW_TO_ALT)

Auf **Arch, Fedora und Debian x86_64** reicht das Brewfile — Homebrew/Linuxbrew übernimmt die Installation direkt.

Das `BREW_TO_ALT`-Mapping in `setup/modules/apt-packages.sh` ist ein **Fallback für Debian ARM** (armv6/armv7), wo Homebrew nicht verfügbar ist. Erweitere es trotzdem bei jeder neuen Formula:

```zsh
[toolname]="apt:toolname"        # Standard: Debian/Ubuntu-Paket
[othertool]="cargo:othertool"    # Falls Installation via cargo erfolgt
[nodetool]="npm:nodetool"        # Falls Installation via npm erfolgt
[macos-only-tool]="skip"         # Wenn es unter Linux bewusst übersprungen wird
```

## Schritt 3: Alias-Datei erstellen

Erstelle `terminal/.config/alias/<tool>.alias` nach diesem Template:

```zsh
# ============================================================
# tool.alias - Kurzbeschreibung (max. 50 Zeichen)
# ============================================================
# Zweck       : Ausführliche Beschreibung
# Pfad        : ~/.config/alias/tool.alias
# Docs        : https://...
# Config      : ~/.config/tool/config (wenn lokale Config existiert)
# Nutzt       : - (oder: fzf, bat, etc.)
# Ersetzt     : - (oder: original-cmd)
# Aliase      : cmd1, cmd2
# ============================================================

# Guard   : Nur wenn tool installiert ist
if ! command -v tool >/dev/null 2>&1; then
    return 0
fi

# ------------------------------------------------------------
# Beschreibung der Sektion
# ------------------------------------------------------------
# Beschreibung für cmds/tldr
alias cmd='tool --flag'
```

**Regeln:**

- Header-Felder auf 12 Zeichen padden
- Guard immer als erstes nach dem Header
- Funktionen als `name() {` — **nicht** `function name`
- Jeder Alias/Funktion braucht einen Beschreibungskommentar

## Schritt 4: Shell-Init prüfen

Braucht das Tool Shell-Integration (Completions, Prompts, etc.)? Falls ja, füge es in `terminal/.zshrc` ein:

```zsh
if command -v newtool >/dev/null 2>&1; then
    eval "$(newtool init zsh)"
fi
```

| Tool-Typ | Beispiele | .zshrc nötig? |
| -------- | --------- | ------------- |
| Shell-Integration | zoxide, starship, fzf | Ja |
| Completions | gh, docker | Ja |
| Nur Aliase | bat, eza, fd | Nein |

**Reihenfolge:** In `.zshrc` werden Tools nach den Alias-Dateien initialisiert.

## Schritt 5: Theming prüfen

Falls das Tool eine Config mit Farben hat:

### 5a: Upstream-Theme suchen

Prüfe ob ein offizielles Theme existiert auf `github.com/catppuccin/<toolname>`. Falls ja:

1. Theme-Datei herunterladen und unter `terminal/.config/<tool>/` ablegen
2. Header-Block hinzufügen (Zweck, Pfad, Quelle)
3. Prüfe ob `bg:#1E1E2E` entfernt werden sollte (für transparenten Terminal-Hintergrund)
4. Akzentfarbe auf **Mauve** (`#CBA6F7`) setzen falls konfigurierbar

### 5b: Semantische Farben anwenden

Falls Anpassungen nötig sind, nutze die Zuweisungen aus `terminal/.config/theme-style`:

| Verwendung | Farbe | Hex |
| ---------- | ----- | --- |
| Selection | Surface1 | `#45475A` |
| Accent | Mauve | `#CBA6F7` |
| Marker | Lavender | `#B4BEFE` |
| Success | Green | `#A6E3A1` |
| Error | Red | `#F38BA8` |

### 5c: Theme-Quellen-Tabelle aktualisieren

In `terminal/.config/theme-style` die Tabelle um einen Eintrag erweitern:

```text
#   toolname     | ~/.config/tool/theme-file          | github.com/catppuccin/toolname                | upstream+anpassung
```

Status-Suffixe: `upstream` (unverändert), `+X` (Anpassung), `-X` (Entfernung), `manual` (kein Upstream).

### 5d: Post-Install prüfen

Manche Tools brauchen Cache-Rebuilds nach Theme-Änderungen (z.B. `bat cache --build`). Falls nötig, gehört das in ein Setup-Modul unter `setup/modules/`.

## Schritt 6: Doku generieren

```zsh
./.github/scripts/generate-docs.sh --generate
```

Dies generiert automatisch tldr-Patches und aktualisiert README + docs.

## Schritt 7: Validieren

```zsh
# Pre-Commit Checks lokal ausführen
./.github/hooks/pre-commit

# Health-Check
./.github/scripts/health-check.sh
```

## Checkliste

- [ ] Brewfile-Eintrag mit Beschreibung + URL
- [ ] BREW_TO_ALT Mapping für Debian ARM (apt-packages.sh)
- [ ] `.alias`-Datei mit korrektem Header-Format
- [ ] Guard-Check am Anfang der `.alias`-Datei
- [ ] Shell-Init in `.zshrc` (falls nötig)
- [ ] Catppuccin-Theme geprüft/installiert
- [ ] `generate-docs.sh --generate` ausgeführt
- [ ] Pre-Commit Hooks bestanden
