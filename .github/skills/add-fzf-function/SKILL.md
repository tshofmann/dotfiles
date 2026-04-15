---
name: add-fzf-function
description: 'Schritt-für-Schritt Workflow um eine neue interaktive fzf-Funktion zu einer .alias-Datei hinzuzufügen: Beschreibungskommentar, header-wrap, Keybinding-Sync und Validierung.'
argument-hint: '<funktionsname> in <tool>.alias'
---

# Neue fzf-Funktion hinzufügen

Folge diesen Schritten **in Reihenfolge** um eine fzf-Funktion korrekt zu implementieren.

## Schritt 1: Zuordnung klären

Die Funktion gehört in die `.alias`-Datei des Tools, das sie **primär** repräsentiert:

| Funktion | Datei | Begründung |
| -------- | ----- | ---------- |
| `zj()` | `zoxide.alias` | zoxide-Workflow, fzf nur UI |
| `bat-theme()` | `bat.alias` | bat-spezifisch |
| `procs()` | `fzf.alias` | generische Funktion ohne Tool-Bindung |

**Faustregel:** Frage „Ohne welches Tool wäre diese Funktion sinnlos?“ → Dort gehört sie hin.

## Schritt 2: Beschreibungskommentar schreiben

**Format (Single Source of Truth für tldr-Patches):**

```text
# Name(param?) – Key=Aktion, Key=Aktion
```

| Notation | Bedeutung |
| -------- | --------- |
| `(param)` | Pflichtparameter |
| `(param?)` | Optionaler Parameter |
| `(param=default)` | Optional mit Default |

Keybindings: `Enter=Aktion`, `Ctrl+S=Aktion`, durch `,` getrennt.

**Beispiele:**

```zsh
# zoxide Browser(suche?) – Enter=Wechseln, Ctrl+D=Eintrag löschen, Ctrl+Y=Pfad kopieren
# Theme Browser(suche?) – Enter=Theme aktivieren
# Live-Grep(suche?) – Enter=Datei öffnen, Ctrl+Y=Pfad kopieren
```

## Schritt 3: Funktion implementieren

**Syntax:** Immer `name() {` — **nicht** `function name` oder `function name()`.

**Template:**

```zsh
# Beschreibung(param?) – Enter=Aktion, Ctrl+Y=Kopieren
name() {
    local query="${1:-}"
    local selection

    selection=$(some-command | fzf --query="$query" \
        --preview "$FZF_HELPER_DIR/preview <type> {}" \
        --bind "ctrl-y:execute-silent($FZF_HELPER_DIR/action copy {})" \
        --bind "start,resize:transform-header:$FZF_HELPER_DIR/header-wrap 'Enter: Aktion' 'Ctrl+Y: Kopieren'")

    [[ -z "$selection" ]] && return 0
    # Aktion mit $selection
}
```

**Regeln:**

- `local query="${1:-}"` für optionalen Suchparameter
- `[[ -z "$selection" ]] && return 0` für Abbruch-Handling
- `$FZF_HELPER_DIR` statt hartcodierter Pfade (definiert in `terminal/.config/fzf/init.zsh`)
- Previews: `$FZF_HELPER_DIR/preview <type> {field}` nutzen
- Aktionen: `$FZF_HELPER_DIR/action <name> {field}` nutzen

## Schritt 4: header-wrap integrieren

**Kein `--header=`** verwenden — `header-wrap` übernimmt die Header-Generierung mit dynamischem Umbruch.

**Standard-Binding:**

```zsh
--bind "start,resize:transform-header:$FZF_HELPER_DIR/header-wrap 'Key: Aktion' 'Key: Aktion'"
```

**Sonderfälle:**

| Situation | Lösung |
| --------- | ------ |
| Anderes `start`-Binding existiert bereits | `start:+transform-header` (additiv) + separates `resize:transform-header` |
| Pipe-Zeichen im Text | `\|` escapen: `'Enter: Aktion \| Tab: Mehrfach'` |

