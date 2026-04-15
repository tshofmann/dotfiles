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
| `arch:` | Nur Arch Linux |

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
# Benötigt    : _core.sh, stow.sh (wenn Configs verlinkt sein müssen)
#
# STEP        : Name | Beschreibung | ✓ Schnell / ⚠️ Netzwerk
# ============================================================

# Standalone: Core laden bevor Guard greift
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    source "${0:A:h}/_core.sh" || { echo "FEHLER: _core.sh nicht gefunden" >&2; exit 1; }
fi

# Guard: Core muss geladen sein (fängt source ohne Core ab)
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor modulname.sh geladen werden" >&2
    return 1
}
```

**Reihenfolge ist kritisch:** Standalone-Check **vor** Guard — sonst bricht der Guard den Standalone-Modus.

## Header-Felder

| Feld | Pflicht | Beschreibung |
| ---- | ------- | ------------ |
| `Benötigt` | Ja | Abhängigkeiten (`_core.sh` + weitere Module) |
| `STEP` | Ja | Name, Beschreibung, Geschwindigkeit — wird vom Generator für `docs/setup.md` gelesen |

## Modul-Registrierung

Neue Module müssen im `MODULES`-Array in `setup/bootstrap.sh` registriert werden. Position beachten — Abhängigkeiten müssen vorher laufen (z.B. `stow` vor `bat`).

## Setup-Funktion

Jedes Modul definiert eine `setup_<name>()`-Funktion und setzt `CURRENT_STEP` für den Error-Handler:

```zsh
setup_modulname() {
    CURRENT_STEP="Modulname Setup"
    # Implementation
}
```

## Linux-Mapping (BREW_TO_ALT)

Auf **Arch, Fedora und Debian x86_64** installiert Homebrew/Linuxbrew direkt aus dem Brewfile — kein zusätzliches Mapping nötig.

`setup/modules/apt-packages.sh` enthält das `BREW_TO_ALT`-Mapping als **Fallback für Debian ARM** (armv6/armv7, wo Homebrew nicht verfügbar ist). Einträge nutzen Method-Prefixe wie `apt:<pkg>`, `cargo:<crate>`, `npm:<pkg>` oder `skip`. Bei neuen Tools in `setup/Brewfile` sollte dieses Mapping erweitert werden, damit der ARM-Fallback vollständig bleibt.
