#!/usr/bin/env zsh
# ============================================================
# architecture.sh - Generator für docs/architecture.md
# ============================================================
# Zweck   : Generiert Architektur-Dokumentation aus Verzeichnisstruktur
# Pfad    : scripts/generators/architecture.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Beschreibung aus Datei-Header extrahieren
# ------------------------------------------------------------
get_file_description() {
    local file="$1"
    local name="${file:t}"
    local desc=""
    
    # Versuche Beschreibung aus Header zu extrahieren
    if [[ -f "$file" ]]; then
        # 1. Shell/YAML: # Zweck : ... (nicht für Markdown, da Codeblock-Beispiele matchen könnten)
        if [[ "$name" != *.md ]]; then
            desc=$(grep -m1 "^# Zweck" "$file" 2>/dev/null | sed 's/^# Zweck[[:space:]]*:[[:space:]]*//')
        fi
        
        # 2. Shell: Zweite Zeile nach Shebang (z.B. "# description.sh - Beschreibung")
        if [[ -z "$desc" ]]; then
            desc=$(sed -n '2{s/^#[[:space:]]*//p;q}' "$file" 2>/dev/null | grep -v '^=' | grep -v '^!')
            # Extrahiere Teil nach " - " wenn vorhanden
            [[ "$desc" == *" - "* ]] && desc="${desc#* - }"
        fi
        
        # 3. Markdown: Erste Überschrift (# Titel)
        if [[ -z "$desc" && "$name" == *.md ]]; then
            desc=$(grep -m1 "^# " "$file" 2>/dev/null | sed 's/^# //')
            # Emoji am Anfang entfernen
            desc=$(echo "$desc" | sed 's/^[^ ]* //' | head -c 50)
        fi
    fi
    
    # Fallback: Nur für Dateien die KEINEN Header haben können
    # (binär, auto-generiert, oder festes Format)
    if [[ -z "$desc" ]]; then
        case "$name" in
            # Binäre/Plist-Dateien (nicht editierbar)
            *.terminal)          desc="Terminal.app Profil" ;;
            *.xccolortheme)      desc="Xcode Theme" ;;
            *.tmTheme)           desc="Syntax-Theme (XML)" ;;
            
            # Standard-Dateien mit festem Format
            LICENSE)             desc="MIT Lizenz" ;;
            
            # Auto-generierte Dateien
            *.patch.md)          desc="tldr-Patch (auto-generiert)" ;;
            
            # Generische Fallbacks nach Endung
            *.md)                desc="" ;;  # Sollte Header haben
            *.sh)                desc="" ;;  # Sollte Header haben
            *.alias)             desc="" ;;  # Sollte Header haben
            *)                   desc="" ;;
        esac
    fi
    
    echo "$desc"
}

