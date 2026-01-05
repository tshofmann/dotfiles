# Automatische Dokumentations-Generierung

> **Code ist die Single Source of Truth** – Dokumentation wird automatisch aus dem Code generiert.

## Konzept

Traditionell müssen Entwickler bei jeder Code-Änderung manuell die Dokumentation aktualisieren. Dieses System dreht den Prozess um:

```
┌─────────────┐
│ Code ändern │  (z.B. neuer Alias in bat.alias)
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ git commit          │
└──────┬──────────────┘
       │ Pre-Commit Hook
       ▼
┌─────────────────────┐
│ generate-docs.sh    │  Parser extrahiert Aliase/Funktionen
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ docs/tools.md       │  Markdown-Tabellen werden aktualisiert
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ git add docs/*.md   │  Änderungen automatisch stagen
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ validate-docs.sh    │  Konsistenzprüfung
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Commit erfolgt      │  Dokumentation ist synchron
└─────────────────────┘
```

**Vorteile:**
- ✅ Dokumentation ist immer aktuell
- ✅ Kein manuelles Pflegen von Tabellen
- ✅ Konsistenz durch automatische Prüfung
- ✅ Weniger Fehler durch Vergessen

## Was wird generiert?

| Sektion | Quelle | Ziel | Marker |
|---------|--------|------|--------|
| **brew.alias Tabelle** | `terminal/.config/alias/brew.alias` | `docs/tools.md` | `ALIASES_BREW` |
| **fd.alias Tabelle** | `terminal/.config/alias/fd.alias` | `docs/tools.md` | `ALIASES_FD` |
| **btop.alias Tabelle** | `terminal/.config/alias/btop.alias` | `docs/tools.md` | `ALIASES_BTOP` |
| **fastfetch.alias Tabelle** | `terminal/.config/alias/fastfetch.alias` | `docs/tools.md` | `ALIASES_FASTFETCH` |
| **git.alias Tabelle** | `terminal/.config/alias/git.alias` | `docs/tools.md` | `ALIASES_GIT` |
| **eza.alias Tabelle** | `terminal/.config/alias/eza.alias` | `docs/tools.md` | `ALIASES_EZA` |
| **bat.alias Tabelle** | `terminal/.config/alias/bat.alias` | `docs/tools.md` | `ALIASES_BAT` |
| **rg.alias Tabelle** | `terminal/.config/alias/rg.alias` | `docs/tools.md` | `ALIASES_RG` |
| **gh.alias Tabelle** | `terminal/.config/alias/gh.alias` | `docs/tools.md` | `ALIASES_GH` |
| **fzf.alias Tabelle** | `terminal/.config/alias/fzf.alias` | `docs/tools.md` | `ALIASES_FZF` |

**Hinweis:** Funktions-Tabellen werden automatisch für Dateien mit interaktiven Funktionen generiert.

## Marker-System

Generierte Bereiche sind durch HTML-Kommentare markiert:

```markdown
### bat.alias

<!-- BEGIN:GENERATED:ALIASES_BAT -->
<!-- AUTO-GENERATED – Änderungen werden überschrieben -->
| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `cat` | `bat -pp` | cat-Ersatz: Plain + kein Pager |
| `catn` | `bat --style=numbers --paging=never` | Nur Zeilennummern |
...
<!-- END:GENERATED:ALIASES_BAT -->

> **Hinweis:** Manuelle Anmerkungen außerhalb der Marker bleiben erhalten.
```

**Wichtig:**
- ✅ Inhalte **außerhalb** der Marker können manuell gepflegt werden
- ⚠️ Inhalte **zwischen** Markern werden bei jedem Commit überschrieben
- 🔒 Marker selbst dürfen nicht manuell bearbeitet werden

## Verwendung

### Automatisch via Pre-Commit Hook (Standard)

Wenn du eine `.alias`-Datei änderst und committest, wird die Dokumentation automatisch generiert:

```zsh
# 1. Alias hinzufügen
echo "# Neuer Alias für..." >> terminal/.config/alias/bat.alias
echo "alias catr='bat --style=rule'" >> terminal/.config/alias/bat.alias

# 2. Committen – Generator läuft automatisch
git add terminal/.config/alias/bat.alias
git commit -m "feat: Füge catr Alias hinzu"

# Output:
# 📝 Generiere Dokumentation aus Code...
#   ✔ Dokumentation generiert und gestaged
# 📖 Prüfe Dokumentations-Konsistenz...
#   ✔ Dokumentation ist synchron
```

### Manuell ausführen

```zsh
# Alle Generatoren ausführen
./scripts/generate-docs.sh

# Dry-Run: Zeige was geändert würde
./scripts/generate-docs.sh --dry-run

# Hilfe anzeigen
./scripts/generate-docs.sh --help
```

