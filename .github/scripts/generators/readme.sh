#!/usr/bin/env zsh
# ============================================================
# readme.sh - Generator für README.md
# ============================================================
# Zweck   : Generiert Haupt-README aus Template + dynamischen Daten
# Pfad    : .github/scripts/generators/readme.sh
# Quelle  : setup/modules/*.sh (modulare Struktur) oder setup/bootstrap.sh (legacy)
# ============================================================

source "${0:A:h}/lib.sh"

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

    # dothelp-Kategorien aus echten Quellen
    local dothelp_categories=$(get_dothelp_categories)

    cat << EOF
# 🍎 dotfiles

[![CI](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-${macos_min}%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

> ${PROJECT_DESCRIPTION}

## Quickstart

\`\`\`zsh
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/bootstrap.sh
\`\`\`

Nach Terminal-Neustart:

\`\`\`zsh
cd ~/dotfiles && stow --adopt -R terminal editor && git reset --hard HEAD && bat cache --build && tldr --update
\`\`\`

> ⚠️ **Achtung:** \`git reset --hard\` verwirft lokale Änderungen. Siehe [Setup](docs/setup.md) für Details.

## Voraussetzungen

- **Apple Silicon Mac** (arm64)
- **macOS ${macos_min}+** (${macos_min_name}) – getestet auf macOS ${macos_tested} (${macos_tested_name})
- **Internetverbindung** & Admin-Rechte

## Hilfe & Dokumentation

| Thema | Beschreibung |
| ----- | ------------ |
| \`dothelp\` | Hilfe/Dokumentation im Terminal: ${dothelp_categories} |
| [Setup](docs/setup.md) | Schritt-für-Schritt Anleitung |
| [Anpassung](docs/customization.md) | Starship, Aliase, ZSH anpassen |
| [Contributing](CONTRIBUTING.md) | Für Entwickler: Architektur, Hooks, Workflow |

## Lizenz

[MIT](LICENSE)
EOF
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_readme_md || true
