# 🔍 Review-Checklist

Strukturierter Analyse- und Review-Prompt für dieses dotfiles-Repository.

> **Trigger:** Dieses Dokument an Copilot senden, um ein vollständiges Review zu starten.

---

## ⛔ Grundprinzipien

> **Vollständige Richtlinien:** Siehe [copilot-instructions.md](../.github/copilot-instructions.md)

```
Sehen → Recherchieren → Denken → Verstehen → Handeln
```

- **Repository-Zustand ist die Wahrheit** – nicht Annahmen oder veraltete Dokumentation
- **Generatoren erzeugen Doku aus Code** – Quellcode ist Single Source of Truth
- **Beweispflicht** – jede Aussage mit Beleg (Code, Terminal-Output, Doku)
- **Bei Unklarheiten**: Rückfrage statt Annahme

### ⚠️ Grenzen der automatischen Generierung

Die Dokumentation wird aus dem Code generiert. Das bedeutet:

| Generator prüft ✓ | Generator prüft NICHT ✗ |
|-------------------|-------------------------|
| Header-Felder vorhanden | Ob Header-Inhalte inhaltlich stimmen |
| Aliase werden extrahiert | Ob Aliase das tun was dokumentiert |
| Brewfile-Tools gezählt | Ob Tool-Beschreibungen aktuell sind |
| Struktur aus Dateisystem | Ob Symlinks tatsächlich funktionieren |

**Konsequenz:** Generierte Doku ist strukturell konsistent, aber semantische Korrektheit erfordert manuelles Review.

---

## Rolle & Kontext

| Aspekt | Wert |
|--------|------|
| **Rolle** | Systems Engineer und Toolchain-Architekt |
| **Plattform** | macOS mit Apple Silicon (arm64) |
| **Shell** | zsh (Login- und interaktive Shell) |
| **Design** | Catppuccin Mocha Theme |

> **Stil-Regeln:** Siehe [CONTRIBUTING.md](../CONTRIBUTING.md) → "Stil-Regeln (automatisch geprüft)"

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

**Prüfen (Code → Doku, nicht umgekehrt!):**
- [ ] Fehlen Verzeichnisse/Dateien die im Code existieren aber nicht dokumentiert sind?
- [ ] Gibt es Alias-Dateien ohne entsprechenden Eintrag in tools.md?
- [ ] Referenziert die Doku Dateien die nicht mehr existieren?

### 1.2 Einstiegspunkte identifizieren

```zsh
# Alle Shell-Konfigurationsdateien
ls -la terminal/.zsh* setup/bootstrap.sh

# Ladereihenfolge (zsh-spezifisch):
# 1. .zshenv    – Immer (Umgebungsvariablen)
# 2. .zprofile  – Login-Shell (Homebrew-Pfad)
# 3. .zshrc     – Interaktive Shell (Aliase, Tools)
```

**Für jede gefundene Datei prüfen:**
- [ ] Zweck dokumentiert (Kommentar am Anfang)?
- [ ] Abhängigkeiten klar (was muss vorher geladen sein)?
- [ ] Keine zirkulären Abhängigkeiten?

### 1.3 Tool-Inventar aus Brewfile

```zsh
# Tatsächlich installierte Formulae/Casks
grep "^brew " setup/Brewfile | wc -l
grep "^cask " setup/Brewfile | wc -l
grep "^mas " setup/Brewfile | wc -l
```

---

## Phase 2: Generator-System prüfen

> **Ziel:** Sicherstellen dass Dokumentation korrekt aus Code generiert wird.

### 2.1 Dokumentation regenerieren

```zsh
# Doku neu generieren und Diff prüfen
./scripts/generate-docs.sh

# Oder nur prüfen ohne zu ändern
./scripts/generate-docs.sh --check
```

### 2.2 Generator-Tests

```zsh
# Unit-Tests für Parser-Funktionen
./scripts/tests/test_generators.sh --verbose
```

**Prüfen:**
- [ ] Alle Tests bestanden?
- [ ] Neue Parser-Funktionen getestet?
- [ ] Edge-Cases abgedeckt (leere Dateien, Sonderzeichen)?

### 2.3 Pre-Commit Hook

```zsh
# Hook manuell testen
./.githooks/pre-commit
```

**Prüfen:**
- [ ] Shell-Syntax validiert?
- [ ] Doku automatisch generiert?
- [ ] Bei Änderungen: Doku automatisch gestaged?

---

## Phase 3: Bootstrap-Analyse

> **Ziel:** Idempotenz und Robustheit verifizieren.

