---
name: 'Alias-Konventionen'
description: 'Header-Format, Guard-Pattern, Funktions-Syntax und Zuordnungsregeln für .alias-Dateien'
applyTo: 'terminal/.config/alias/*.alias'
---

# Alias-Datei Konventionen

## Zuordnungsregel

Ein Alias/Funktion gehört in die `.alias`-Datei des Tools, das er **primär** repräsentiert:

- `zj()` → `zoxide.alias` (zoxide-Workflow, fzf nur UI)
- `procs()` → `fzf.alias` (generische fzf-Funktion)

## Datei-Struktur

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

## Regeln

- Funktionen als `name() {` schreiben – **nicht** `function name` oder `function name()`
- Private Funktionen mit `_` Präfix (werden von Validatoren ignoriert)
- Guard-Check am Anfang: `if ! command -v tool >/dev/null 2>&1; then return 0; fi`
- **Jede Funktion und jeder Alias** braucht einen Beschreibungskommentar direkt darüber
- `# Config :` ist Pflicht wenn das Tool eine lokale Config hat
- Header-Felder auf 12 Zeichen padden, dann Leerzeichen + `:`

## Namenskonvention

| Kategorie | Schema | Beispiele |
| --------- | ------ | --------- |
| Tool-Wrapper | `<tool>-<aktion>` | `git-log`, `brew-add` |
| Browser/Interaktiv | Beschreibend | `help`, `cmds`, `procs` |
| Navigation | Kurze Verben | `go`, `edit`, `zj` |
| Bewusste Ersetzungen | Original-Name | `cat`, `ls`, `top` |

Bindestriche (`-`) statt Unterstriche. Keine Kollisionen mit System-Befehlen (außer bewusste Ersetzungen).

## fzf-Funktionen – Beschreibungsformat

```text
# Name(param?) – Key=Aktion, Key=Aktion
```

- `(param)` = Pflicht, `(param?)` = optional, `(param=default)` = optional mit Default
- Keybindings: `Enter=Aktion`, `Ctrl+S=Aktion`, durch `,` getrennt
- Diese Kommentare sind die Single Source of Truth für tldr-Patches

### Keybinding-Sync (header-wrap)

Jede fzf-Funktion hat zwei synchronisierte Quellen:

| Quelle | Format |
| ------ | ------ |
| Beschreibungskommentar | `Key=Aktion, Key=Aktion` |
| header-wrap Argumente | `'Key: Aktion' 'Key: Aktion'` |

Der Aktions-Text muss **exakt** übereinstimmen. Kein `--header=` verwenden – header-wrap übernimmt.

Neue fzf-Funktion: Kommentar schreiben → `--bind "start,resize:transform-header:..."` → `check-header-sync.sh` ausführen.
