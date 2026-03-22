#!/usr/bin/env zsh
# ============================================================
# setup.sh - Generator für docs/setup.md
# ============================================================
# Zweck       : Generiert Setup-Dokumentation aus bootstrap.sh/Modulen
# Pfad        : .github/scripts/generators/setup.sh
# Quelle  : setup/modules/*.sh (modulare Struktur) oder setup/bootstrap.sh (legacy)
# ============================================================

source "${0:A:h}/common.sh"

# ------------------------------------------------------------
# Bootstrap-Schritte extrahieren (Smart: Module oder Legacy)
# ------------------------------------------------------------
# Parst CURRENT_STEP Zuweisungen aus Modulen oder bootstrap.sh
extract_bootstrap_steps() {
    local step_count=0

    if has_bootstrap_modules; then
        # Modulare Struktur: Schritte aus allen Modulen sammeln
        local steps
        steps=$(generate_bootstrap_steps_from_modules)
        step_count=$(echo "$steps" | grep -c "." || echo 0)
    else
        # Legacy: Aus bootstrap.sh direkt
        while IFS= read -r line; do
            if [[ "$line" == *'CURRENT_STEP='* ]]; then
                local step="${line#*CURRENT_STEP=}"
                step="${step#\"}"
                step="${step%\"}"
                [[ -n "$step" && "$step" != "Initialisierung" ]] && {
                    (( step_count++ )) || true
                }
            fi
        done < "$BOOTSTRAP"
    fi

    echo "$step_count"
}

# ------------------------------------------------------------
# Deinstallations-Abschnitt (aus restore.sh Metadaten)
# ------------------------------------------------------------
generate_uninstall_section() {
    local restore_script="$DOTFILES_DIR/setup/restore.sh"
    [[ -f "$restore_script" ]] || return 0

    cat << 'UNINSTALL'

---

## Deinstallation / Wiederherstellung

Falls du die dotfiles-Installation rückgängig machen möchtest:

```zsh
./setup/restore.sh
```

### Was passiert?

| Aktion | Beschreibung |
| ------ | ------------ |
| Symlinks entfernen | Alle dotfiles-Symlinks aus `~` werden gelöscht |
| Backup wiederherstellen | Originale Konfigurationsdateien werden aus `.backup/` zurückkopiert |
| Terminal-Profil | Wird auf "Basic" zurückgesetzt (macOS) |

### Optionen

| Option | Beschreibung |
| ------ | ------------ |
| `--yes`, `-y` | Keine Bestätigung erforderlich |
| `--help`, `-h` | Hilfe anzeigen |

### Backup-Speicherort

Das Backup wird beim ersten Bootstrap automatisch erstellt:

```text
.backup/
├── manifest.json    # Metadaten aller gesicherten Dateien
├── backup.log       # Protokoll der Backup-Operationen
└── home/            # Gesicherte Originaldateien (Struktur von ~)
```

> **Wichtig:** Das erste Backup wird NIE überschrieben (Idempotenz). Selbst bei mehrfacher Bootstrap-Ausführung bleibt das ursprüngliche Backup erhalten.
>
> **💡 Tipp:** Nach erfolgreicher Wiederherstellung kann das Backup manuell gelöscht werden: `rm -rf .backup/`

### Was bleibt bestehen?

`restore.sh` entfernt nur Symlinks und stellt Backups wieder her. **Nicht entfernt** werden:

- Über Homebrew installierte Pakete (Formulae, Casks, Mac App Store Apps)
- Homebrew selbst
- Das Repository `~/dotfiles`

Das ist Absicht: Pakete könnten unabhängig von den dotfiles installiert worden sein oder von anderer Software benötigt werden.

### Optional: Vollständig aufräumen

Falls du auch die installierten Pakete und das Repository entfernen möchtest, gehe **in dieser Reihenfolge** vor:

**Schritt 1 – Prüfen, was entfernt würde:**

```zsh
brew bundle list --file=~/dotfiles/setup/Brewfile --all
```

Zeigt alle Pakete aus dem Brewfile. Prüfe die Liste – behalte, was du unabhängig von den dotfiles brauchst (z.B. VS Code, Xcode).

**Schritt 2 – Pakete entfernen** (nur was du nicht mehr brauchst):

```zsh
brew remove bat eza fd fzf ripgrep   # Beispiel: einzelne Formulae
brew remove --cask kitty             # Beispiel: einzelne Casks
```

> ⚠️ **Vorsicht:** Entferne Pakete einzeln statt pauschal. Casks wie Visual Studio Code oder Kitty haben eigene Einstellungen und Daten, die bei der Deinstallation verloren gehen.

**Schritt 3 – Repository entfernen** (erst wenn alles geprüft ist):

> ⚠️ Das Backup liegt in `~/dotfiles/.backup/`. Stelle **vorher** sicher, dass `restore.sh` alle Dateien korrekt wiederhergestellt hat.

```zsh
rm -rf ~/dotfiles
```
UNINSTALL
}

