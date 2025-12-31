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
- **Validatoren sind Hilfsmittel, nicht Wahrheit** – kritisch hinterfragen
- **Beweispflicht** – jede Aussage mit Beleg (Code, Terminal-Output, Doku)
- **Bei Unklarheiten**: Rückfrage statt Annahme

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
- [ ] Fehlen Verzeichnisse/Dateien in `docs/architecture.md`, die im Code existieren?
- [ ] Gibt es Alias-Dateien in `terminal/.config/alias/`, die nicht dokumentiert sind?
- [ ] Referenziert die Doku Dateien, die nicht mehr existieren?

### 1.2 Einstiegspunkte identifizieren

```zsh
# Alle Shell-Konfigurationsdateien finden (dynamisch)
ls -la terminal/.zsh* setup/bootstrap.sh

# Ladereihenfolge prüfen (zsh-spezifisch):
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

**Doku-Lücken finden (Code ist Wahrheit):**
```zsh
# Prüfen: Sind alle Brewfile-Tools in tools.md dokumentiert?
for tool in $(grep '^brew "' setup/Brewfile | sed 's/brew "\([^"]*\)".*/\1/'); do
  grep -qi "$tool" docs/tools.md || echo "FEHLT in tools.md: $tool"
done

# Prüfen: Stimmen die Zahlen in architecture.md?
echo "Brewfile: $(grep '^brew ' setup/Brewfile | wc -l | tr -d ' ') brew, $(grep '^cask ' setup/Brewfile | wc -l | tr -d ' ') cask, $(grep '^mas ' setup/Brewfile | wc -l | tr -d ' ') mas"
grep -E "brew.*:|cask.*:|mas.*:" docs/architecture.md
```

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

**Struktur-Checks (siehe CONTRIBUTING.md → "Header-Block Format"):**
- [ ] Header-Block mit Metadaten (Zweck, Pfad, Docs)?
- [ ] Guard-Check vorhanden (`command -v tool >/dev/null`)?
- [ ] Beschreibungskommentare für Help-System?
- [ ] Private Funktionen mit `_` Prefix?

**Stil-Checks (siehe CONTRIBUTING.md → "Stil-Regeln"):**
- [ ] Metadaten 8 Zeichen breit, linksbündig?
- [ ] Sektions-Trenner 60 Zeichen?
- [ ] Lokale Variablen mit `local`?

```zsh
# Automatische Stil-Prüfung
./scripts/validate-docs.sh --extended
```

### 3.2 Tool-Integrationen prüfen

Jedes Tool hat Abhängigkeiten zu anderen Tools. Diese müssen funktionieren:

```zsh
# Tool-Namen aus Brewfile extrahieren (dynamisch)
tools=$(grep '^brew "' setup/Brewfile | sed 's/brew "\([^"]*\)".*/\1/' | tr '\n' '|' | sed 's/|$//')
# Alle Tool-Referenzen in Alias-Dateien finden
grep -rn "command -v\|$tools" terminal/.config/alias/*.alias | head -30
```

**Tool-Integrationen dynamisch ermitteln:**

```zsh
# Alle Tools aus Brewfile mit ihren Integrationen:
for tool in $(grep '^brew "' setup/Brewfile | sed 's/brew "\([^"]*\)".*/\1/'); do
  echo "=== $tool ==="
  # Wo wird dieses Tool referenziert?
  refs=$(grep -rln "$tool" terminal/.config/alias/*.alias terminal/.zshrc 2>/dev/null | xargs -I {} basename {} 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/, $//')
  echo "  Referenziert in: ${refs:--}"
  # Welche anderen Tools referenziert es (falls Alias-Datei existiert)?
  if [[ -f "terminal/.config/alias/${tool}.alias" ]]; then
    deps=$(grep -oE "command -v [a-z_-]+" "terminal/.config/alias/${tool}.alias" 2>/dev/null | sed 's/command -v //' | sort -u | tr '\n' ', ' | sed 's/, $//')
    echo "  Nutzt: ${deps:--}"
  fi
done
```

**Für jede Integration prüfen:**
- [ ] Fallback wenn Abhängigkeit fehlt?
- [ ] Preview-Commands: ZSH-Syntax gewrappt? (siehe copilot-instructions.md → "Bekannte Patterns")
- [ ] Catppuccin-Farben konsistent? (siehe copilot-instructions.md → "Catppuccin Mocha Farben")
- [ ] Keybinding-Header im Format `Key: Aktion | Key: Aktion`?

**Synergie-Potenzial ermitteln:**

> **Ziel:** Ungenutzte Kombinationen finden, die Mehrwert bieten könnten.

```zsh
# 1. Bestehende Tool-Abhängigkeiten aus Code:
echo "=== Bestehende Integrationen ==="
for file in terminal/.config/alias/*.alias; do
  tool=$(basename "$file" .alias)
  deps=$(grep -oE "command -v [a-z_-]+" "$file" 2>/dev/null | sed 's/command -v //' | sort -u | tr '\n' ', ' | sed 's/, $//')
  [[ -n "$deps" ]] && echo "$tool → $deps"
done

# 2. Tools OHNE fzf-Integration (Potenzial?):
echo ""
echo "=== Potenzielle fzf-Integrationen ==="
for tool in $(grep '^brew "' setup/Brewfile | sed 's/brew "\([^"]*\)".*/\1/'); do
  # Prüfen ob in fzf.alias ODER als fzf-Funktion woanders
  if ! grep -rq "$tool" terminal/.config/alias/fzf.alias 2>/dev/null; then
    if ! grep -rq "fzf.*$tool\|$tool.*fzf" terminal/.config/alias/*.alias 2>/dev/null; then
      echo "$tool – keine fzf-Integration"
    fi
  fi
done

# 3. Alias-Dateien OHNE bat-Preview (cat statt bat?):
echo ""
echo "=== Alias-Dateien ohne bat-Preview ==="
for file in terminal/.config/alias/*.alias; do
  if grep -q "preview" "$file" 2>/dev/null; then
    if ! grep -q "bat" "$file" 2>/dev/null; then
      echo "$(basename "$file") – hat Previews aber nutzt nicht bat"
    fi
  fi
done
grep -rn "cat " terminal/.config/alias/*.alias | grep -v "# " | head -5 && echo "  ↑ cat statt bat?"

# 4. Tools OHNE Catppuccin-Theme:
echo ""
echo "=== Config-Verzeichnisse ohne Theme ==="
for dir in terminal/.config/*/; do
  if ! grep -rqi "catppuccin\|theme\|color\|#[0-9A-Fa-f]\{6\}" "$dir" 2>/dev/null; then
    echo "$(basename "$dir") – kein Theme gefunden"
  fi
done

# 5. Doppelte Funktionalität finden:
echo ""
echo "=== Mögliche Duplikate ==="
# Aliase die auf dasselbe Kommando zeigen
grep -h "^alias" terminal/.config/alias/*.alias | sed 's/alias \([^=]*\)=.*/\1/' | sort | uniq -d

# 6. Häufige Workflows ohne Keybinding/Alias:
echo ""
echo "=== Häufige Patterns ohne Alias ==="
# Git-Operationen die häufig sind aber evtl. keinen Alias haben
for cmd in "git stash" "git rebase" "git cherry-pick" "git bisect"; do
  grep -rq "${cmd##* }" terminal/.config/alias/git.alias 2>/dev/null || echo "$cmd – kein Alias?"
done
```

**Fragen zur Synergie-Analyse:**
- [ ] Gibt es Tools ohne fzf-Integration, wo sie sinnvoll wäre?
- [ ] Nutzen alle Preview-Commands bat (statt cat)?
- [ ] Haben alle Tools mit Theme-Support Catppuccin konfiguriert?
- [ ] Gibt es doppelte Funktionalität (z.B. zwei Aliase für dasselbe)?
- [ ] Fehlen Keybindings für häufige Workflows?
- [ ] Wird eza überall für Directory-Listings verwendet (nicht ls)?

### 3.3 XDG-Konformität

```zsh
# Alle XDG- und Config-Variablen dynamisch finden:
grep -E "XDG_|_CONFIG|_PATH|_DIR" terminal/.zshenv terminal/.zshrc 2>/dev/null | grep -v "^#"

# Für jedes Config-Verzeichnis prüfen ob XDG-konform:
for dir in terminal/.config/*/; do
  tool=$(basename "$dir")
  echo -n "$tool: "
  # Prüfen ob Tool eine spezielle Config-Variable braucht
  grep -rqi "${tool}.*config\|${tool}.*dir\|${tool}.*path" terminal/.zshenv terminal/.zshrc 2>/dev/null && echo "✓ Variable gesetzt" || echo "– (XDG-Standard oder keine Variable nötig)"
done
```

**Prüfen:**
- [ ] Alle Tools nutzen `~/.config/` (nicht `~/Library/Application Support`)?
- [ ] Config-Pfade in Alias-Dateien korrekt?

---

## Phase 4: Dokumentations-Synchronisation

> **Ziel:** Code ist die Wahrheit – Doku muss dem Code entsprechen, nicht umgekehrt.

### 4.1 Automatische Validierung

```zsh
# Vollständige Validierung
./scripts/validate-docs.sh

# Kern-Validierungen
./scripts/validate-docs.sh --core

# Erweiterte Prüfungen
./scripts/validate-docs.sh --extended
```

### 4.2 Code → Doku Abgleich (manuell)

**Prinzip:** Für jede Code-Komponente prüfen, ob die Doku aktuell ist.

```zsh
# Alle Markdown-Dateien die geprüft werden müssen
find . -maxdepth 1 -name "*.md" -type f
find docs/ -name "*.md" -type f
```

| Code-Quelle | Doku prüfen | Befehl zum Abgleich |
|-------------|-------------|---------------------|
| `setup/Brewfile` | tools.md, architecture.md | `grep '^brew "' setup/Brewfile` vs. Doku |
| `terminal/.config/alias/*.alias` | tools.md (Aliase) | `grep -h '^alias' terminal/.config/alias/*.alias` |
| `terminal/.config/*/` | architecture.md (Struktur) | `ls terminal/.config/` vs. Doku |
| `setup/bootstrap.sh` | installation.md (Schritte) | Bootstrap-Schritte im Code zählen |
| `terminal/.zsh*` | configuration.md | Geladene Plugins/Tools prüfen |
| Alias-Header | CONTRIBUTING.md | Header-Format im Code vs. Doku |

**Konkrete Lücken-Suche:**

```zsh
# Neue Tools im Brewfile die nicht dokumentiert sind?
for tool in $(grep '^brew "' setup/Brewfile | sed 's/brew "\([^"]*\)".*/\1/'); do
  grep -qi "$tool" docs/tools.md || echo "⚠ $tool nicht in tools.md"
done

# Neue Alias-Dateien die nicht dokumentiert sind?
for file in terminal/.config/alias/*.alias; do
  name=$(basename "$file" .alias)
  grep -qi "$name" docs/tools.md || echo "⚠ $name.alias nicht in tools.md"
done

# Neue Config-Verzeichnisse die nicht dokumentiert sind?
for dir in terminal/.config/*/; do
  name=$(basename "$dir")
  grep -qi "$name" docs/architecture.md || echo "⚠ $name/ nicht in architecture.md"
done
```

### 4.3 Code-Marker finden

```zsh
# Offene TODOs/FIXMEs
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.sh" --include="*.alias" --include="*.md"
```

---

## Phase 5: Tool-Integrationen gründlich prüfen

> **Ziel:** Jede Integration manuell verifizieren – Code lesen UND ausführen.

### 5.1 Systematische Tool-Prüfung

**Für JEDES Tool aus dem Brewfile durchführen:**

```zsh
# Alle Tools auflisten
grep '^brew "' setup/Brewfile | sed 's/brew "\([^"]*\)".*/\1/'
```

**Pro Tool prüfen:**

| Aspekt | Prüfbefehl | Erwartung |
|--------|------------|-----------|
| Installiert? | `command -v <tool>` | Exit 0 |
| Alias-Datei? | `ls terminal/.config/alias/<tool>.alias` | Existiert oder bewusst nicht |
| Config-Datei? | `ls terminal/.config/<tool>/` | XDG-konform |
| .zshrc-Integration? | `grep -n "<tool>" terminal/.zshrc` | Init/Eval vorhanden |
| Dokumentiert? | `grep -n "<tool>" docs/tools.md` | Beschrieben |
| Theme-Support? | `find terminal/.config/<tool> -name "*theme*" 2>/dev/null` | Catppuccin Mocha falls vorhanden |

```zsh
# Automatisierte Prüfung für alle Tools:
for tool in $(grep '^brew "' setup/Brewfile | sed 's/brew "\([^"]*\)".*/\1/'); do
  echo "=== $tool ==="
  echo -n "  Installiert: "; command -v "$tool" >/dev/null && echo "✓" || echo "✗"
  echo -n "  Alias-Datei: "; [[ -f "terminal/.config/alias/${tool}.alias" ]] && echo "✓" || echo "–"
  echo -n "  Config-Dir:  "; [[ -d "terminal/.config/${tool}" ]] && echo "✓" || echo "–"
  echo -n "  In .zshrc:   "; grep -q "$tool" terminal/.zshrc && echo "✓" || echo "–"
  echo -n "  In tools.md: "; grep -qi "$tool" docs/tools.md && echo "✓" || echo "–"
  echo -n "  Theme:       "; find "terminal/.config/${tool}" -name "*theme*" -o -name "*catppuccin*" 2>/dev/null | grep -q . && echo "✓ Catppuccin" || echo "–"
done
```

### 5.2 Tool-spezifische Integrationen

**Dynamische Prüfung – für jedes Tool mit Alias-Datei:**

```zsh
# Alle Alias-Dateien durchgehen und Prüfpunkte generieren:
for file in terminal/.config/alias/*.alias; do
  tool=$(basename "$file" .alias)
  echo "=== $tool ==="
  
  # 1. Welche Abhängigkeiten hat dieses Tool?
  echo "  Abhängigkeiten:"
  grep -oE "command -v [a-z_-]+" "$file" 2>/dev/null | sed 's/command -v /    /'
  
  # 2. Wo wird es in .zshrc integriert?
  echo "  .zshrc-Integration:"
  grep -n "$tool" terminal/.zshrc 2>/dev/null | sed 's/^/    /' | head -3
  
  # 3. Welche Umgebungsvariablen?
  echo "  Umgebungsvariablen:"
  grep -E "^export.*${(U)tool}" terminal/.zshenv terminal/.zshrc 2>/dev/null | sed 's/^/    /'
  
  # 4. Hat es Previews?
  echo "  Previews:"
  grep -c "preview" "$file" 2>/dev/null | xargs -I {} echo "    {} Preview-Definitionen"
done
```

**Manuelle Verifikation pro Tool (im Terminal testen):**
- [ ] Funktionieren alle Aliase/Funktionen?
- [ ] Previews korrekt (bat/eza statt cat)?
- [ ] Keybindings wo erwartet?
- [ ] Fallback bei fehlender Abhängigkeit?

### 5.3 Catppuccin Theme-Konsistenz

**Kritisch:** Gleiche Farben müssen überall verwendet werden.

> **Farbpalette:** Siehe [copilot-instructions.md](../.github/copilot-instructions.md) → "Catppuccin Mocha Farben"

```zsh
# Alle Farbdefinitionen finden
grep -rn "1E1E2E\|CDD6F4\|F38BA8\|A6E3A1\|CBA6F7\|89B4FA" terminal/.config/
grep -rn "Mauve\|Sky\|Green\|Red\|Yellow" terminal/.config/alias/help.alias

# Alle Theme-Konfigurationen auflisten
find terminal/.config \( -name "*theme*" -o -name "*catppuccin*" \) 2>/dev/null
```

**Tools mit Theme-Support dynamisch finden:**

```zsh
# Alle Theme-Dateien im Config-Verzeichnis:
echo "=== Theme-Dateien ==="
find terminal/.config -type f \( -name "*theme*" -o -name "*color*" -o -name "*.yml" -o -name "*.toml" \) 2>/dev/null

# Catppuccin-Referenzen prüfen:
echo ""
echo "=== Catppuccin-Referenzen ==="
grep -rln -i "catppuccin\|mocha\|1E1E2E" terminal/.config/ setup/*.terminal 2>/dev/null

# Tools MIT Config aber OHNE Theme:
echo ""
echo "=== Config ohne Theme-Referenz ==="
for dir in terminal/.config/*/; do
  tool=$(basename "$dir")
  if ! grep -rqi "catppuccin\|theme\|color" "$dir" 2>/dev/null; then
    echo "$tool – kein Theme gefunden"
  fi
done
```

**Für jede gefundene Theme-Datei prüfen:**
- [ ] Catppuccin Mocha korrekt konfiguriert?
- [ ] Farben konsistent mit anderen Tools?

### 5.4 XDG-Pfade tatsächlich verifizieren

**Nicht nur Variablen prüfen – tatsächliche Symlinks:**

```zsh
# Alle XDG-Variablen aus .zshenv/.zshrc
grep -E "XDG_|_CONFIG_DIR|_CONFIG_PATH|_OPTS_FILE" terminal/.zsh*

# Dynamisch alle Config-Verzeichnisse prüfen:
for dir in terminal/.config/*/; do
  tool=$(basename "$dir")
  target="$HOME/.config/$tool"
  echo -n "$tool: "
  if [[ -L "$target" ]]; then
    local link_target
    link_target=$(readlink "$target" 2>/dev/null)
    [[ -n "$link_target" ]] && echo "✓ Symlink → $link_target" || echo "⚠ Defekter Symlink"
  elif [[ -d "$target" ]]; then
    echo "⚠ Verzeichnis (kein Symlink)"
  else
    echo "✗ Nicht vorhanden"
  fi
done
```

Manuell prüfen:
- [ ] Jede Variable zeigt auf existierenden Symlink?
- [ ] Symlink zeigt in dotfiles-Repo (nicht Kopie)?
- [ ] Tools laden Config tatsächlich von dort?

```zsh
# Verifizieren dass Tools ihre Config laden:
bat --config-file
rg --version  # Zeigt config path
eza --version  # Prüfen ob Icons/Farben korrekt
```

### 5.5 Alle Alias-Dateien einzeln prüfen

**Dynamisch alle Alias-Dateien auflisten und prüfen:**

```zsh
# Alle Alias-Dateien mit Prüfstatus
for file in terminal/.config/alias/*.alias; do
  name=$(basename "$file")
  echo "=== $name ==="
  echo -n "  Guard:      "; grep -q "command -v" "$file" && echo "✓" || echo "✗"
  echo -n "  Header:     "; grep -q "^# Zweck" "$file" && echo "✓" || echo "✗"
  echo -n "  Previews:   "; grep -q "preview" "$file" && echo "hat Previews" || echo "–"
  echo -n "  Catppuccin: "; grep -qE "#[0-9A-Fa-f]{6}|Mauve|Sky" "$file" && echo "hat Farben" || echo "–"
done
```

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

## Review-Abschluss

Ein Review ist abgeschlossen wenn:

1. **Verstanden** – Repository-Zustand ist klar, nicht nur oberflächlich geprüft
2. **Verifiziert** – Aussagen sind belegt (Terminal-Output, Code-Referenzen)
3. **Dokumentiert** – Erkenntnisse und Empfehlungen sind strukturiert festgehalten
4. **Freigabe eingeholt** – keine Umsetzung ohne explizite Bestätigung

Welche Validierungen und Prüfungen dafür nötig sind, ergibt sich aus dem Review-Kontext. Tools in `scripts/` können helfen – aber kritisch einsetzen, nicht blind vertrauen.

> **Verweise:**
> - [copilot-instructions.md](../.github/copilot-instructions.md) – Arbeitsweise, Code-Stil
> - [CONTRIBUTING.md](../CONTRIBUTING.md) – Header-Format, Stil-Regeln
