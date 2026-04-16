---
name: 'Dokumentations-Generatoren'
description: 'Single Source of Truth, Generator-Pipeline, was generiert wohin, niemals Docs manuell editieren'
applyTo: '.github/scripts/generators/**'
---

# Dokumentations-Generatoren

## Single Source of Truth

Doku wird automatisch aus Code generiert. **Niemals Docs manuell editieren** – Änderungen im Code machen.

## Was generiert wohin

| Quelle | Ziel |
| ------ | ---- |
| `.alias`-Dateien | tldr-Patches/Pages (`.patch.md`/`.page.md`), `README.md` (Tool-Ersetzungen) |
| `Brewfile` | `docs/setup.md` (Tool-Listen) |
| `bootstrap.sh` + `setup/modules/*.sh` | `docs/setup.md` (Bootstrap-Schritte) |
| `theme-style` | `docs/customization.md` (Farbpalette), `terminal/.config/tealdeer/pages/catppuccin.page.md` |
| `CONTRIBUTING.md` | Table of Contents (ToC) |

## Generator-Architektur

Modularisiert in `.github/scripts/generators/`:

- `common/` — Core Utilities (Config, UI, Parser, Bootstrap-Parser)
- `tldr/` — tldr-Patch-Generierung (Alias-Helper, Patch-Generator, Spezial-Tools)
- `*.sh` — Individuelle Generatoren (readme.sh, setup.sh, customization.sh, contributing.sh)

## Ausführung

```zsh
./.github/scripts/generate-docs.sh --generate   # Generieren
./.github/scripts/generate-docs.sh --check       # Nur prüfen
```

## tldr-Format

Der Generator prüft automatisch ob eine offizielle tldr-Seite existiert:

- Offizielle Seite vorhanden → `.patch.md` (erweitert diese)
- Keine offizielle Seite → `.page.md` (ersetzt diese)