# ------------------------------------------------------------
# Dynamischer Verzeichnisbaum
# ------------------------------------------------------------
generate_dynamic_tree() {
    local base_dir="$1"
    local prefix="${2:-}"
    local max_depth="${3:-99}"
    local current_depth="${4:-0}"
    
    # Locale für konsistente Sortierung (CI vs lokal)
    local LC_ALL=C
    
    # Tiefenlimit erreicht
    (( current_depth >= max_depth )) && return
    
    # Ignorierte Einträge
    local -a ignore=('.git' '.DS_Store' 'node_modules' '__pycache__' '.gitkeep')
    
    # Sammle alle Einträge (Dateien und Verzeichnisse)
    local -a entries=()
    
    # Versteckte (.foo) und normale Einträge sammeln
    for item in "$base_dir"/.*(N) "$base_dir"/*(N); do
        [[ -e "$item" ]] || continue
        local name="${item:t}"
        
        # Keine . und .. (ZSH glob kann diese matchen)
        [[ "$name" == "." || "$name" == ".." ]] && continue
        
        # Ignorieren?
        local skip=false
        for pattern in "${ignore[@]}"; do
            [[ "$name" == "$pattern" ]] && skip=true && break
        done
        [[ "$skip" == true ]] && continue
        
        entries+=("$item")
    done
    
    # Sortieren: Versteckte zuerst, dann alphabetisch (explizit sortiert)
    local -a sorted_entries=()
    local -a hidden_dirs=() hidden_files=() normal_dirs=() normal_files=()
    
    for e in "${entries[@]}"; do
        if [[ -d "$e" ]]; then
            [[ "${e:t}" == .* ]] && hidden_dirs+=("$e") || normal_dirs+=("$e")
        else
            [[ "${e:t}" == .* ]] && hidden_files+=("$e") || normal_files+=("$e")
        fi
    done
    
    # Explizit alphabetisch sortieren (locale-unabhängig)
    sorted_entries=(
        ${(o)hidden_dirs}
        ${(o)hidden_files}
        ${(o)normal_dirs}
        ${(o)normal_files}
    )
    
    local count=${#sorted_entries[@]}
    local i=0
    
    for item in "${sorted_entries[@]}"; do
        (( i++ )) || true
        local name="${item:t}"
        local connector="├──"
        local next_prefix="${prefix}│   "
        
        (( i == count )) && connector="└──" && next_prefix="${prefix}    "
        
        if [[ -d "$item" ]]; then
            echo "${prefix}${connector} ${name}/"
            
            # Rekursiv, aber manche Verzeichnisse nur oberflächlich
            local child_depth=$max_depth
            case "$name" in
                themes|pages) child_depth=$((current_depth + 2)) ;;  # +2 Ebenen unter diesem Verzeichnis
            esac
            generate_dynamic_tree "$item" "$next_prefix" "$child_depth" $((current_depth + 1))
        else
            local file_desc=$(get_file_description "$item")
            [[ -n "$file_desc" ]] && file_desc=" # $file_desc"
            echo "${prefix}${connector} ${name}${file_desc}"
        fi
    done
}

# ------------------------------------------------------------
# Setup-Datei-Erkennung aus bootstrap.sh extrahieren
# ------------------------------------------------------------
generate_setup_file_detection() {
    local bootstrap="$DOTFILES_DIR/setup/bootstrap.sh"
    [[ -f "$bootstrap" ]] || return 1
    
    # Extrahiere Dateiendungen aus find-Befehlen
    local -a extensions
    extensions=($(grep -o 'find.*-name "\*\.[^"]*"' "$bootstrap" | grep -o '\*\.[^"]*' | sort -u))
    
    local has_sort="Nein"
    grep -q 'find.*| sort |' "$bootstrap" && has_sort="Ja"
    
    local has_warning="Nein"
    grep -q 'TERMINAL_COUNT\|XCODE_THEME_COUNT' "$bootstrap" && has_warning="Ja"
    
    cat << 'DETECTION_HEADER'
## Setup-Datei-Erkennung

Bootstrap erkennt Theme-Dateien automatisch nach Dateiendung:

| Dateiendung | Sortiert | Warnung bei mehreren |
|-------------|----------|----------------------|
DETECTION_HEADER

    for ext in "${extensions[@]}"; do
        local display_ext="${ext#\*}"
        echo "| \`$display_ext\` | $has_sort | $has_warning |"
    done
    
    local example_ext="${extensions[1]#\*}"
    local -a example_files
    example_files=($(find "$DOTFILES_DIR/setup" -maxdepth 1 -name "*$example_ext" 2>/dev/null | sort | xargs -I{} basename {}))
    
    if (( ${#example_files[@]} > 0 )); then
        cat << EXAMPLE

**Aktuell in \`setup/\`:** \`${example_files[1]}\`
EXAMPLE
    fi
    
    cat << 'DETECTION_FOOTER'

Dies ermöglicht:
- Freie Benennung der Theme-Dateien
- Deterministisches Verhalten (alphabetisch erste bei mehreren)
- Explizite Warnung wenn mehrere Dateien existieren
DETECTION_FOOTER
}

# ------------------------------------------------------------
# Haupt-Generator für architecture.md
# ------------------------------------------------------------
generate_architecture_md() {
    cat << 'HEADER'
# 🏗️ Architektur

Technische Details zur Struktur und Funktionsweise dieses dotfiles-Repositories.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Die Verzeichnisstruktur wird dynamisch aus dem Dateisystem erzeugt.

---

## Verzeichnisstruktur

```
dotfiles/
HEADER

    # Dynamisch generierter Baum
    generate_dynamic_tree "$DOTFILES_DIR" ""
    
    cat << 'MIDDLE'
```

---

## Kern-Konzepte

### Single Source of Truth

Der Code ist die einzige Wahrheit. Alle Dokumentation wird automatisch generiert:

| Quelle | Generiert |
|--------|-----------|
| \`.alias\`-Dateien | tools.md, tldr-Patches |
| \`Brewfile\` | tools.md (CLI-Tools), setup.md |
| \`bootstrap.sh\` | setup.md |
| Config-Dateien | customization.md |
| Verzeichnisstruktur | architecture.md |

### Dokumentations-Generator

Der Generator (`scripts/generate-docs.sh`) wird automatisch via Pre-Commit Hook ausgeführt:

```zsh
# Manuell ausführen
./scripts/generate-docs.sh --generate

# Nur prüfen (CI)
./scripts/generate-docs.sh --check
```

### Guard-System

Alle `.alias`-Dateien prüfen ob das jeweilige Tool installiert ist:

```zsh
# Guard am Anfang jeder .alias-Datei
if ! command -v tool >/dev/null 2>&1; then
    return 0
fi
```

So bleiben Original-Befehle (`ls`, `cat`) erhalten wenn ein Tool fehlt.

---

## XDG Base Directory Specification

Das Setup folgt der [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

| Variable | Pfad | Verwendung |
|----------|------|------------|
| `XDG_CONFIG_HOME` | `~/.config` | Konfigurationsdateien |
| `XDG_DATA_HOME` | `~/.local/share` | Anwendungsdaten |
| `XDG_CACHE_HOME` | `~/.cache` | Cache-Dateien |

---

## Symlink-Strategie

GNU Stow mit `--no-folding` erstellt Symlinks für **Dateien**, nicht Verzeichnisse:

```zsh
# Stow mit --no-folding (via .stowrc)
stow --adopt -R terminal
```

Vorteile:
- Neue lokale Dateien werden nicht ins Repository übernommen
- Granulare Kontrolle über einzelne Dateien
- `.gitignore` in `~/.config/` bleibt erhalten

---

MIDDLE
    
    # Setup-Datei-Erkennung dynamisch aus bootstrap.sh extrahieren
    generate_setup_file_detection
    
    cat << 'DEPENDENCIES'

---

## Komponenten-Abhängigkeiten

```
Terminal.app Profil
       │
       ├── MesloLG Nerd Font ──┬── Starship Icons
       │                       └── eza Icons
       │
       └── Catppuccin Mocha ───┬── bat Theme
                               ├── fzf Colors
                               ├── btop Theme
                               ├── eza Theme
                               ├── zsh-syntax-highlighting
                               └── Xcode Theme
```

Bei Icon-Problemen (□ oder ?) prüfen:
1. Font in Terminal.app korrekt? (`catppuccin-mocha` Profil)
2. Nerd Font installiert? (`brew list --cask | grep font`)
3. Terminal neu gestartet?

---

## ZSH-Ladereihenfolge

```
.zshenv        # Immer (Umgebungsvariablen)
    │
    ├── Login-Shell?
    │       │
    │       └── .zprofile (PATH, EDITOR, etc.)
    │
    └── Interactive?
            │
            └── .zshrc (Aliase, Prompt, Keybindings)
                    │
                    └── .zlogin (Background-Tasks)
```
DEPENDENCIES
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_architecture_md || true