# ------------------------------------------------------------
# Haupt-Generator für setup.md
# ------------------------------------------------------------
generate_setup_md() {
    # Dynamische macOS-Versionen (Smart: aus Modulen oder bootstrap.sh)
    local macos_min macos_tested macos_min_name macos_tested_name
    macos_min=$(extract_macos_min_version_smart)
    macos_tested=$(extract_macos_tested_version_smart)
    macos_min_name=$(get_macos_codename "$macos_min")
    macos_tested_name=$(get_macos_codename "$macos_tested")

    cat << 'HEADER'
# 🚀 Installation

Diese Anleitung führt dich durch die vollständige Installation der dotfiles.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen in `setup/modules/*.sh` und `setup/Brewfile` vornehmen.
>
> ⚠️ **Plattform-Status:** Auf **macOS** produktiv getestet. Linux-Bootstrap (Fedora, Debian, Arch) in Docker/Headless validiert – Desktop (Wayland) und echte Hardware noch ausstehend.

## Voraussetzungen

### macOS (getestet ✅)

| Anforderung | Details |
| ----------- | ------- |
| **Apple Silicon oder Intel Mac** | arm64 (M1, M2, …) oder x86_64 |
HEADER
    # Dynamische macOS-Zeile mit min und tested
    echo "| **macOS ${macos_min}+** | ${macos_min_name} oder neuer – getestet auf ${macos_tested} (${macos_tested_name}) |"
    cat << 'PART2'
| **Internetverbindung** | Für Homebrew-Installation und Download der Formulae/Casks |
| **Admin-Rechte** | `sudo`-Passwort erforderlich (siehe unten) |

### Linux (vorbereitet 🔧)

| Anforderung | Details |
| ----------- | ------- |
| **Fedora / Debian / Arch** | Bootstrap + Plattform-Abstraktionen in Docker/Headless validiert (Desktop/Hardware ausstehend) |
| **arm64, x86_64 oder armv6/armv7** | Alle Architekturen unterstützt (32-bit ARM via apt/cargo) |
| **Internetverbindung** | Für Linuxbrew-Installation |
| **Build-Tools** | `gcc`/`clang` – werden bei Bedarf nachinstalliert |

> **Hinweis:** Auf Linux werden macOS-spezifische Module (Terminal.app, mas, Xcode-Theme) automatisch übersprungen. Die Plattform-Erkennung erfolgt in `setup/modules/_core.sh`.
>
> **Hinweis (32-bit ARM / Raspberry Pi):** Homebrew unterstützt kein armv6/armv7. Auf diesen Systemen werden Tools automatisch via apt, Cargo und npm installiert (`setup/modules/apt-packages.sh`). Das Brewfile bleibt die Single Source of Truth – das Mapping erfolgt dynamisch.
>
> **Hinweis (macOS):** Architektur- und macOS-Versionsprüfung erfolgen automatisch beim Start von `bootstrap.sh`. Bei nicht unterstützten Systemen bricht das Skript mit einer Fehlermeldung ab.

### Wann wird `sudo` benötigt?

Das Bootstrap-Skript fragt zu folgenden Zeitpunkten nach dem Admin-Passwort:

**macOS:**

1. **Xcode CLI Tools Installation** – `xcode-select --install` triggert einen System-Dialog, der Admin-Rechte erfordert
2. **Homebrew Erstinstallation** – Das offizielle Installationsskript erstellt Verzeichnisse unter `/opt/homebrew` (Apple Silicon) oder `/usr/local` (Intel) und benötigt dafür `sudo`

**Linux:**

1. **Linuxbrew Erstinstallation** – Erstellt Verzeichnisse unter `/home/linuxbrew/.linuxbrew`
2. **Build-Tools** – Falls `gcc`/`clang` fehlen, werden Paketmanager-Befehle vorgeschlagen

> **Nach der Ersteinrichtung:** Sobald Homebrew/Linuxbrew installiert ist, laufen alle weiteren `brew`-Befehle ohne `sudo`. Das Bootstrap-Skript ist idempotent – bei erneuter Ausführung werden keine Admin-Rechte mehr benötigt, wenn die Tools bereits vorhanden sind.

---

## Schritt 1: Install-Skript ausführen

PART2

    cat << INSTALL_CMD
\`\`\`bash
curl -fsSL https://github.com/${PROJECT_REPO}/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/install.sh
\`\`\`
INSTALL_CMD

    cat << 'PART3'

> **💡 Warum install.sh?** Das Install-Skript ist POSIX-kompatibel und läuft mit /bin/sh, bash oder zsh. Es stellt sicher, dass zsh installiert ist (ggf. via apt/dnf/pacman) und startet dann das eigentliche Bootstrap.

### Was das Skript macht

Das Install-Skript führt folgende Aktionen aus:

1. **Plattform-Erkennung** – macOS, Fedora, Debian oder Arch
2. **zsh-Installation** – Falls nicht vorhanden, via Paketmanager
3. **Default-Shell** – Setzt zsh als Standard-Shell (nur Linux)
4. **Bootstrap starten** – Führt bootstrap.sh mit zsh aus

Das Bootstrap-Skript führt dann folgende Aktionen in dieser Reihenfolge aus:

| Aktion | Beschreibung | Bei Fehler |
| ------ | ------------ | ---------- |
PART3

    # Dynamische Bootstrap-Schritte-Tabelle aus Modulen generieren
    if has_bootstrap_modules; then
        generate_bootstrap_steps_table
    else
        # Fallback: Statische Tabelle für Legacy-Bootstrap
        echo "| macOS-Version-Check | Prüft ob macOS ${macos_min}+ (${macos_min_name}) | ❌ Exit |"

        # Font- und Profilname dynamisch aus Brewfile/Setup-Dateien
        local legacy_font legacy_profile
        legacy_font=$(font_display_name "$(extract_installed_nerd_font)")
        [[ -z "$legacy_font" ]] && legacy_font="Nerd Font"
        legacy_profile=$(extract_terminal_profile_name)
        [[ -z "$legacy_profile" ]] && legacy_profile="<profilname>"

        cat << LEGACY_STEPS
| Netzwerk-Check | Prüft Internetverbindung | ❌ Exit |
| Schreibrechte-Check | Prüft ob \`\$HOME\` schreibbar ist | ❌ Exit |
| Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit |
| Homebrew | Installiert/prüft Homebrew | ❌ Exit |
| Brewfile | Installiert CLI-Tools via \`brew bundle\` | ❌ Exit |
| Font-Verifikation | Prüft ${legacy_font} Installation | ❌ Exit |
| Terminal-Profil | Importiert \`${legacy_profile}.terminal\` als Standard | ⚠️ Warnung |
| ZSH-Sessions | Prüft SHELL_SESSIONS_DISABLE in ~/.zshenv | ⚠️ Warnung |
LEGACY_STEPS
    fi

    cat << 'REST'

> **Idempotenz:** Das Skript kann beliebig oft ausgeführt werden – bereits installierte Komponenten werden erkannt und übersprungen.
>
> **⏱️ Timeout-Konfiguration (macOS):** Der Terminal-Profil-Import wartet standardmäßig 20 Sekunden auf Registrierung im System. Bei langsamen Systemen oder VMs kann dies erhöht werden:
>
> ```bash
> PROFILE_IMPORT_TIMEOUT=60 ./setup/install.sh
> ```
>
> **Empfohlene Timeout-Werte:**
>
> | Umgebung | Empfohlener Wert | Begründung |
> | -------- | ---------------- | ---------- |
> | Native Hardware | `20` (Standard) | Ausreichend für normale Systeme |
> | macOS VM (Apple Silicon) | `30-45` | VMs haben leicht erhöhte I/O-Latenz |
> | macOS VM (Parallels/VMware) | `45-60` | Virtualisierungsoverhead bei GUI-Operationen |
> | CI/CD (GitHub Actions) | `60-90` | Shared Resources, variable Performance |
> | Langsame Netzwerk-Speicher | `90-120` | Bei NFS/SMB-gemounteten Home-Verzeichnissen |
>
> **📦 Komponenten-Abhängigkeiten:** Terminal-Profil, Nerd Font und Starship-Config sind eng gekoppelt. Wenn Icons als □ oder ? angezeigt werden, siehe [Troubleshooting](#troubleshooting) unten.

---

## Schritt 2: Terminal neu starten

Nach Abschluss des Bootstrap-Skripts:

**macOS:** Terminal.app beenden und neu öffnen (Cmd+Q, dann neu starten)

**Linux:** Terminal neu starten oder Shell neu laden: `exec zsh`

Das ist alles! Das Bootstrap-Skript hat bereits:

- ✅ Alle Konfigurationsdateien verlinkt (via Stow)
- ✅ Git-Hooks aktiviert
- ✅ bat-Cache für das Catppuccin Theme gebaut
- ✅ tldr-Pages heruntergeladen

> **💡 Warum Terminal neu starten?** Das Terminal muss neu gestartet werden, damit alle Konfigurationen (Profile, Umgebungsvariablen) vollständig aktiv werden.

---

## Schritt 3: Verifizierung

Nach der Installation kannst du die Einrichtung prüfen:

\`\`\`zsh
./.github/scripts/health-check.sh  # Health-Check ausführen
cmds                                # Interaktive Alias-Suche
dothelp                             # Tool-Hilfe mit dotfiles-Erweiterungen
ff                                  # System-Info anzeigen
\`\`\`

---

## Installierte Pakete

> **Hinweis:** Casks und Mac App Store Apps werden nur auf macOS installiert. Auf Linux werden nur Homebrew Formulae verwendet.

REST

    # Pakete nach Kategorien aus Brewfile generieren
    generate_brewfile_section

    # Deinstallations-Abschnitt generieren (aus restore.sh)
    generate_uninstall_section
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_setup_md || true
