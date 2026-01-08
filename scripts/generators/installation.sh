#!/usr/bin/env zsh
# ============================================================
# installation.sh - Generator für docs/installation.md
# ============================================================
# Zweck   : Generiert Installationsdokumentation aus bootstrap.sh
# Pfad    : scripts/generators/installation.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Bootstrap-Schritte extrahieren
# ------------------------------------------------------------
# Parst CURRENT_STEP Zuweisungen und Aktionen aus bootstrap.sh
extract_bootstrap_steps() {
    local output=""
    local step_count=0
    
    while IFS= read -r line; do
        # CURRENT_STEP="..." Zuweisungen
        if [[ "$line" == *'CURRENT_STEP='* ]]; then
            local step="${line#*CURRENT_STEP=}"
            step="${step#\"}"
            step="${step%\"}"
            [[ -n "$step" && "$step" != "Initialisierung" ]] && {
                (( step_count++ )) || true
            }
        fi
    done < "$BOOTSTRAP"
    
    echo "$step_count"
}

# ------------------------------------------------------------
# Haupt-Generator für installation.md
# ------------------------------------------------------------
generate_installation_md() {
    # Dynamische macOS-Version aus bootstrap.sh
    local macos_min macos_codename
    macos_min=$(extract_macos_min_version)
    macos_codename=$(get_macos_codename "$macos_min")
    
    cat << 'HEADER'
# 🚀 Installation

Diese Anleitung führt dich durch die vollständige Installation der dotfiles auf einem frischen Apple Silicon Mac.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen direkt in `setup/bootstrap.sh` und `setup/Brewfile` vornehmen.

## Voraussetzungen

| Anforderung | Details |
|-------------|---------|
| **Apple Silicon Mac** | M1, M2, … (arm64) – Intel-Macs werden nicht unterstützt |
HEADER
    # Dynamische macOS-Zeile
    echo "| **macOS ${macos_min}** | ${macos_codename} – ältere Versionen nicht getestet |"
    cat << 'PART2'
| **Internetverbindung** | Für Homebrew-Installation und Download der Formulae/Casks |
| **Admin-Rechte** | `sudo`-Passwort erforderlich (siehe unten) |

> **Hinweis:** Architektur- und macOS-Versionsprüfung erfolgen automatisch beim Start von `bootstrap.sh`. Bei nicht unterstützten Systemen bricht das Skript mit einer Fehlermeldung ab.

### Wann wird `sudo` benötigt?

Das Bootstrap-Skript fragt zu folgenden Zeitpunkten nach dem Admin-Passwort:

1. **Xcode CLI Tools Installation** – `xcode-select --install` triggert einen System-Dialog, der Admin-Rechte erfordert
2. **Homebrew Erstinstallation** – Das offizielle Installationsskript erstellt Verzeichnisse unter `/opt/homebrew` und benötigt dafür `sudo`

> **Nach der Ersteinrichtung:** Sobald Homebrew installiert ist, laufen alle weiteren `brew`-Befehle ohne `sudo`. Das Bootstrap-Skript ist idempotent – bei erneuter Ausführung werden keine Admin-Rechte mehr benötigt, wenn die Tools bereits vorhanden sind.

---

## Schritt 1: Bootstrap-Skript ausführen

```zsh
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/bootstrap.sh
```

> **💡 Warum curl statt git?** Auf einem frischen Mac ist Git erst nach Installation der Xcode CLI Tools verfügbar. Mit `curl` (in macOS enthalten) umgehen wir diese Abhängigkeit – die CLI Tools werden dann automatisch vom Bootstrap-Skript installiert.

### Was das Skript macht

Das Bootstrap-Skript führt folgende Aktionen in dieser Reihenfolge aus:

| Aktion | Beschreibung | Bei Fehler |
|--------|--------------|------------|
| Architektur-Check | Prüft ob arm64 (Apple Silicon) | ❌ Exit |
PART2
    # Dynamische macOS-Version-Check Zeile
    echo "| macOS-Version-Check | Prüft ob macOS ${macos_min}+ (${macos_codename}) | ❌ Exit |"
    cat << 'PART3'
| Netzwerk-Check | Prüft Internetverbindung | ❌ Exit |
| Schreibrechte-Check | Prüft ob `$HOME` schreibbar ist | ❌ Exit |
| Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit |
| Homebrew | Installiert/prüft Homebrew unter `/opt/homebrew` | ❌ Exit |
| Brewfile | Installiert CLI-Tools via `brew bundle` | ❌ Exit |
| Font-Verifikation | Prüft MesloLG Nerd Font Installation | ❌ Exit |
| Terminal-Profil | Importiert `catppuccin-mocha.terminal` als Standard | ⚠️ Warnung |
| Starship-Theme | Generiert `~/.config/starship.toml` | ⚠️ Warnung |
| ZSH-Sessions | Prüft SHELL_SESSIONS_DISABLE in ~/.zshenv | ⚠️ Warnung |
PART3

    cat << 'REST'
> **Idempotenz:** Das Skript kann beliebig oft ausgeführt werden – bereits installierte Komponenten werden erkannt und übersprungen.

> **⏱️ Timeout-Konfiguration:** Der Terminal-Profil-Import wartet standardmäßig 20 Sekunden auf Registrierung im System. Bei langsamen Systemen oder VMs kann dies erhöht werden:
> ```bash
> PROFILE_IMPORT_TIMEOUT=60 ./setup/bootstrap.sh
> ```
>
> **Empfohlene Timeout-Werte:**
> | Umgebung | Empfohlener Wert | Begründung |
> |----------|------------------|------------|
> | Native Hardware | `20` (Standard) | Ausreichend für normale Systeme |
> | macOS VM (Apple Silicon) | `30-45` | VMs haben leicht erhöhte I/O-Latenz |
> | macOS VM (Parallels/VMware) | `45-60` | Virtualisierungsoverhead bei GUI-Operationen |
> | CI/CD (GitHub Actions) | `60-90` | Shared Resources, variable Performance |
> | Langsame Netzwerk-Speicher | `90-120` | Bei NFS/SMB-gemounteten Home-Verzeichnissen |

> **📦 Komponenten-Abhängigkeiten:** Terminal-Profil, Nerd Font und Starship-Preset sind eng gekoppelt. Wenn Icons als □ oder ? angezeigt werden, liegt es meist an einer fehlenden oder falschen Font-Konfiguration. Details: [Architektur → Komponenten-Abhängigkeiten](architecture.md#komponenten-abhängigkeiten)

---

## Schritt 2: Konfigurationsdateien verlinken

Nach Abschluss des Bootstrap-Skripts:

1. **Terminal.app neu starten** (für vollständige Übernahme der Profil-Einstellungen)
2. Dann im neuen Terminal-Fenster:

```zsh
cd ~/dotfiles && stow --adopt -R terminal && git reset --hard HEAD
```

3. **bat-Cache für Catppuccin Theme bauen:**

```zsh
bat cache --build
```

> **💡 Warum dieser Schritt?** Das Catppuccin Mocha Theme für bat liegt in `~/.config/bat/themes/` (via Stow verlinkt). bat erkennt neue Themes erst nach einem Cache-Rebuild.

4. **tealdeer-Cache herunterladen (einmalig):**

```zsh
tldr --update
```

> **💡 Warum dieser Schritt?** tealdeer benötigt einen initialen Download der tldr-Pages. Danach aktualisiert sich der Cache automatisch (`auto_update = true` in Config).

### Was diese Befehle machen

| Befehl | Beschreibung |
|--------|--------------|
| `cd ~/dotfiles` | Ins dotfiles-Verzeichnis wechseln |
| `stow --adopt -R terminal` | Symlinks erstellen, existierende Dateien übernehmen |
| `git reset --hard HEAD` | Adoptierte Dateien auf Repository-Zustand zurücksetzen |
| `bat cache --build` | bat Theme-Cache neu aufbauen |
| `tldr --update` | tldr-Pages herunterladen |

> **⚠️ Vorsicht:** `git reset --hard HEAD` verwirft alle lokalen Änderungen an adoptierten Dateien. Falls du bereits eigene `.zshrc` Anpassungen hattest, sichere diese vorher.

---

## Schritt 3: Verifizierung

Nach der Installation kannst du die Einrichtung prüfen:

```zsh
# Health-Check ausführen
./scripts/health-check.sh

# Interaktive Alias-Suche testen
fa

# System-Info anzeigen
ff
```

---

## Installierte Pakete

REST

    # CLI-Tools aus Brewfile
    echo "### CLI-Tools (via Homebrew)"
    echo ""
    echo "| Paket | Beschreibung |"
    echo "|-------|--------------|"
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        local typ="${rest##*|}"
        
        [[ "$typ" == "brew" ]] && echo "| \`$name\` | $desc |"
    done < "$BREWFILE"
    
    echo ""
    
    # Casks
    echo "### Apps & Fonts (via Cask)"
    echo ""
    echo "| Paket | Beschreibung |"
    echo "|-------|--------------|"
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        local typ="${rest##*|}"
        
        [[ "$typ" == "cask" ]] && echo "| \`$name\` | $desc |"
    done < "$BREWFILE"
    
    echo ""
    
    # MAS Apps
    echo "### Mac App Store Apps (via mas)"
    echo ""
    echo "| App | Beschreibung |"
    echo "|-----|--------------|"
    
    while IFS= read -r line; do
        [[ "$line" == \#* || -z "$line" ]] && continue
        
        local parsed=$(parse_brewfile_entry "$line")
        [[ -z "$parsed" ]] && continue
        
        local name="${parsed%%|*}"
        local rest="${parsed#*|}"
        local desc="${rest%%|*}"
        local typ="${rest##*|}"
        
        [[ "$typ" == "mas" ]] && echo "| $name | $desc |"
    done < "$BREWFILE"
    
    echo ""
    echo '> **Hinweis:** Die Anmeldung im App Store muss manuell erfolgen – die Befehle `mas account` und `mas signin` sind auf macOS 12+ nicht verfügbar.'
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_installation_md || true