**Beispiel für additives Binding** (wenn `start` bereits belegt ist wie bei `rg-live`):

```zsh
--bind "start:+transform-header:$FZF_HELPER_DIR/header-wrap 'Enter: Datei öffnen' 'Ctrl+Y: Pfad kopieren'" \
--bind "resize:transform-header:$FZF_HELPER_DIR/header-wrap 'Enter: Datei öffnen' 'Ctrl+Y: Pfad kopieren'"
```

## Schritt 5: Keybinding-Sync sicherstellen

Zwei Quellen müssen **exakt** übereinstimmen:

| Quelle | Format | Beispiel |
| ------ | ------ | -------- |
| Beschreibungskommentar | `Key=Aktion` | `Ctrl+Y=Pfad kopieren` |
| header-wrap Argumente | `'Key: Aktion'` | `'Ctrl+Y: Pfad kopieren'` |

Der Aktions-Text (nach `=` bzw. `:`) muss **identisch** sein. Nur der Separator (`=` vs `:`) unterscheidet sich.

## Schritt 6: Cross-Platform Abstraktionen

**Immer** diese Wrapper statt nativer Befehle verwenden:

| Statt | Verwende | Definiert in |
| ----- | -------- | ------------ |
| `pbcopy` | `clip` | `platform.zsh` |
| `pbpaste` | `clippaste` | `platform.zsh` |
| `open` | `xopen` | `platform.zsh` |
| `sed -i` | `sedi` | `platform.zsh` |

## Schritt 7: Header-Feld `# Aliase :` aktualisieren

In der `.alias`-Datei den Header-Kommentar aktualisieren — die neue Funktion zum `# Aliase :` Feld hinzufügen.

## Schritt 8: Validieren

```zsh
# Keybinding-Sync prüfen (muss grün sein)
./.github/scripts/check-header-sync.sh

# Doku generieren (tldr-Patches werden aktualisiert)
./.github/scripts/generate-docs.sh --generate

# Pre-Commit Checks
./.github/hooks/pre-commit
```

## Referenz: Vollständiges Beispiel

```zsh
# zoxide Browser(suche?) – Enter=Wechseln, Ctrl+D=Eintrag löschen, Ctrl+Y=Pfad kopieren
zj() {
    local query="${1:-}"
    local selection dir

    selection=$(zoxide query -l -s | \
        fzf -n2.. --query="$query" \
            --preview "$FZF_HELPER_DIR/preview dir {2..} 2" \
            --bind "ctrl-d:execute-silent($FZF_HELPER_DIR/action zoxide-remove {2..})+reload(zoxide query -l -s)" \
            --bind "ctrl-y:execute-silent($FZF_HELPER_DIR/action copy {2..})" \
            --bind "start,resize:transform-header:$FZF_HELPER_DIR/header-wrap 'Enter: Wechseln' 'Ctrl+D: Eintrag löschen' 'Ctrl+Y: Pfad kopieren'")

    [[ -n "$selection" ]] && dir=$(echo "$selection" | awk '{$1=""; print substr($0,2)}') && cd "$dir"
}
```

## Checkliste

- [ ] Zuordnung: Funktion ist in der richtigen `.alias`-Datei
- [ ] Beschreibungskommentar mit `Key=Aktion` Format
- [ ] `name() {` Syntax (nicht `function name`)
- [ ] `local query="${1:-}"` für optionalen Suchparameter
- [ ] `$FZF_HELPER_DIR` statt hartcodierter Pfade
- [ ] `header-wrap` statt `--header=`
- [ ] Keybinding-Text exakt synchron (Kommentar ↔ header-wrap)
- [ ] Cross-Platform: `clip`/`xopen`/`sedi` statt nativer Befehle
- [ ] `# Aliase :` Header-Feld aktualisiert
- [ ] `check-header-sync.sh` bestanden
- [ ] `generate-docs.sh --generate` ausgeführt
