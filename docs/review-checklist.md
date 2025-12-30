# 🔍 Review-Checklist

Strukturierter Analyse- und Review-Prompt für dieses dotfiles-Repository.

> **Trigger:** Dieses Dokument an Copilot senden, um ein vollständiges Review zu starten.
> 
> **Grundregeln:** Siehe [copilot-instructions.md](../.github/copilot-instructions.md) für Arbeitsweise, Sprache und Code-Stil.

---

## ⚠️ KRITISCH: Manuelle Verifikation

> **Validatoren sind Hilfsmittel, nicht Wahrheit.**

Die automatischen Validatoren (`validate-docs.sh`, `health-check.sh`, Unit-Tests) können **selbst fehlerhaft sein**. Sie prüfen nur das, wofür sie programmiert wurden – nicht das Gesamtbild.

### Pflicht bei jedem Review

1. **Validator-Output kritisch hinterfragen**
   - Grünes Ergebnis ≠ Korrektheit
   - Prüft der Validator überhaupt das Richtige?
   - Gibt es Aspekte, die kein Validator abdeckt?

2. **Manuelle Gegenproben durchführen**
   - `grep`, `cat`, `diff` verwenden, um Validator-Aussagen zu verifizieren
   - Stichproben: Nimm 2-3 Aliase und prüfe manuell, ob Doku stimmt
   - Fehlerhafte Eingaben testen: Löst der Validator wirklich Fehler aus?

3. **Tool-Integrationen tatsächlich testen**
   - Nicht nur Code lesen – im Terminal ausführen
   - Edge-Cases ausprobieren (leere Eingabe, Sonderzeichen, fehlende Tools)

4. **Konsistenz über Dateigrenzen hinweg**
   - Gleiche Farben in fzf/config, help.alias, allen Previews?
   - Gleiche Patterns in allen Alias-Dateien?
   - XDG-Pfade: Stimmen Variablen mit tatsächlichen Symlinks überein?

### Verboten

- ❌ Validator laufen lassen und Ergebnis ungeprüft übernehmen
- ❌ "Tests bestanden" als Review-Abschluss melden
- ❌ Nur Code lesen ohne Terminal-Verifikation

---

## Rolle

Du agierst als **Systems Engineer und Toolchain-Architekt** für dieses Repository:
- **Plattform:** macOS mit Apple Silicon (arm64)
- **Shell:** zsh (Login- und interaktive Shell)
- **Kontext:** Dotfiles mit Bootstrap-Mechanismus und Catppuccin Mocha Theme

---

## Phase 1: Repository-Erkundung

> **Ziel:** Aktuellen Zustand erfassen – nicht aus Annahmen ableiten.

### 1.1 Struktur analysieren

```zsh
# Aktuelle Struktur erfassen
tree -L 3 -a -I ".git"
find . -type f -name "*.alias" | wc -l
find . -type f -name "*.sh" | head -20
```

**Prüfen:**
- [ ] Stimmt `docs/architecture.md` → "Verzeichnisstruktur" mit Realität überein?
- [ ] Sind alle Alias-Dateien in `terminal/.config/alias/` dokumentiert?
- [ ] Existieren alle referenzierten Dateien?

### 1.2 Einstiegspunkte identifizieren

| Datei | Zweck | Abhängigkeiten |
|-------|-------|----------------|
| `setup/bootstrap.sh` | Hauptinstallation | Homebrew, Internet |
| `terminal/.zshenv` | Umgebungsvariablen | Wird zuerst geladen |
| `terminal/.zprofile` | Login-Shell | Homebrew-Pfad |
| `terminal/.zshrc` | Interaktive Shell | Aliase, Tools |

### 1.3 Tool-Inventar aus Brewfile

```zsh
# Tatsächlich installierte Formulae/Casks
grep "^brew " setup/Brewfile | wc -l
grep "^cask " setup/Brewfile | wc -l
grep "^mas " setup/Brewfile | wc -l
```

**Abgleichen mit:**
- `docs/architecture.md` → Brewfile-Details
- `docs/tools.md` → Tool-Übersicht