### 3.1 Bootstrap-Flow nachvollziehen

```zsh
# Bootstrap-Skript lesen
cat setup/bootstrap.sh
```

**Dokumentieren:**
1. Was passiert in welcher Reihenfolge?
2. Welche Checks existieren (Architektur, macOS-Version, Netzwerk)?
3. Wo werden Zustände geprüft vor Aktionen?

### 3.2 Idempotenz-Test

```zsh
# Mehrfach ausführen – Ergebnis muss identisch sein
./setup/bootstrap.sh
./setup/bootstrap.sh
```

**Prüfen:**
- [ ] Keine Fehler bei Wiederholung
- [ ] Keine doppelten Installationen
- [ ] Output zeigt "bereits vorhanden" bei existierenden Komponenten

---

## Phase 4: Alias- und Konfigurationsprüfung

> **Ziel:** Code-Qualität und Konsistenz sicherstellen.

### 4.1 Alias-Dateien analysieren

Für jede Datei in `terminal/.config/alias/`:

**Struktur-Checks (siehe CONTRIBUTING.md → "Header-Block Format"):**
- [ ] Header-Block mit Metadaten (Zweck, Pfad, Docs)?
- [ ] Guard-Check vorhanden (`command -v tool >/dev/null 2>&1`)?
- [ ] Beschreibungskommentare für Help-System?
- [ ] Private Funktionen mit `_` Prefix?

```zsh
# Alle Alias-Dateien mit Prüfstatus
for file in terminal/.config/alias/*.alias; do
  name=$(basename "$file")
  echo "=== $name ==="
  echo -n "  Guard:   "; grep -q "command -v" "$file" && echo "✓" || echo "✗"
  echo -n "  Header:  "; grep -q "^# Zweck" "$file" && echo "✓" || echo "✗"
done
```

### 4.2 Tool-Integrationen prüfen

```zsh
# Alle Tool-Abhängigkeiten aus Alias-Dateien:
for file in terminal/.config/alias/*.alias; do
  tool=$(basename "$file" .alias)
  deps=$(grep -oE "command -v [a-z_-]+" "$file" 2>/dev/null | sed 's/command -v //' | sort -u | tr '\n' ', ' | sed 's/, $//')
  [[ -n "$deps" ]] && echo "$tool → $deps"
done
```

### 4.3 Catppuccin Theme-Konsistenz

```zsh
# Alle Farbdefinitionen finden
grep -rn "1E1E2E\|CDD6F4\|F38BA8\|A6E3A1\|CBA6F7\|89B4FA" terminal/.config/

# Zentrale Shell-Farben
cat terminal/.config/shell-colors
```

---

## Phase 5: Manuelle Verifizierung

> **Ziel:** Funktionalität testen, nicht nur Syntax.

### 5.1 Health-Check

```zsh
./scripts/health-check.sh
```

### 5.2 Alias-Tests

```zsh
# Alias-/Funktionssuche testen
fa

# Stichproben ausführen
ll
glog
brewup
```

### 5.3 fzf-Keybindings

| Keybinding | Erwartung | Testen |
|------------|-----------|--------|
| `Ctrl+X 1` | History-Suche | Manuell |
| `Ctrl+X 2` | Datei-Suche | Manuell |
| `Ctrl+X 3` | Verzeichnis-Suche | Manuell |

### 5.4 Edge-Cases

| Test | Erwartung |
|------|-----------|
| Tool nicht installiert | Guard verhindert Fehler |
| Leeres Verzeichnis | Graceful handling |
| Spezialzeichen in Pfaden | Korrekte Quotierung |

---

## Phase 6: Code-Marker und TODOs

```zsh
# Offene TODOs/FIXMEs
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.sh" --include="*.alias" --include="*.md"
```

---

## Phase 7: Review-Zusammenfassung

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

---

## Review-Abschluss

Ein Review ist abgeschlossen wenn:

1. **Verstanden** – Repository-Zustand ist klar
2. **Verifiziert** – Aussagen sind belegt (Terminal-Output, Code-Referenzen)
3. **Manuell getestet** – Kritische Funktionen wurden ausgeführt
4. **Dokumentiert** – Erkenntnisse und Empfehlungen sind strukturiert festgehalten
5. **Freigabe eingeholt** – keine Umsetzung ohne explizite Bestätigung

> **Verweise:**
> - [copilot-instructions.md](../.github/copilot-instructions.md) – Arbeitsweise, Code-Stil
> - [CONTRIBUTING.md](../CONTRIBUTING.md) – Header-Format, Stil-Regeln
