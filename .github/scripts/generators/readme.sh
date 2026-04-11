#!/usr/bin/env zsh
# ============================================================
# readme.sh - Generator für README.md
# ============================================================
# Zweck       : Generiert Haupt-README aus Template + dynamischen Daten
# Pfad        : .github/scripts/generators/readme.sh
# Quelle      : setup/modules/*.sh, setup/Brewfile
# ============================================================

source "${0:A:h}/common.sh"

# ------------------------------------------------------------
# Helper: Tool-Ersetzungen aus .alias-Dateien extrahieren
# ------------------------------------------------------------
# Parst "# Ersetzt : original (beschreibung)" aus allen .alias-Dateien
generate_tool_replacements_table() {
    local -A replacements=()

    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local tool_name=$(basename "$alias_file" .alias)
        local ersetzt=$(parse_header_field "$alias_file" "Ersetzt")

        # Format: "original (beschreibung)" → extrahiere beides
        if [[ -n "$ersetzt" && "$ersetzt" == *"("* ]]; then
            local original="${ersetzt%% \(*}"
            local desc="${ersetzt#*\(}"
            desc="${desc%\)}"
            replacements[$original]="${tool_name}|${desc}"
        fi
    done

    # Sortiert ausgeben
    echo "| Vorher | Nachher | Vorteil |"
    echo "| ------ | ------- | ------- |"
    for original in ${(ko)replacements}; do
        local data="${replacements[$original]}"
        local tool="${data%%|*}"
        local desc="${data#*|}"
        echo "| \`${original}\` | \`${tool}\` | ${desc} |"
    done
}

