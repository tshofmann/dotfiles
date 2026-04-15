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

Erweitere das `BREW_TO_ALT`-Array in `setup/modules/apt-packages.sh` mit dem Linux-Paketnamen:

```zsh
[toolname]="toolname"  # oder abweichender Paketname
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

1. Prüfe ob ein Catppuccin-Theme existiert auf [github.com/catppuccin](https://github.com/catppuccin)
2. Nutze semantische Farben aus `terminal/.config/theme-style`
3. Aktualisiere die Theme-Quellen-Tabelle in `theme-style`

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
- [ ] BREW_TO_ALT Mapping für Linux
- [ ] `.alias`-Datei mit korrektem Header-Format
- [ ] Guard-Check am Anfang der `.alias`-Datei
- [ ] Shell-Init in `.zshrc` (falls nötig)
- [ ] Catppuccin-Theme geprüft/installiert
- [ ] `generate-docs.sh --generate` ausgeführt
- [ ] Pre-Commit Hooks bestanden
