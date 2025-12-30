# 🔍 Review-Checklist

Strukturierter Analyse- und Review-Prompt für dieses dotfiles-Repository.

> **Trigger:** Dieses Dokument an Copilot senden, um ein vollständiges Review zu starten.
> 
> **Grundregeln:** Siehe [copilot-instructions.md](../.github/copilot-instructions.md) für Arbeitsweise, Sprache und Code-Stil.

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

## Phase 5: Synergie- und Redundanz-Analyse

> **Ziel:** Tool-Zusammenspiel optimieren.

### 5.1 Tool-Integrationen prüfen

Aus `docs/architecture.md` → Tool-Integrationen:

| Integration | Funktioniert? |
|-------------|---------------|
| fzf + fd (Ctrl+T, Alt+C) | |
| fzf + bat (Preview) | |
| fzf + eza (Alt+C Preview) | |
| zoxide + fzf (zi) | |
| lazygit + git | |

```zsh
# Integration testen
# Ctrl+T, Alt+C, Ctrl+R im Terminal ausprobieren
zi  # zoxide interaktiv
```

### 5.2 Ungenutzte Synergien erkennen

Fragen:
- Könnten Tools besser zusammenarbeiten?
- Gibt es Konfigurationen die nicht genutzt werden?
- Sind alle Catppuccin-Themes konsistent?

### 5.3 Redundanzen identifizieren

**Sinnvoll (beibehalten):**
- Fallback-Mechanismen (fd → find)
- Alias-Alternativen für verschiedene Use-Cases

**Problematisch (adressieren):**
- Doppelte Definitionen
- Divergierende Konfigurationen

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
