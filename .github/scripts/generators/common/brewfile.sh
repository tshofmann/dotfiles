#!/usr/bin/env zsh
# ============================================================
# brewfile.sh - Brewfile Parser und Sektion-Generator
# ============================================================
# Zweck       : Parst Brewfile und generiert Markdown-Tabellen
# Pfad        : .github/scripts/generators/common/brewfile.sh
# ============================================================

# Abhängigkeit: config.sh muss vorher geladen sein

# ------------------------------------------------------------
# Parser: Brewfile
# ------------------------------------------------------------
# Extrahiert Tool-Name, Beschreibung und URL
# Format: brew "name"                # Beschreibung | URL
#         mas "name", id: 123456     # Beschreibung (URL wird aus ID generiert)
# Rückgabe: name|beschreibung|typ|url (brew/cask/mas)
parse_brewfile_entry() {
    local line="$1"
    local name description typ url

    case "$line" in
        brew\ *)
            typ="brew"
            name="${line#brew \"}"
            name="${name%%\"*}"
            ;;
        cask\ *)
            typ="cask"
            name="${line#cask \"}"
            name="${name%%\"*}"
            ;;
        mas\ *)
            typ="mas"
            name="${line#mas \"}"
            name="${name%%\"*}"
            # ID extrahieren und App Store URL generieren
            if [[ "$line" =~ id:[[:space:]]*([0-9]+) ]]; then
                url="https://apps.apple.com/app/id${match[1]}"
            fi
            ;;
        *)
            return 1
            ;;
    esac

    # Beschreibung und URL aus Kommentar (Format: # Beschreibung | URL)
    # MAS-Apps haben bereits URL aus ID, überschreibe nur wenn explizit angegeben
    if [[ "$line" == *"#"* ]]; then
        local comment="${line#*# }"
        if [[ "$comment" == *" | "* ]]; then
            description="${comment%% | *}"
            # Explizite URL überschreibt generierte
            url="${comment##* | }"
        else
            description="$comment"
            # url bleibt wie gesetzt (leer oder aus MAS-ID)
        fi
    else
        description=""
    fi

    echo "${name}|${description}|${typ}|${url}"
}

# ------------------------------------------------------------
# Brewfile-Sektion generieren (respektiert Kategorien)
# ------------------------------------------------------------
# Parst Kategorie-Kommentare aus Brewfile und gruppiert Pakete
# Format im Brewfile: # Kategorie-Name (einzelne Zeile)
generate_brewfile_section() {
    local current_category=""
    local table_started=false
    local header_end_count=0

    while IFS= read -r line; do
        # Header-Block: Alles bis zur letzten ====== Zeile überspringen (4 Stück)
        if [[ "$line" == "# ===="* ]]; then
            (( header_end_count++ )) || true
            continue
        fi

        # Solange wir nicht alle 4x ====== gesehen haben, Header überspringen
        if (( header_end_count < 4 )); then
            continue
        fi

        # Leere Zeilen überspringen
        [[ -z "$line" ]] && continue

        # Kategorie-Kommentar erkennen (# Kategoriename)
        if [[ "$line" == "# "* ]]; then
            local category="${line#\# }"
            # Nur wenn es eine echte Kategorie ist (keine URL, kein Kommentar zu Paketen)
            if [[ "$category" != *"http"* && "$category" != *"|"* && ${#category} -lt 40 ]]; then
                # Neue Kategorie – Tabelle abschließen falls offen
                if $table_started; then
                    echo ""
                fi
                current_category="$category"
                echo "### $current_category"
                echo ""
                echo "| Paket | Beschreibung |"
                echo "| ----- | ------------ |"
                table_started=true
                continue
            fi
        fi

        # Paket-Zeilen parsen
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue

        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        rest="${rest#*|}"
        local typ="${rest%%|*}"
        local url="${rest#*|}"

        # Formatierung nach Typ – mit Link falls URL vorhanden
        case "$typ" in
            brew|cask)
                if [[ -n "$url" ]]; then
                    echo "| [\`$name\`]($url) | $desc |"
                else
                    echo "| \`$name\` | $desc |"
                fi
                ;;
            mas)
                if [[ -n "$url" ]]; then
                    echo "| [$name]($url) | $desc |"
                else
                    echo "| $name | $desc |"
                fi
                ;;
        esac
    done < "$BREWFILE"

    echo ""
    echo '> **Hinweis:** Die Anmeldung im App Store muss manuell erfolgen – die Befehle `mas account` und `mas signin` sind auf macOS 12+ nicht verfügbar.'

    # Technische Details
    cat << 'TECH'

---

## Technische Details

### XDG Base Directory Specification

Das Setup folgt der [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

| Variable | Pfad | Verwendung |
| -------- | ---- | ---------- |
| `XDG_CONFIG_HOME` | `~/.config` | Konfigurationsdateien |
| `XDG_DATA_HOME` | `~/.local/share` | Anwendungsdaten |
| `XDG_CACHE_HOME` | `~/.cache` | Cache-Dateien |

### Symlink-Strategie

GNU Stow mit `--no-folding` erstellt Symlinks für **Dateien**, nicht Verzeichnisse:

```zsh
# Stow mit --no-folding (via .stowrc)
stow --adopt -R terminal editor
```

Vorteile:

- Neue lokale Dateien werden nicht ins Repository übernommen
- Granulare Kontrolle über einzelne Dateien
- `.gitignore` in `~/.config/` bleibt erhalten

### Setup-Datei-Erkennung

Bootstrap erkennt Theme-Dateien automatisch nach Dateiendung:

| Dateiendung | Sortiert | Warnung bei mehreren |
| ----------- | -------- | -------------------- |
| `.terminal` | Ja | Ja |
| `.xccolortheme` | Ja | Ja |

Dies ermöglicht:

- Freie Benennung der Theme-Dateien
- Deterministisches Verhalten (alphabetisch erste bei mehreren)
- Explizite Warnung wenn mehrere Dateien existieren

---

## Troubleshooting

### Icon-Probleme (□ oder ?)

Bei fehlenden oder falschen Icons prüfen:

1. **Font in Terminal.app korrekt?** – `catppuccin-mocha` Profil muss MesloLG Nerd Font verwenden
2. **Nerd Font installiert?** – `brew list --cask | grep font`
3. **Terminal neu gestartet?** – Nach Font-Installation erforderlich
TECH
}