---

## Phase 2: Bootstrap-Analyse

> **Ziel:** Idempotenz und Robustheit verifizieren.

### 2.1 Bootstrap-Flow nachvollziehen

```zsh
# Bootstrap-Skript lesen
cat setup/bootstrap.sh
```

**Dokumentieren:**
1. Was passiert in welcher Reihenfolge?
2. Welche Checks existieren (Architektur, macOS-Version, Netzwerk)?
3. Wo werden Zustände geprüft vor Aktionen?

### 2.2 Idempotenz-Test

```zsh
# Mehrfach ausführen – Ergebnis muss identisch sein
./setup/bootstrap.sh
./setup/bootstrap.sh
```

**Prüfen:**
- [ ] Keine Fehler bei Wiederholung
- [ ] Keine doppelten Installationen
- [ ] Symlinks bleiben intakt

### 2.3 Implizite Annahmen finden

Suchen nach Stellen die annehmen ohne zu prüfen:
- Verzeichnisse existieren
- Tools sind vorinstalliert
- Umgebungsvariablen gesetzt
- Internet verfügbar

```zsh
# Potenzielle ungeprüfte Annahmen
grep -n "cd " setup/bootstrap.sh
grep -n "\$HOME" setup/bootstrap.sh | head -10
```

---

## Phase 3: Alias- und Konfigurationsprüfung

> **Ziel:** Code-Qualität und Konsistenz sicherstellen.

### 3.1 Alias-Dateien analysieren

Für jede Datei in `terminal/.config/alias/`:

**Struktur-Checks:**
- [ ] Header-Block mit Metadaten (Zweck, Pfad, Docs, Hinweis)?
- [ ] Guard-Check vorhanden (`command -v tool >/dev/null`)?
- [ ] Beschreibungskommentare für Help-System?
- [ ] Private Funktionen mit `_` Prefix?

**Stil-Checks (aus CONTRIBUTING.md):**
- [ ] Metadaten 8 Zeichen breit, linksbündig?
- [ ] Sektions-Trenner 60 Zeichen?
- [ ] Lokale Variablen mit `local`?

```zsh
# Automatische Stil-Prüfung
./scripts/validate-docs.sh --extended
```

### 3.2 fzf-Integration prüfen

Besondere Aufmerksamkeit auf Preview-Commands:

```zsh
# fzf-Previews mit ZSH-Syntax finden
grep -n "preview=" terminal/.config/alias/*.alias
```

**Prüfen:**
- [ ] ZSH-Syntax in Previews mit `zsh -c '...'` gewrappt?
- [ ] Catppuccin-Farben aus `fzf/config` verwendet?
- [ ] Keybinding-Header im Format `Key: Aktion | Key: Aktion`?

### 3.3 XDG-Konformität

```zsh
# XDG-Variablen in .zshenv
grep "XDG_" terminal/.zshenv

# Tool-spezifische Overrides
grep "EZA_CONFIG_DIR\|RIPGREP_CONFIG_PATH\|BAT_CONFIG" terminal/.zsh*
```

**Prüfen:**
- [ ] Alle Tools nutzen `~/.config/` (nicht `~/Library/Application Support`)?
- [ ] Config-Pfade in Alias-Dateien korrekt?

---

## Phase 4: Dokumentations-Synchronisation

> **Ziel:** Code = Docs = Copilot-Instructions.

### 4.1 Automatische Validierung

```zsh
# Vollständige Validierung
./scripts/validate-docs.sh

# Kern-Validierungen
./scripts/validate-docs.sh --core

# Erweiterte Prüfungen
./scripts/validate-docs.sh --extended
```

### 4.2 Manuelle Checks

| Dokument | Prüfen gegen |
|----------|--------------|
| `README.md` | Aktuelle Features, Quickstart funktioniert |
| `docs/architecture.md` | Verzeichnisstruktur, Brewfile-Zahlen |
| `docs/tools.md` | Installierte Tools, Aliase |
| `docs/installation.md` | Symlink-Tabelle, Bootstrap-Schritte |
| `CONTRIBUTING.md` | Stil-Regeln, Header-Format |
| `.github/copilot-instructions.md` | Patterns, Architektur-Entscheidungen |