## Neuen Alias dokumentieren

### Schritt 1: Beschreibungskommentar hinzufügen

```zsh
# terminal/.config/alias/bat.alias

# Zeige Datei mit Syntax-Highlighting (ohne Pager)
alias cat='bat -pp'

# Nur Zeilennummern anzeigen
alias catn='bat --style=numbers --paging=never'
```

**Parser-Regeln:**
- Kommentar direkt vor der Alias-Definition
- Eine Zeile, beginnend mit `#` gefolgt von Leerzeichen
- Header-Kommentare (`# ====`, `# Zweck :`) werden ignoriert

### Schritt 2: Committen

```zsh
git add terminal/.config/alias/bat.alias
git commit -m "feat: Füge cat/catn Aliase hinzu"
```

Der Pre-Commit Hook generiert automatisch die Tabelle in `docs/tools.md`.

### Schritt 3: Verifizieren

```zsh
# Prüfe ob Tabelle aktualisiert wurde
git diff docs/tools.md

# Oder: Dokumentation öffnen
bat docs/tools.md
```

## Funktionen dokumentieren

Funktionen werden wie Aliase behandelt:

```zsh
# terminal/.config/alias/bat.alias

if command -v fzf >/dev/null 2>&1; then
    # Theme interaktiv auswählen und aktivieren
    bat-theme() {
        local theme
        theme=$(bat --list-themes | fzf --preview='bat --theme={} --color=always ~/.zshrc')
        [[ -n "$theme" ]] && sed -i "s/^--theme=.*$/--theme=\"$theme\"/" ~/.config/bat/config
    }
fi
```

**Ausgabe:**

```markdown
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `bat-theme` | Theme interaktiv auswählen und aktivieren |
```

## Fehlerbehandlung

### Generator schlägt fehl

```zsh
# Fehler-Output:
❌ Commit abgebrochen: Dokumentations-Generator fehlgeschlagen!

Optionen:
  1. Generator-Fehler beheben und erneut committen
  2. Hook überspringen: git commit --no-verify
```

**Debugging:**

```zsh
# 1. Syntax-Check
zsh -n scripts/generate-docs.sh
zsh -n scripts/generators/*.sh

# 2. Debug-Modus
GEN_DEBUG=1 ./scripts/generate-docs.sh

# 3. Manuell Marker prüfen
grep -n "BEGIN:GENERATED" docs/tools.md
```

### Validation schlägt fehl (nach Generierung)

```zsh
# Fehler-Output:
❌ Commit abgebrochen: Dokumentation stimmt nicht mit Code überein!
```

**Ursachen:**
- Generator hat Marker nicht gefunden → Marker prüfen
- Parser hat Alias nicht erkannt → Kommentar-Format prüfen
- Validatoren erkennen Diskrepanz → Manuell fixen

### Notfall: Hook überspringen

```zsh
git commit --no-verify -m "..."
```

> ⚠️ Nur im Notfall nutzen – Dokumentation muss manuell synchronisiert werden!

## Erweiterung: Neue Generatoren

Siehe [scripts/generators/README.md](../scripts/generators/README.md) für Details zur Implementierung eigener Generatoren.

**Geplante Generatoren (Future Work):**
- [ ] Tool-Übersicht aus `Brewfile`
- [ ] Validator-Anzahlen in `CONTRIBUTING.md`
- [ ] Verzeichnisstruktur via `tree` in `architecture.md`
- [ ] Keybinding-Übersicht aus `fzf/config`

## Design-Prinzipien

1. **Code als Single Source of Truth**
   - Dokumentation wird aus Code generiert, nicht umgekehrt
   - Code-Änderungen triggern automatische Doku-Updates

2. **Idempotenz**
   - Mehrfaches Ausführen produziert identisches Ergebnis
   - Keine unerwarteten Seiteneffekte

3. **Fail-Safe**
   - Generator-Fehler blockieren Commits (außer mit `--no-verify`)
   - Validatoren prüfen Konsistenz nach Generierung

4. **Explizite Marker**
   - Generierte Bereiche sind klar gekennzeichnet
   - Manuelle Ergänzungen außerhalb der Marker bleiben erhalten

5. **Modulare Architektur**
   - Jeder Generator ist eigenständig testbar
   - Gemeinsame Bibliothek (`lib.sh`) für Wiederverwendung

## Verwandte Dokumentation

- [CONTRIBUTING.md](../CONTRIBUTING.md#automatische-dokumentations-generierung) – Anleitung für Entwickler
- [scripts/generators/README.md](../scripts/generators/README.md) – Generator-Architektur
- [scripts/validators/](../scripts/validators/) – Konsistenz-Validatoren
