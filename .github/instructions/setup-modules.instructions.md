---
name: 'Setup-Module'
description: 'Konventionen für Bootstrap-Module: Plattform-Prefixes, _core.sh Guard, Modul-Format'
applyTo: 'setup/modules/*.sh'
---

# Setup-Module Konventionen

## Plattform-Prefixes

Module in `setup/modules/*.sh` können plattformspezifisch sein:

| Prefix | Gilt für |
| ------ | -------- |
| (kein) | Alle Plattformen |
| `macos:` | Nur macOS |
| `linux:` | Alle Linux-Distros |
| `fedora:` | Nur Fedora |
| `debian:` | Nur Debian/Ubuntu |

## Core Guard

Alle Module setzen voraus, dass `_core.sh` geladen ist (gemeinsame stdlib). Logging wird über `_core.sh` bereitgestellt.

## Modul-Format

```zsh
#!/usr/bin/env zsh
# ============================================================
# modulname.sh - Kurzbeschreibung
# ============================================================
# Zweck       : Was macht dieses Modul
# Pfad        : setup/modules/modulname.sh
# ============================================================

# Guard: _core.sh muss geladen sein
```

## Linux-Mapping (BREW_TO_ALT)

`setup/modules/apt-packages.sh` enthält das `BREW_TO_ALT`-Mapping (Homebrew-Tool → Linux-Paket). Bei neuen Tools in `setup/Brewfile` muss dieses Mapping erweitert werden.
