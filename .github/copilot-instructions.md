# Copilot Instructions für dotfiles

## Git Commits

- **Niemals `--no-verify` verwenden** – Pre-Commit Hooks müssen durchlaufen
- Bei Hook-Fehlern: Problem beheben, dann erneut committen
- Commit-Messages auf Deutsch, Conventional Commits Format

## Code-Stil

- Shell-Dateien: ZSH-kompatibel, `set -euo pipefail` wo sinnvoll
- Aliase: Guard-Check am Anfang (`command -v tool &>/dev/null || return`)
- Kommentare: Deutsch, außer bei technischen Begriffen

## Architektur-Entscheidungen

- Plattform: macOS mit Apple Silicon (arm64) – Bootstrap blockiert andere Architekturen
- Homebrew-Pfade: Dynamisch erkannt (Apple Silicon → Intel → Linux)
- Designprinzip: **So dynamisch wie möglich, so statisch wie nötig**

## Validierung vor Änderungen

1. `zsh -n <datei>` – Syntax-Check
2. `./scripts/tests/run-tests.sh` – Unit-Tests bei Validator-Änderungen
3. `./scripts/health-check.sh` – System-Health bei Tool-Änderungen
