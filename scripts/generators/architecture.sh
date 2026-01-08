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
        # Zweck-Feld aus Header
        desc=$(grep -m1 "^# Zweck" "$file" 2>/dev/null | sed 's/^# Zweck[[:space:]]*:[[:space:]]*//')
        
        # Oder erste Kommentarzeile nach Shebang
        if [[ -z "$desc" ]]; then
            desc=$(sed -n '2{s/^#[[:space:]]*//p;q}' "$file" 2>/dev/null | grep -v '^=')
        fi
    fi
    
    # Fallback: Bekannte Dateien
    if [[ -z "$desc" ]]; then
        case "$name" in
            README.md)           desc="Kurzübersicht & Quickstart" ;;
            LICENSE)             desc="MIT Lizenz" ;;
            CONTRIBUTING.md)     desc="Entwickler-Richtlinien" ;;
            .stowrc)             desc="Stow-Konfiguration" ;;
            .gitignore)          desc="Git-Ignore-Patterns" ;;
            .gitattributes)      desc="Git-Attribute" ;;
            pre-commit)          desc="Docs-Generierung vor Commit" ;;
            Brewfile)            desc="Homebrew-Abhängigkeiten" ;;
            bootstrap.sh)        desc="Automatisiertes Setup-Skript" ;;
            *.terminal)          desc="Terminal.app Profil" ;;
            *.xccolortheme)      desc="Xcode Theme" ;;
            .zshenv)             desc="Umgebungsvariablen (wird zuerst geladen)" ;;
            .zprofile)           desc="Login-Shell Konfiguration" ;;
            .zshrc)              desc="Interactive Shell Konfiguration" ;;
            .zlogin)             desc="Post-Login (Background-Optimierungen)" ;;
            shell-colors)        desc="Catppuccin Mocha ANSI-Farbvariablen" ;;
            config)              desc="Tool-Konfiguration" ;;
            config.toml)         desc="Tool-Konfiguration" ;;
            config.yml)          desc="Tool-Konfiguration" ;;
            config.jsonc)        desc="Tool-Konfiguration" ;;
            *.conf)              desc="Konfiguration" ;;
            *.theme)             desc="Theme-Datei" ;;
            theme.yml)           desc="Catppuccin Theme" ;;
            ignore)              desc="Ignore-Patterns" ;;
            init.zsh)            desc="Shell-Integration" ;;
            *.alias)             desc="${name%.alias}-Aliase" ;;
            *.sh)                desc="Shell-Skript" ;;
            *.md)                desc="Dokumentation" ;;
            *.patch.md)          desc="tldr-Patch" ;;
            lib.sh)              desc="Gemeinsame Bibliothek" ;;
            *)                   desc="" ;;
        esac
    fi
    
    echo "$desc"
}

# ------------------------------------------------------------
# Verzeichnis-Beschreibung
# ------------------------------------------------------------
get_dir_description() {
    local dir="$1"
    local name="${dir:t}"
    
    case "$name" in
        .githooks)    echo "Git Hooks" ;;
        .github)      echo "GitHub-Konfiguration" ;;
        ISSUE_TEMPLATE) echo "Issue-Templates" ;;
        workflows)    echo "GitHub Actions" ;;
        docs)         echo "Dokumentation" ;;
        scripts)      echo "Utility-Scripts" ;;
        generators)   echo "Generator-Module" ;;
        tests)        echo "Unit-Tests" ;;
        setup)        echo "Installation & Themes" ;;
        terminal)     echo "Shell-Konfiguration" ;;
        .config)      echo "XDG-Configs" ;;
        alias)        echo "Tool-Aliase" ;;
        themes)       echo "Theme-Dateien" ;;
        pages)        echo "tldr-Patches" ;;
        bat)          echo "bat Config" ;;
        btop)         echo "btop Config" ;;
        eza)          echo "eza Config" ;;
        fd)           echo "fd Config" ;;
        fzf)          echo "fzf Config & Helper" ;;
        fastfetch)    echo "fastfetch Config" ;;
        lazygit)      echo "lazygit Config" ;;
        ripgrep)      echo "ripgrep Config" ;;
        tealdeer)     echo "tealdeer Config" ;;
        zsh)          echo "ZSH-spezifisch" ;;
        *)            echo "" ;;
    esac
}

# ------------------------------------------------------------
# Dynamischer Verzeichnisbaum
# ------------------------------------------------------------
generate_dynamic_tree() {
    local base_dir="$1"
    local prefix="${2:-}"
    local max_depth="${3:-99}"
    local current_depth="${4:-0}"
    
    # Tiefenlimit erreicht
    (( current_depth >= max_depth )) && return
    
    # Ignorierte Einträge
    local -a ignore=('.git' '.DS_Store' 'node_modules' '__pycache__' '.gitkeep')
    
    # Sammle alle Einträge (Dateien und Verzeichnisse)
    local -a entries=()
    
    # Versteckte Dateien zuerst, dann normale (sortiert)
    for item in "$base_dir"/.(N) "$base_dir"/.*(N) "$base_dir"/*(N); do
        [[ -e "$item" ]] || continue
        local name="${item:t}"
        
        # Ignorieren?
        local skip=false
        for pattern in "${ignore[@]}"; do
            [[ "$name" == "$pattern" ]] && skip=true && break
        done
        [[ "$skip" == true ]] && continue
        
        # Keine . und .. 
        [[ "$name" == "." || "$name" == ".." ]] && continue
        
        entries+=("$item")
    done
    
    # Sortieren: Versteckte zuerst, dann alphabetisch
    local -a sorted_entries=()
    # Versteckte Verzeichnisse
    for e in "${entries[@]}"; do [[ -d "$e" && "${e:t}" == .* ]] && sorted_entries+=("$e"); done
    # Versteckte Dateien
    for e in "${entries[@]}"; do [[ -f "$e" && "${e:t}" == .* ]] && sorted_entries+=("$e"); done
    # Normale Verzeichnisse
    for e in "${entries[@]}"; do [[ -d "$e" && "${e:t}" != .* ]] && sorted_entries+=("$e"); done
    # Normale Dateien
    for e in "${entries[@]}"; do [[ -f "$e" && "${e:t}" != .* ]] && sorted_entries+=("$e"); done
    
    local count=${#sorted_entries[@]}
    local i=0
    
    for item in "${sorted_entries[@]}"; do
        (( i++ )) || true
        local name="${item:t}"
        local connector="├──"
        local next_prefix="${prefix}│   "
        
        (( i == count )) && connector="└──" && next_prefix="${prefix}    "
        
        if [[ -d "$item" ]]; then
            local dir_desc=$(get_dir_description "$item")
            [[ -n "$dir_desc" ]] && dir_desc=" # $dir_desc"
            echo "${prefix}${connector} ${name}/${dir_desc}"
            
            # Rekursiv, aber manche Verzeichnisse nur oberflächlich
            local child_depth=$max_depth
            case "$name" in
                themes|pages) child_depth=$((current_depth + 2)) ;;  # Nur 1 Ebene tief
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
| `.alias`-Dateien | tools.md, tldr-Patches |
| `Brewfile` | tools.md (CLI-Tools), installation.md |
| `bootstrap.sh` | installation.md |
| Config-Dateien | configuration.md |
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
