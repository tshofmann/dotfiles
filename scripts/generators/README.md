# Dokumentations-Generatoren

Automatische Generierung von Dokumentations-Inhalten aus Code.

## Übersicht

| Generator | Quelle | Ziel | Status |
|-----------|--------|------|--------|
| `aliases.sh` | `terminal/.config/alias/*.alias` | `docs/tools.md` | ✅ Implementiert |
| `tools.sh` | `setup/Brewfile` | `docs/tools.md` | 🔮 Geplant |
| `validators.sh` | `scripts/validators/` | `CONTRIBUTING.md` | 🔮 Geplant |
| `structure.sh` | `tree` Command | `docs/architecture.md` | 🔮 Geplant |
| `keybindings.sh` | `*.alias`, `fzf/config` | `docs/tools.md` | 🔮 Geplant |

## Verwendung

### Alle Generatoren ausführen

```zsh
./scripts/generate-docs.sh
```

### Dry-Run (zeigt was geändert würde)

```zsh
./scripts/generate-docs.sh --dry-run
```

### Automatisch via Pre-Commit Hook

Der Generator wird automatisch vor jedem Commit ausgeführt wenn relevante Dateien geändert wurden:
- `terminal/.config/alias/*.alias`
- `setup/Brewfile`
- `docs/*.md`
- `CONTRIBUTING.md`

## Architektur

### Marker-System

Generierte Bereiche werden durch HTML-Kommentare markiert:

```markdown
<!-- BEGIN:GENERATED:SECTION_NAME -->
<!-- AUTO-GENERATED – Änderungen werden überschrieben -->
...generierter Inhalt...
<!-- END:GENERATED:SECTION_NAME -->
```

**Wichtig:** Manuelle Änderungen zwischen Markern gehen beim nächsten Commit verloren!

### lib.sh – Gemeinsame Bibliothek

**Funktionen:**
- `extract_alias_table <file>` – Extrahiert Aliase mit Beschreibungen
- `extract_function_table <file>` – Extrahiert Funktionen mit Beschreibungen
- `replace_marked_section <file> <section> <content>` – Ersetzt Inhalt zwischen Markern
- Logging: `log`, `ok`, `warn`, `info`, `debug`
- Pfad-Konfiguration: `$DOTFILES_DIR`, `$DOCS_DIR`, `$ALIAS_DIR`, etc.

### Ablauf

1. **Laden:** `generate-docs.sh` lädt alle Generator-Module aus `generators/*.sh`
2. **Extraktion:** Parser lesen Kommentare und Definitionen aus Code
3. **Generierung:** Markdown-Tabellen werden gebaut
4. **Ersetzung:** Inhalte zwischen Markern werden aktualisiert
5. **Staging:** Pre-Commit Hook staged die Änderungen automatisch

## Neuen Generator hinzufügen

1. Generator-Datei in `scripts/generators/` erstellen:
   ```zsh
   #!/usr/bin/env zsh
   [[ -z "${GENERATOR_LIB_LOADED:-}" ]] && source "${0:A:h}/lib.sh"
   
   generate_my_section() {
       local target_file="$1"
       # ... Logik hier ...
       replace_marked_section "$target_file" "MY_SECTION" "$content"
   }
   ```

2. Marker in Zieldatei einfügen:
   ```markdown
   <!-- BEGIN:GENERATED:MY_SECTION -->
   ...existierender Inhalt (wird überschrieben)...
   <!-- END:GENERATED:MY_SECTION -->
   ```

3. Generator in `generate-docs.sh` aufrufen:
   ```zsh
   if [[ $(type -w generate_my_section) == *function* ]]; then
       generate_my_section "$DOCS_DIR/target.md"
   fi
   ```

## Parser-Regeln

### Alias-Extraktion

**Erwartet:**
```zsh
# Beschreibung des Alias
alias name='befehl'
```

**Ignoriert:**
- Header-Kommentare (`# ====`, `# Zweck :`, etc.)
- Trennlinien
- Kommentare in Guard-Blocks (`if command -v ... fi`)

### Funktions-Extraktion

**Erwartet:**
```zsh
# Beschreibung der Funktion
funktionsname() {
    ...
}
```

**Ignoriert:**
- Private Funktionen (mit `_` Prefix)
- Header-Kommentare
- Inline-Kommentare innerhalb der Funktion

## Fehlerbehandlung

Wenn der Generator fehlschlägt:

1. **Syntax-Check:**
   ```zsh
   zsh -n scripts/generate-docs.sh
   zsh -n scripts/generators/*.sh
   ```

2. **Debug-Modus:**
   ```zsh
   GEN_DEBUG=1 ./scripts/generate-docs.sh
   ```

3. **Hook überspringen (Notfall):**
   ```zsh
   git commit --no-verify
   ```

## Design-Prinzipien

- **Code als Single Source of Truth:** Dokumentation wird aus Code generiert, nicht umgekehrt
- **Idempotenz:** Mehrfaches Ausführen produziert dasselbe Ergebnis
- **Fail-Safe:** Generator-Fehler blockieren Commits (außer mit `--no-verify`)
- **Explizite Marker:** Generierte Bereiche sind klar gekennzeichnet
- **Modulare Generatoren:** Jeder Generator ist eigenständig testbar