### 4.3 Code-Marker finden

```zsh
# Offene TODOs/FIXMEs
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.sh" --include="*.alias" --include="*.md"
```

---

## Phase 5: Tool-Integrationen gründlich prüfen

> **Ziel:** Jede Integration manuell verifizieren – Code lesen UND ausführen.

### 5.1 fzf-Gesamtintegration

**1. Backend-Konfiguration verifizieren (.zshrc):**

```zsh
# Prüfen welche Variablen gesetzt werden
grep -A2 "FZF_DEFAULT_COMMAND\|FZF_CTRL_T\|FZF_ALT_C" terminal/.zshrc
```

Manuell verifizieren:
- [ ] `FZF_DEFAULT_COMMAND` nutzt fd (nicht find)?
- [ ] `FZF_CTRL_T_COMMAND` identisch zu DEFAULT?
- [ ] `FZF_ALT_C_COMMAND` nutzt `fd --type d`?
- [ ] Bei fehlendem fd: Fällt fzf korrekt auf find zurück?

**2. Preview-Commands in ALLEN Dateien:**

```zsh
# ALLE Preview-Definitionen finden
grep -rn "preview" terminal/.config/alias/*.alias terminal/.zshrc
grep -rn "FZF.*OPTS" terminal/.zshrc
```

Für JEDE gefundene Preview prüfen:
- [ ] Nutzt externe Befehle (bat, eza, cat)? → OK ohne Wrapper
- [ ] Nutzt ZSH-Syntax (Parameter Expansion `${var}`, `[[ ]]`)? → Sollte `zsh -c` Wrapper haben (siehe copilot-instructions.md)
- [ ] Konsistente Farben (Catppuccin Mocha)?
- [ ] Fehlerbehandlung (`|| fallback`)?

**3. Keybindings verifizieren:**

```zsh
# Im Terminal testen:
# Ctrl+T – Dateisuche mit bat-Preview
# Ctrl+R – History mit Vorschau
# Alt+C  – Verzeichniswechsel mit eza-Preview
```

### 5.2 zoxide-Integration

```zsh
# Konfiguration prüfen
grep -A5 "zoxide" terminal/.zshrc
grep -n "zoxide\|_ZO_" terminal/.config/alias/*.alias
```

Manuell prüfen:
- [ ] `_ZO_FZF_OPTS` setzt eza-Preview?
- [ ] `zf()` Funktion in fzf.alias nutzt zoxide query?
- [ ] `zi` (built-in) funktioniert?
- [ ] Preview-Command konsistent mit anderen eza-Previews?

### 5.3 Catppuccin Theme-Konsistenz

**Kritisch:** Gleiche Farben müssen überall verwendet werden.

```zsh
# Alle Farbdefinitionen finden
grep -rn "1E1E2E\|CDD6F4\|F38BA8\|A6E3A1\|CBA6F7\|89B4FA" terminal/.config/
grep -rn "Mauve\|Sky\|Green\|Red\|Yellow" terminal/.config/alias/help.alias
```

