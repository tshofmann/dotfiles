# 🍎 dotfiles

> macOS Setup für Apple Silicon (arm64) – automatisiert, idempotent, minimal.

## Quickstart

```zsh
git clone https://github.com/tshofmann/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./setup/bootstrap.sh
```

Nach Terminal-Neustart:

```zsh
cd ~/dotfiles && stow --adopt -R terminal && git reset --hard HEAD
```

> ⚠️ **Achtung:** `git reset --hard` verwirft lokale Änderungen. Siehe [Installation](docs/installation.md) für Details.

## Voraussetzungen

- **Apple Silicon Mac** (arm64)
- **macOS 26 (Tahoe)**
- **Internetverbindung** & Admin-Rechte

## Dokumentation

| Thema | Beschreibung |
|-------|--------------|
| [Installation](docs/installation.md) | Schritt-für-Schritt Anleitung |
| [Konfiguration](docs/configuration.md) | Starship, Aliase anpassen |
| [Architektur](docs/architecture.md) | Struktur & Designentscheidungen |
| [Tools](docs/tools.md) | Enthaltene CLI-Tools & Aliase |
| [Troubleshooting](docs/troubleshooting.md) | Häufige Probleme & Lösungen |
| [Contributing](CONTRIBUTING.md) | Für Entwickler: Hooks, Workflow |

## Lizenz

[MIT](LICENSE)
