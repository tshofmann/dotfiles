#!/usr/bin/env zsh
# ============================================================
# readme.sh - Generator für README.md
# ============================================================
# Zweck       : Generiert Haupt-README aus Template + dynamischen Daten
# Pfad        : .github/scripts/generators/readme.sh
# Quelle  : setup/modules/*.sh (modulare Struktur) oder setup/bootstrap.sh (legacy)
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
# fzf-Erkennung: Sucht "fzf" zwischen Funktionsstart und nächster Funktion/Dateiende
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
    local -a media_files=("ffmpeg" "magick" "poppler" "resvg")

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
# Haupt-Generator für README.md
# ------------------------------------------------------------
generate_readme_md() {
    # Dynamische macOS-Versionen (Smart: aus Modulen oder bootstrap.sh)
    local macos_min macos_tested macos_min_name macos_tested_name
    macos_min=$(extract_macos_min_version_smart)
    macos_tested=$(extract_macos_tested_version_smart)
    macos_min_name=$(get_macos_codename "$macos_min")
    macos_tested_name=$(get_macos_codename "$macos_tested")

    # Tool-Ersetzungen dynamisch generieren
    local tool_replacements=$(generate_tool_replacements_table)
    local fzf_workflows=$(generate_fzf_workflows_table)
    local media_toolkit=$(generate_media_toolkit_table)

    cat << EOF
# 🍎 dotfiles

[![CI](https://github.com/${PROJECT_REPO}/actions/workflows/validate.yml/badge.svg)](https://github.com/${PROJECT_REPO}/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-${macos_min}%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-vorbereitet-yellow?logo=linux)](https://kernel.org/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

**Dotfiles mit modernen CLI-Tools, einheitlichem Theme und integrierter Hilfe.**

> ⚠️ **Plattform-Status:** Auf **macOS** produktiv getestet. Linux-Bootstrap (Fedora, Debian, Arch) in Docker/Headless validiert – Desktop (Wayland) und echte Hardware noch ausstehend.

## ✨ Was du bekommst

${tool_replacements}

### Interaktive Workflows (fzf)

Alle Workflows nutzen [fzf](https://github.com/junegunn/fzf) mit bat-Preview, Keybindings und Catppuccin-Theming:

${fzf_workflows}

### Media-Toolkit

${media_toolkit}

Dazu: **[Catppuccin Mocha](https://catppuccin.com/) Theme** überall, **Hilfe im Terminal** via \`dothelp\`, **fzf-Integration** für alles.

Alle installierten Pakete: [\`setup/Brewfile\`](setup/Brewfile)

## 🚀 Installation

\`\`\`bash
curl -fsSL https://github.com/${PROJECT_REPO}/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/install.sh
\`\`\`

Danach **Terminal neu starten**. Fertig!

> 💡 **Tipp:** Gib \`dothelp\` ein – zeigt Keybindings, Aliase und Wartungsbefehle.
>
> ⚠️ **Probleme?** \`dothealth\` prüft die Installation. Backup liegt in \`~/dotfiles/.backup/\`.

### Voraussetzungen

#### macOS (getestet ✅)

- **Apple Silicon oder Intel Mac** (arm64/x86_64)
- **macOS ${macos_min}+** (${macos_min_name})
- **Internetverbindung** & Admin-Rechte

#### Linux (vorbereitet 🔧)

- **Fedora / Debian / Arch** – Bootstrap + Plattform-Abstraktionen in Docker/Headless validiert (Desktop/Hardware ausstehend)
- macOS-spezifische Module werden automatisch übersprungen

## 📖 Dokumentation

| Befehl | Was es zeigt |
| ------ | ------------ |
| \`dothelp\` | Schnellreferenz: Keybindings, Tool-Ersetzungen, Wartung |
| \`cmds\` | Alle Aliase und Funktionen interaktiv durchsuchen |
| \`tldr <tool>\` | Vollständige Tool-Doku mit dotfiles-Erweiterungen |

Mehr: [Setup](docs/setup.md) · [Anpassung](docs/customization.md) · [Contributing](CONTRIBUTING.md)

## Lizenz

[MIT](LICENSE)
EOF
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_readme_md || true
