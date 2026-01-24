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

    cat << EOF
# 🍎 dotfiles

[![CI](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-${macos_min}%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

**Dein Mac-Terminal mit modernen Tools, einheitlichem Theme und Dokumentation.**

## ✨ Was du bekommst

${tool_replacements}

Dazu: **[Catppuccin Mocha](https://catppuccin.com/) Theme** überall, **Hilfe im Terminal** via \`dothelp\`, **fzf-Integration** für alles.

Alle installierten Pakete: [\`setup/Brewfile\`](setup/Brewfile)

## 🚀 Installation

\`\`\`zsh
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/bootstrap.sh
\`\`\`

Danach **Terminal neu starten** (Cmd+Q). Fertig!

### Voraussetzungen

- **Apple Silicon Mac** (arm64)
- **macOS ${macos_min}+** (${macos_min_name}) – getestet auf macOS ${macos_tested} (${macos_tested_name})
- **Internetverbindung** & Admin-Rechte

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
