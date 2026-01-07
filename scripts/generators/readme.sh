#!/usr/bin/env zsh
# ============================================================
# readme.sh - Generator für README.md
# ============================================================
# Zweck   : Generiert Haupt-README aus Template + dynamischen Daten
# Pfad    : scripts/generators/readme.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Haupt-Generator für README.md
# ------------------------------------------------------------
generate_readme_md() {
    cat << 'EOF'
# 🍎 dotfiles

[![CI](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/tshofmann/dotfiles/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-green?logo=gnubash)](https://www.zsh.org/)

> macOS Setup für Apple Silicon (arm64) – automatisiert, idempotent, minimal.

## Quickstart

```zsh
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/bootstrap.sh
```

Nach Terminal-Neustart:

```zsh
cd ~/dotfiles && stow --adopt -R terminal && git reset --hard HEAD && bat cache --build && tldr --update
```

> ⚠️ **Achtung:** `git reset --hard` verwirft lokale Änderungen. Siehe [Installation](docs/installation.md) für Details.

> 💡 **Tipp:** Nach der Installation `fa` eingeben für eine interaktive Übersicht aller Aliase und Funktionen.

## Voraussetzungen

- **Apple Silicon Mac** (arm64)
- **macOS 14+** (Sonoma oder neuer)
- **Internetverbindung** & Admin-Rechte

## Dokumentation

| Thema | Beschreibung |
|-------|--------------|
| [Installation](docs/installation.md) | Schritt-für-Schritt Anleitung |
| [Konfiguration](docs/configuration.md) | Starship, Aliase anpassen |
| [Architektur](docs/architecture.md) | Struktur & Designentscheidungen |
| [Tools](docs/tools.md) | Enthaltene CLI-Tools & Aliase |
| [Contributing](CONTRIBUTING.md) | Für Entwickler: Hooks, Workflow |

## Lizenz

[MIT](LICENSE)
EOF
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_readme_md || true