Vergleichen:
- [ ] `fzf/config` Farben = `help.alias` Preview-Farben?
- [ ] `bat/themes/` = Catppuccin Mocha?
- [ ] `btop/themes/` = Catppuccin Mocha?
- [ ] `eza/theme.yml` = Catppuccin Mocha?
- [ ] `lazygit/config.yml` = Catppuccin Mocha?
- [ ] Terminal-Profil = Catppuccin Mocha Hintergrund (#1E1E2E)?

### 5.4 XDG-Pfade tatsächlich verifizieren

**Nicht nur Variablen prüfen – tatsächliche Symlinks:**

```zsh
# Definierte Variablen
grep "XDG_CONFIG_HOME\|EZA_CONFIG_DIR\|RIPGREP_CONFIG_PATH\|FZF_DEFAULT_OPTS_FILE" terminal/.zsh*

# Tatsächliche Symlinks
ls -la ~/.config/fzf/config
ls -la ~/.config/ripgrep/config
ls -la ~/.config/eza/
ls -la ~/.config/bat/config
```

Manuell prüfen:
- [ ] Jede Variable zeigt auf existierenden Symlink?
- [ ] Symlink zeigt in dotfiles-Repo (nicht Kopie)?
- [ ] Tools laden Config tatsächlich von dort (`bat --config-file`, `rg --version`)?

### 5.5 Alle Alias-Dateien einzeln prüfen

**Für JEDE Datei in `terminal/.config/alias/`:**

| Datei | Guard | Header | Previews | Catppuccin |
|-------|-------|--------|----------|------------|
| bat.alias | | | | |
| btop.alias | | | | |
| eza.alias | | | | |
| fd.alias | | | | |
| fzf.alias | | | | |
| gh.alias | | | | |
| git.alias | | | | |
| help.alias | | | | |
| homebrew.alias | | | | |
| ripgrep.alias | | | | |

Prüfpunkte pro Datei:
- [ ] Guard: `if ! command -v <tool>` vorhanden und korrekt?
- [ ] Header: Alle Pflichtfelder (Zweck, Pfad, Docs)?
- [ ] Previews: ZSH-Syntax gewrappt? Fallbacks?
- [ ] Catppuccin: Verwendete Farben korrekt?

---

## Phase 6: Fehlertests

> **Ziel:** Robustheit unter realen Bedingungen.

### 6.1 Health-Check

```zsh
./scripts/health-check.sh
```

### 6.2 Alias-Tests

```zsh
# Alle definierten Aliase aufrufen
alias | head -20

# Help-System testen
help
```

### 6.3 Unit-Tests

```zsh
./scripts/tests/run-tests.sh
./scripts/tests/run-tests.sh --verbose
```

### 6.4 Edge-Cases

| Test | Erwartung |
|------|-----------|
| Tool nicht installiert | Guard verhindert Fehler |
| Leeres Verzeichnis | Graceful handling |
| Spezialzeichen in Pfaden | Korrekte Quotierung |

---

## Phase 7: Review-Zusammenfassung

> **Ziel:** Strukturiertes Ergebnis mit Maßnahmen.

### 7.1 Review erstellen

```markdown
## Review: dotfiles

### Zusammenfassung
<2-3 Sätze: Gesamteindruck>

### Stärken
- <Was funktioniert gut>

### Probleme
| # | Problem | Schwere | Dateien |
|---|---------|---------|---------|
| 1 | ... | Kritisch/Hoch/Mittel/Niedrig | ... |

### Verbesserungspotenzial
| # | Bereich | Nutzen | Aufwand |
|---|---------|--------|---------|
| 1 | ... | ... | Gering/Mittel/Hoch |
```

### 7.2 Maßnahmen priorisieren

| Priorität | Kriterien |
|-----------|-----------|
| **Kritisch** | Blockiert Nutzung, Sicherheit |
| **Hoch** | Kernfunktionalität beeinträchtigt |
| **Mittel** | Wartbarkeit, Robustheit |
| **Niedrig** | Nice-to-have, Kosmetik |

### 7.3 Freigabe einholen

> **Keine Umsetzung ohne explizite Freigabe.**

```
Welche Maßnahmen soll ich umsetzen?
- Alle
- Nur #1 und #3
- Erst mehr Details zu #2
```

---

## Checkliste: Review abgeschlossen

- [ ] Repository-Struktur mit Dokumentation abgeglichen
- [ ] Bootstrap idempotent und robust
- [ ] Alias-Dateien entsprechen Stil-Regeln
- [ ] fzf-Integration korrekt (ZSH-Wrapping, Catppuccin)
- [ ] XDG-Konformität gegeben
- [ ] Dokumentation synchron (validate-docs.sh grün)
- [ ] Health-Check und Tests bestanden
- [ ] Review-Zusammenfassung erstellt
- [ ] Maßnahmen priorisiert und zur Freigabe vorgelegt
