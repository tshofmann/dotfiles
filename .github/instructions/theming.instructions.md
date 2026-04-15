---
name: 'Theming (Catppuccin Mocha)'
description: 'Catppuccin Mocha Farbpalette, semantische Farben, Theme-Quellen-Tabelle und Upstream-Themes'
applyTo: '**/theme-style'
---

# Theming – Catppuccin Mocha

## Zentrale Definition

`terminal/.config/theme-style` ist die zentrale Referenz für alle Farben.

## Semantische Farben

| Verwendung | Farbe | Hex |
| ---------- | ----- | --- |
| Selection Background | Surface1 | `#45475A` |
| Active Border/Accent | Mauve | `#CBA6F7` |
| Multi-Select Marker | Lavender | `#B4BEFE` |
| Success/Valid | Green | `#A6E3A1` |
| Error/Invalid | Red | `#F38BA8` |
| Warning/Modified | Yellow | `#F9E2AF` |
| Directory | Mauve | `#CBA6F7` |
| Symlink/Info | Blue | `#89B4FA` |

## Bei neuen Tool-Konfigurationen

1. **Prüfe** ob ein offizielles Catppuccin-Theme existiert auf [github.com/catppuccin](https://github.com/catppuccin)
2. **Nutze semantische Farben** konsistent (Tabelle oben)
3. **Aktualisiere Status** in der Theme-Quellen-Tabelle (Abschnitt „Theme-Quellen“) in `theme-style`
4. **Bevorzuge Upstream-Themes** – nur manuell wenn kein offizielles existiert

## Status-Dokumentation

```text
upstream        = Unverändert aus offiziellem Repo
upstream+X      = Mit Anpassung (X = was geändert)
upstream-X      = Mit Entfernung (X = was entfernt)
builtin         = In Tool eingebaut (kein externes Theme nötig)
manual          = Manuell basierend auf catppuccin.com/palette
semantics       = Nur semantische Farbzuordnung, kein vollständiges Upstream-Theme
```

## In Skripten nutzen

```zsh
source "$DOTFILES_DIR/terminal/.config/theme-style"
# Dann: $C_GREEN, $C_RED, $C_BLUE, etc.
```
