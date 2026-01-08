#!/usr/bin/env zsh
# ============================================================
# architecture.sh - Generator für docs/architecture.md
# ============================================================
# Zweck   : Generiert Architektur-Dokumentation aus Verzeichnisstruktur
# Pfad    : scripts/generators/architecture.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Verzeichnisbaum generieren
# ------------------------------------------------------------
# Vereinfachter tree-Output ohne externe Abhängigkeit
generate_tree() {
    local dir="$1"
    local prefix="${2:-}"
    local output=""
    
    # Ignorierte Verzeichnisse/Dateien
    local -a ignore_patterns=('.git' '.DS_Store' 'node_modules' '__pycache__')
    
    local -a items=()
    for item in "$dir"/*(.N) "$dir"/*(/.N); do
        local name="${item:t}"
        local skip=false
        
        for pattern in "${ignore_patterns[@]}"; do
            [[ "$name" == "$pattern" ]] && skip=true && break
        done
        
        [[ "$skip" == false ]] && items+=("$item")
    done
    
    local count=${#items[@]}
    local i=0
    
    for item in "${items[@]}"; do
        (( i++ )) || true
        local name="${item:t}"
        local connector="├──"
        local next_prefix="${prefix}│   "
        
        (( i == count )) && connector="└──" && next_prefix="${prefix}    "
        
        if [[ -d "$item" ]]; then
            output+="${prefix}${connector} ${name}/\n"
            output+=$(generate_tree "$item" "$next_prefix")
        else
            output+="${prefix}${connector} ${name}\n"
        fi
    done
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Setup-Datei-Erkennung aus bootstrap.sh extrahieren
# ------------------------------------------------------------
# Extrahiert die Dateiendungen und das Erkennungs-Pattern dynamisch
generate_setup_file_detection() {
    local bootstrap="$DOTFILES_DIR/setup/bootstrap.sh"
    [[ -f "$bootstrap" ]] || return 1
    
    # Extrahiere Dateiendungen aus find-Befehlen (z.B. "*.terminal")
    local -a extensions
    extensions=($(grep -o 'find.*-name "\*\.[^"]*"' "$bootstrap" | grep -o '\*\.[^"]*' | sort -u))
    
    # Prüfe ob sort verwendet wird (deterministisch)
    local has_sort="Nein"
    grep -q 'find.*| sort |' "$bootstrap" && has_sort="Ja"
    
    # Prüfe ob Warnung bei mehreren existiert
    local has_warning="Nein"
    grep -q 'TERMINAL_COUNT\|XCODE_THEME_COUNT' "$bootstrap" && has_warning="Ja"
    
    cat << 'DETECTION_HEADER'
## Setup-Datei-Erkennung

Bootstrap erkennt Theme-Dateien automatisch nach Dateiendung:

| Dateiendung | Sortiert | Warnung bei mehreren |
|-------------|----------|----------------------|
DETECTION_HEADER

    for ext in "${extensions[@]}"; do
        # Entferne * am Anfang für Anzeige
        local display_ext="${ext#\*}"
        echo "| \`$display_ext\` | $has_sort | $has_warning |"
    done
    
    # Beispiel mit tatsächlichen Dateien aus setup/
    local example_ext="${extensions[1]#\*}"  # Erste Endung (z.B. .terminal)
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
> Änderungen an der Verzeichnisstruktur werden automatisch reflektiert.

---

## Verzeichnisstruktur

```
dotfiles/
├── README.md                    # Kurzübersicht & Quickstart
├── LICENSE                      # MIT Lizenz
├── .stowrc                      # Stow-Konfiguration
├── .gitignore                   # Git-Ignore-Patterns
├── .githooks/                   # Git Hooks (GitHub-Standard)
│   └── pre-commit               # Docs-Generierung vor Commit
├── docs/                        # Dokumentation
│   ├── installation.md          # Installationsanleitung
│   ├── configuration.md         # Anpassungen
│   ├── architecture.md          # Diese Datei
│   └── tools.md                 # Tool-Übersicht
├── scripts/                     # Utility-Scripts
│   ├── health-check.sh          # Validierung der Installation
│   ├── generate-docs.sh         # Dokumentations-Generator
│   ├── generators/              # Generator-Module
│   │   ├── lib.sh               # Gemeinsame Bibliothek
│   │   ├── tools.sh             # tools.md Generator
│   │   ├── installation.sh      # installation.md Generator
│   │   ├── architecture.sh      # architecture.md Generator
│   │   ├── configuration.sh     # configuration.md Generator
│   │   ├── readme.sh            # README.md Generator
│   │   └── tldr.sh              # tldr-Patches Generator
│   └── tests/                   # Unit-Tests
HEADER

    # Test-Dateien dynamisch auflisten
    local test_dir="$DOTFILES_DIR/scripts/tests"
    local test_count=0
    local -a test_files=()
    
    for test_file in "$test_dir"/*.sh(N); do
        [[ -f "$test_file" ]] || continue
        test_files+=("$test_file")
        (( test_count++ )) || true
    done
    
    local i=0
    for test_file in "${test_files[@]}"; do
        (( i++ )) || true
        local name="${test_file:t}"
        local desc=""
        # Beschreibung aus Header extrahieren
        desc=$(grep "^# Zweck" "$test_file" 2>/dev/null | head -1 | sed 's/^# Zweck[[:space:]]*:[[:space:]]*//')
        [[ -z "$desc" ]] && desc="Tests"
        
        local connector="│       ├──"
        (( i == test_count )) && connector="│       └──"
        
        echo "$connector $name"
    done
    
    cat << 'REST'
├── setup/
│   ├── bootstrap.sh             # Automatisiertes Setup-Skript
│   ├── Brewfile                 # Homebrew-Abhängigkeiten
│   ├── catppuccin-mocha.terminal  # Terminal.app Profil
│   └── Catppuccin Mocha.xccolortheme  # Xcode Theme
└── terminal/
    ├── .zshenv                  # Umgebungsvariablen (wird zuerst geladen)
    ├── .zprofile                # Login-Shell Konfiguration
    ├── .zshrc                   # Interactive Shell Konfiguration
    ├── .zlogin                  # Post-Login (Background-Optimierungen)
    └── .config/
REST

    # Alias-Dateien dynamisch auflisten
    echo "        ├── alias/               # Tool-Aliase"
    local alias_count=0
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        (( alias_count++ )) || true
    done
    
    local i=0
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        (( i++ )) || true
        local name="${alias_file:t}"
        local desc=$(parse_header_field "$alias_file" "Zweck")
        [[ -z "$desc" ]] && desc="${name%.alias}-Aliase"
        
        local connector="│   ├──"
        (( i == alias_count )) && connector="│   └──"
        
        echo "        $connector $name"
    done
    
    cat << 'REST'
        ├── shell-colors         # Catppuccin Mocha ANSI-Farbvariablen
        ├── bat/
        │   ├── config           # bat native Config
        │   └── themes/          # Catppuccin Mocha Theme
        ├── btop/
        │   ├── btop.conf        # btop Konfiguration
        │   └── themes/          # Catppuccin Mocha Theme
        ├── eza/
        │   └── theme.yml        # eza Catppuccin Theme
        ├── fd/
        │   └── ignore           # fd globale Ignore-Patterns
        ├── fastfetch/
        │   └── config.jsonc     # fastfetch System-Info Konfiguration
        ├── fzf/
        │   ├── config           # fzf globale Optionen
        │   ├── init.zsh         # fzf Shell-Integration
        │   └── ...              # Helper-Skripte
        ├── lazygit/
        │   └── config.yml       # lazygit Config mit Catppuccin
        ├── ripgrep/
        │   └── config           # ripgrep globale Optionen
        ├── starship.toml        # Starship Prompt-Konfiguration
        ├── tealdeer/
        │   ├── config.toml      # tealdeer Konfiguration
        │   └── pages/           # Custom tldr-Patches
        └── zsh/
            └── catppuccin_mocha-zsh-syntax-highlighting.zsh
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

REST
    
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
