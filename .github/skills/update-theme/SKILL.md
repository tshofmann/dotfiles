---
name: update-theme
description: 'Schritt-für-Schritt Workflow um ein Upstream-Catppuccin-Theme zu aktualisieren ohne lokale Abweichungen zu verlieren: Diff-basiert (nicht Status-Tag-basiert), mit Struktur-Validierung und Doku-Nachzug.'
argument-hint: '<toolname>'
---

# Upstream-Theme aktualisieren

Aktualisiert ein Catppuccin-Theme aus dem Upstream-Repo, **ohne dokumentierte lokale Abweichungen zu verlieren**.

> **Grundprinzip (aus #445):** Die Status-Tags in der Theme-Quellen-Tabelle sind
> Kurz-Doku — **nicht** die Rekonstruktions-Quelle. Die verbindliche
> Abweichungsliste ist immer der reale Diff `Upstream ↔ lokal`. Tags und
> Kommentare werden am Ende **nachgezogen** (Doku-Output, nie Input).

## Schritt 1: Exakte Upstream-Quelle ermitteln

Zwei Stellen lesen:

1. **Theme-Quellen-Tabelle** in `terminal/.config/theme-style` (Repo + Status-Tags)
2. **`Quelle`-Feld im Header der Theme-Datei** — enthält die exakte
   Upstream-Datei in Klammern, z. B.
   `https://github.com/catppuccin/yazi (themes/mocha/catppuccin-mocha-blue.toml)`

Upstream-Repos haben oft **mehrere Varianten** (eza: 14 Akzent-Dateien,
lazygit: `themes-mergable/`, yazi: pro Flavor+Akzent). Ohne das Quelle-Feld
niemals raten — im Zweifel per Diff gegen mehrere Varianten die passende
bestimmen (kleinstes Diff gewinnt).

```zsh
curl -sL "https://raw.githubusercontent.com/catppuccin/<tool>/main/<pfad>" -o /tmp/upstream-neu
```

## Schritt 2: IST-Abweichungen messen (die Wahrheit)

Normalisierter Diff (Kommentare + Leerzeilen raus), lokale Datei ohne
Header-Block:

```zsh
diff <(grep -v '^\s*#' /tmp/upstream-neu | grep -v '^\s*$') \
     <(sed -n '/^# ====/,$p' terminal/.config/<tool>/<datei> | grep -v '^\s*#' | grep -v '^\s*$')
```

Jede Diff-Zeile ist entweder:

- **Lokale Anpassung** (z. B. Blue→Mauve Akzent) → beim Update **re-applizieren**
- **Upstream-Neuerung** (neue Keys/Features) → **übernehmen**
- **Upstream-Umbenennung** (Key umbenannt) → lokale Anpassung auf den neuen Key **portieren**

Bei Unsicherheit, ob eine Abweichung lokal-gewollt oder Upstream-Drift ist:
den Upstream-Stand zum Import-Zeitpunkt rekonstruieren (3-Wege-Vergleich):

```zsh
git log --follow --format='%ci' -- terminal/.config/<tool>/<datei> | tail -1  # Import-Datum
# Upstream-SHA zu diesem Datum:
curl -s "https://api.github.com/repos/catppuccin/<tool>/commits?path=<pfad>&until=<datum>&per_page=1" | jq -r '.[0].sha'
```

## Schritt 3: Neue Datei bauen

Reihenfolge: **Neuer Upstream als Basis**, dann jede lokale Anpassung aus
Schritt 2 einzeln anwenden. Nie umgekehrt (alte Datei + Upstream-Häppchen =
vergessene Neuerungen).

1. Header-Block der alten Datei übernehmen (Quelle-Feld ggf. aktualisieren)
2. Abweichungs-Kommentarblock im Header aktualisieren (was + warum, ohne
   Hex-Codes — Farbnamen verwenden, sonst schlägt der Palette-Test unten an)
3. Lokale Anpassungen anwenden — bei strukturierten Formaten (TOML/YAML)
   struktur-basiert ersetzen, nicht blind `sed` über die ganze Datei
   (Kollisionsgefahr: `#89b4fa` kann Akzent ODER semantische Dateityp-Farbe sein)

## Schritt 4: Validieren (hart, nicht visuell-nur)

```zsh
# 1. Palette-Reinheit: alle Hex-Farben müssen Catppuccin Mocha sein
python3 -c "
import re
mocha = {'#f5e0dc','#f2cdcd','#f5c2e7','#cba6f7','#f38ba8','#eba0ac','#fab387','#f9e2af','#a6e3a1','#94e2d5','#89dceb','#74c7ec','#89b4fa','#b4befe','#cdd6f4','#bac2de','#a6adc8','#9399b2','#7f849c','#6c7086','#585b70','#45475a','#313244','#1e1e2e','#181825','#11111b'}
colors = set(re.findall(r'#[0-9a-fA-F]{6}', open('<datei>').read()))
bad = {c for c in colors if c.lower() not in mocha}
print('ALLE Mocha' if not bad else f'FREMD: {bad}')"

# 2. Struktur-Parse mit dem echten Format
python3 -c "import tomllib; tomllib.load(open('<datei>','rb'))"   # TOML
ruby -ryaml -e 'YAML.load_file("<datei>")'                        # YAML

# 3. Tool-eigene Lade-Maschinerie (Beispiele)
kitty +runpy 'from kitty.config import load_config; import os; o=load_config(os.path.expanduser("~/.config/kitty/kitty.conf")); print(o.active_border_color)'
timeout 3 yazi --debug 2>&1 | grep -i error
lazygit --use-config-file terminal/.config/lazygit/config.yml --print-config-dir

# 4. Restdiff-Audit: diff aus Schritt 2 erneut — darf NUR noch die
#    dokumentierten Abweichungen zeigen (jede Zeile einzeln begründbar)
```

Danach visuell prüfen (Tool öffnen, Farben ansehen).

## Schritt 5: Doku nachziehen

1. **Status-Tags** in der Theme-Quellen-Tabelle (`terminal/.config/theme-style`)
   aktualisieren: neue Abweichungen ergänzen, obsolete entfernen —
   Spalten-Alignment der Tabelle wahren
2. **Quelle-Feld** im Datei-Header prüfen (Upstream-Pfad noch korrekt?)
3. `./.github/scripts/check-header-alignment.sh`
4. `./.github/scripts/generate-docs.sh --generate` — theme-style speist
   `docs/customization.md` + `catppuccin.page.md`

## Bekannte Fallen

| Falle | Beispiel |
| ----- | -------- |
| Status-Tag lügt | Terminal.app stand als `upstream`, hatte aber eingebettete Font-Config — Tag-basiertes Update hätte sie gelöscht |
| Upstream benennt Keys um | yazi `[tabs] current` → `active` — altes sed-Pattern läuft leer, Anpassung still verloren |
| Mehrere Upstream-Varianten | eza hat 14 Akzent-Dateien; „das Theme" existiert nicht |
| BSD sed | kein `\|` in BRE — Alternation braucht `-E` oder zwei Ausdrücke |
| Icon-Glyphen in sed | Nerd-Font-Glyphen sind fragil im Pattern-Match — strukturbasiert ersetzen (awk-Range, TOML-Parser) |
| Tool-Version zu alt | Neue Upstream-Keys (kitty `scrollbar_*`) erst nach Versions-Check übernehmen: `kitty +runpy '...hasattr(Options(), "scrollbar_handle_color")'` |