# ------------------------------------------------------------
# Helper: fzf-Funktionsnamen aus einer .alias-Datei extrahieren
# ------------------------------------------------------------
# Liest "# Aliase"-Header und filtert Funktionen die fzf nutzen.
# fzf-Erkennung: Sucht "fzf" zwischen Funktionsstart und passender schließender } (per Brace-Depth, inkl. verschachtelter Blöcke)
extract_fzf_functions() {
    local alias_file="$1"
    local is_fzf_file="$2"  # "1" wenn Datei selbst das fzf-Tool ist
    local aliase=$(parse_header_field "$alias_file" "Aliase")
    local -a funcs=()

    # Alle Namen aus Aliase-Header
    local -a names=("${(@s:, :)aliase}")

    for name in "${names[@]}"; do
        [[ -z "$name" ]] && continue
        # Nur Funktionen mit () { im Code
        if grep -q "^[[:space:]]*${name}() {" "$alias_file" 2>/dev/null; then
            if [[ "$is_fzf_file" == "1" ]]; then
                # fzf.alias: alle Funktionen sind fzf-Workflows
                funcs+=("$name")
            else
                # Andere Dateien: Prüfe ob fzf im Bereich der Funktion aufgerufen wird
                # awk mit Brace-Zähler: Trackt { und } um verschachtelte Blöcke korrekt zu handhaben
                local has_fzf=$(awk -v fname="$name" '
                    $0 ~ "^[[:space:]]*" fname "\\(\\) \\{" { found=1; depth=0 }
                    found {
                        for (i=1; i<=length($0); i++) {
                            c = substr($0, i, 1)
                            if (c == "{") depth++
                            else if (c == "}") depth--
                        }
                        if (/fzf/) count++
                        if (depth <= 0 && NR > 1) { found=0 }
                    }
                    END { print count+0 }
                ' "$alias_file")
                [[ "$has_fzf" -gt 0 ]] && funcs+=("$name")
            fi
        fi
    done

    echo "${(j:, :)funcs}"
}

# ------------------------------------------------------------
# Helper: Interaktive fzf-Workflows als Tabelle
# ------------------------------------------------------------
# Gruppiert fzf-Funktionen nach Bereich, extrahiert aus # Nutzt + # Aliase
generate_fzf_workflows_table() {
    # Bereich → Alias-Dateiname (Reihenfolge = Tabellenreihenfolge)
    local -a categories=(
        "Git|git"
        "GitHub|gh"
        "System|fzf"
        "Navigation|fd,zoxide"
        "Suche|rg"
        "Pakete|brew"
        "Archive|7z"
        "Konfiguration|bat,dotfiles"
    )

    echo "| Bereich | Funktionen |"
    echo "| ------- | ---------- |"

    for entry in "${categories[@]}"; do
        local label="${entry%%|*}"
        local files_str="${entry#*|}"
        local -a file_names=("${(@s:,:)files_str}")
        local -a all_funcs=()

        for fname in "${file_names[@]}"; do
            local alias_file="$ALIAS_DIR/${fname}.alias"
            [[ -f "$alias_file" ]] || continue

            # Prüfe ob fzf genutzt wird (fzf.alias ist selbst das fzf-Tool)
            local nutzt=$(parse_header_field "$alias_file" "Nutzt")
            [[ "$fname" != "fzf" && "$nutzt" != *fzf* ]] && continue

            local is_fzf_file="0"
            [[ "$fname" == "fzf" ]] && is_fzf_file="1"
            local funcs=$(extract_fzf_functions "$alias_file" "$is_fzf_file")
            [[ -n "$funcs" ]] && all_funcs+=("${(@s:, :)funcs}")
        done

        [[ ${#all_funcs[@]} -eq 0 ]] && continue

        # Backtick-formatiert
        local formatted=""
        for func in "${all_funcs[@]}"; do
            [[ -n "$formatted" ]] && formatted+=", "
            formatted+="\`${func}\`"
        done

        echo "| ${label} | ${formatted} |"
    done
}

# ------------------------------------------------------------
# Helper: Media-Toolkit als Tabelle
# ------------------------------------------------------------
# Extrahiert Aliase/Funktionen aus Media-bezogenen .alias-Dateien
generate_media_toolkit_table() {
    local -a media_files=("exiftool" "ffmpeg" "magick" "poppler" "resvg")

    echo "| Tool | Funktionen |"
    echo "| ---- | ---------- |"

    for fname in "${media_files[@]}"; do
        local alias_file="$ALIAS_DIR/${fname}.alias"
        [[ -f "$alias_file" ]] || continue

        local aliase=$(parse_header_field "$alias_file" "Aliase")
        [[ -z "$aliase" ]] && continue

        # Backtick-formatiert
        local formatted=""
        local -a names=("${(@s:, :)aliase}")
        for name in "${names[@]}"; do
            [[ -z "$name" ]] && continue
            [[ -n "$formatted" ]] && formatted+=", "
            formatted+="\`${name}\`"
        done

        echo "| ${fname} | ${formatted} |"
    done
}

# ------------------------------------------------------------
# Helper: Shell-Keybindings aus fzf/init.zsh extrahieren
# ------------------------------------------------------------
# Parst "bindkey '^Xn' widget  # Ctrl+X n = Beschreibung" Zeilen
generate_shell_keybindings_table() {
    local init_file="$FZF_DIR/init.zsh"
    [[ -f "$init_file" ]] || return 0

    echo "| Keybinding | Funktion |"
    echo "| ---------- | -------- |"

    grep -E "^bindkey '\\^X[0-9]'" "$init_file" | while IFS= read -r line; do
        local comment="${line#*# }"
        local keybinding="${comment%% =*}"
        local description="${comment#*= }"
        echo "| \`${keybinding}\` | ${description} |"
    done || true
}

# ------------------------------------------------------------
# Helper: Utility-Werkzeuge als Tabelle
# ------------------------------------------------------------
# Listet Aliase aus explizit gewählten Utility-Tool-Dateien (Whitelist)
generate_utility_tools_table() {
    local -a utility_files=("markdownlint")

    echo "| Tool | Funktionen |"
    echo "| ---- | ---------- |"

    for fname in "${utility_files[@]}"; do
        local alias_file="$ALIAS_DIR/${fname}.alias"
        [[ -f "$alias_file" ]] || continue

        local aliase=$(parse_header_field "$alias_file" "Aliase")
        [[ -z "$aliase" ]] && continue

        local formatted=""
        local -a names=("${(@s:, :)aliase}")
        for name in "${names[@]}"; do
            [[ -z "$name" ]] && continue
            [[ -n "$formatted" ]] && formatted+=", "
            formatted+="\`${name}\`"
        done

        echo "| ${fname} | ${formatted} |"
    done
}

# ------------------------------------------------------------
# Haupt-Generator für README.md
# ------------------------------------------------------------
# heading_to_anchor() und generate_toc() kommen aus common/toc.sh
generate_readme_md() {
    # Dynamische macOS-Versionen aus setup/modules/validation.sh
    local macos_min macos_min_name
    macos_min=$(extract_macos_min_version)
    macos_min_name=$(get_macos_codename "$macos_min")
    # URL-Encoding für Badge (Leerzeichen im Codenamen, z.B. "Big Sur")
    local macos_min_name_url="${macos_min_name// /%20}"

    # Tool-Ersetzungen dynamisch generieren
    local tool_replacements=$(generate_tool_replacements_table)
    local fzf_workflows=$(generate_fzf_workflows_table)
    local media_toolkit=$(generate_media_toolkit_table)
    local shell_keybindings=$(generate_shell_keybindings_table)
    local utility_tools=$(generate_utility_tools_table)

    # Homebrew-Check-Intervall aus check.conf (SSOT)
    local brew_check_conf="$DOTFILES_DIR/terminal/.config/homebrew/check.conf"
    local brew_interval_hours="12"
    if [[ -f "$brew_check_conf" ]]; then
        local interval_secs
        interval_secs=$(grep -m1 '^_BREW_CHECK_INTERVAL=' "$brew_check_conf" | cut -d= -f2) || true
        if [[ -n "$interval_secs" ]] && (( interval_secs % 3600 == 0 )); then
            brew_interval_hours=$(( interval_secs / 3600 ))
        fi
    fi

    # Hero-Screenshot bedingt einbinden (nur wenn Datei existiert)
    local hero_image=""
    if [[ -f "$ASSETS_DIR/hero.png" ]]; then
        hero_image=$'\n<p align="center">\n  <img src="docs/assets/hero.png" alt="dotfiles – cmds Workflow mit fzf und bat-Preview" width="800">\n  <br>\n  <em>cmds – alle Aliase und Funktionen durchsuchen (einer von 20+ fzf-Workflows)</em>\n</p>\n'
    fi

    # Theme-Screenshot bedingt einbinden
    local theme_image=""
    if [[ -f "$ASSETS_DIR/theme.png" ]]; then
        theme_image=$'\n<p align="center">\n  <img src="docs/assets/theme.png" alt="eza Tree-View mit Nerd Font Icons und Catppuccin Mocha Farben" width="800">\n  <br>\n  <em>lt – eza Tree-View mit Nerd Font Icons und Catppuccin Mocha Farben</em>\n</p>\n'
    fi

    # Workflow-Screenshot bedingt einbinden
    local workflow_image=""
    if [[ -f "$ASSETS_DIR/workflow.png" ]]; then
        workflow_image=$'\n<p align="center">\n  <img src="docs/assets/workflow.png" alt="git-log Workflow – fzf mit bat-Preview zeigt Commit-Diffs" width="800">\n  <br>\n  <em>git-log – Commit-Historie mit Diff-Preview (bat + Catppuccin Syntax-Highlighting)</em>\n</p>\n'
    fi

    # 1. Body generieren (alles ab "## ✨ Was du bekommst")
    local body
    body=$(cat << EOF
## ✨ Was du bekommst

${tool_replacements}

### Interaktive Workflows (fzf)

Alle Workflows nutzen [fzf](https://github.com/junegunn/fzf) mit bat-Preview, Keybindings und Catppuccin-Theming:

${fzf_workflows}
${workflow_image}
### Media-Toolkit

${media_toolkit}

### Weitere Werkzeuge

${utility_tools}

### Shell-Erlebnis

- **Autosuggestions** – Vorschläge aus der History: \`→\` übernehmen, \`Alt+→\` wortweise
- **Auto-Outdated-Check** – prüft alle ${brew_interval_hours}h auf Homebrew-Updates, einmalige Session-Benachrichtigung
- **\`brew-up\`** – Update + Upgrade + Cleanup in einem Befehl
- **\`brew-list\`** – Versions-Dashboard mit Brewfile-Drift-Erkennung

**Shell-Keybindings** (macOS-optimiert – \`Ctrl+X\` statt \`Alt+C\`):

${shell_keybindings}

Dazu: **[Catppuccin Mocha](https://catppuccin.com/) Theme** überall, **Hilfe im Terminal** via \`dothelp\`, **fzf-Integration** für alles.
${theme_image}
Alle installierten Pakete: [Vollständige Paketliste](docs/setup.md#installierte-pakete)

## 🚀 Installation

\`\`\`bash
curl -fsSL https://github.com/${PROJECT_REPO}/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/install.sh
\`\`\`

Bestehende Konfigurationen werden automatisch gesichert.

Danach **Terminal neu starten**. Fertig!

> 💡 **Tipp:** Gib \`dothelp\` ein – zeigt alle Aliase, Shortcuts und Wartungsbefehle.
>
> ⚠️ **Probleme?** \`dothealth\` prüft die Installation.

### Deinstallation

\`\`\`bash
~/dotfiles/setup/restore.sh
\`\`\`

Entfernt alle Symlinks, stellt Original-Dateien wieder her und setzt das Terminal-Profil (macOS) zurück. Über Homebrew installierte Pakete bleiben bestehen.

Für eine vollständige Deinstallation (inkl. Pakete und Repository): \`~/dotfiles/setup/restore.sh --cleanup\`

Details: [Setup-Doku → Deinstallation](docs/setup.md#deinstallation--wiederherstellung)

### Voraussetzungen

#### macOS (getestet ✅)

- **Apple Silicon oder Intel Mac** (arm64/x86_64)
- **macOS ${macos_min_name} (${macos_min}+)**
- **Internetverbindung** & Admin-Rechte

#### Linux (vorbereitet 🔧)

- **Fedora / Debian / Arch** – Bootstrap + Plattform-Abstraktionen in Docker/Headless validiert (Desktop/Hardware ausstehend)
- macOS-spezifische Module werden automatisch übersprungen

## 📖 Dokumentation

| Befehl | Was es zeigt |
| ------ | ------------ |
| \`dothelp\` | Schnellreferenz: Aliase, Shortcuts, Tool-Ersetzungen, Wartung |
| \`dothealth\` | Installations-Check: fehlende Tools, defekte Symlinks, Config-Probleme |
| \`cmds\` | Alle Aliase und Funktionen interaktiv durchsuchen |
| \`tldr <tool>\` | Vollständige Tool-Doku mit dotfiles-Erweiterungen |

Mehr: [Setup](docs/setup.md) · [Anpassung](docs/customization.md) · [Contributing](CONTRIBUTING.md)

## 🙏 Credits

Dieses Projekt nutzt [Catppuccin Mocha](https://catppuccin.com/) als einheitliches Theme.

Alle Tools und deren Projekt-Homepages: [Installierte Pakete](docs/setup.md#installierte-pakete)

## Lizenz

[MIT](LICENSE)
EOF
)

    # 2. ToC dynamisch aus Body ableiten
    local toc
    toc=$(generate_toc "$body")

    # 3. Alles zusammensetzen: Header + ToC + Body
    cat << EOF
# 🍎 dotfiles

[![CI](https://github.com/${PROJECT_REPO}/actions/workflows/validate.yml/badge.svg)](https://github.com/${PROJECT_REPO}/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-${macos_min_name_url}%20%28${macos_min}%2B%29-black?logo=apple)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-vorbereitet-yellow?logo=linux)](https://kernel.org/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

**Dotfiles mit modernen CLI-Tools, einheitlichem Theme und integrierter Hilfe.**

> ⚠️ **Plattform-Status:** Auf **macOS** produktiv getestet. Linux-Bootstrap (Fedora, Debian, Arch) in Docker/Headless validiert – Desktop (Wayland) und echte Hardware noch ausstehend.
${hero_image}
## Inhalt

${toc}

${body}
EOF
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_readme_md || true
