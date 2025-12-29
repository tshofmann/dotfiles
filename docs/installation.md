# 🚀 Installation

Diese Anleitung führt dich durch die vollständige Installation der dotfiles auf einem frischen Apple Silicon Mac.

## Voraussetzungen

| Anforderung | Details |
|-------------|---------|
| **Apple Silicon Mac** | M1, M2, … (arm64) – Intel-Macs werden nicht unterstützt |
| **macOS 14+** | Sonoma oder neuer – entspricht [Homebrew Tier 1](https://docs.brew.sh/Support-Tiers) |
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
| macOS-Version-Check | Prüft ob macOS 14+ (Sonoma) | ❌ Exit |
| Netzwerk-Check | Prüft Internetverbindung | ❌ Exit |
| Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit |
| Homebrew | Installiert/prüft Homebrew unter `/opt/homebrew` | ❌ Exit |
| Brewfile | Installiert CLI-Tools via `brew bundle` | ❌ Exit |
| Font-Verifikation | Prüft MesloLG Nerd Font Installation | ❌ Exit |
| Terminal-Profil | Importiert `tshofmann.terminal` als Standard | ⚠️ Warnung |
| Starship-Theme | Generiert `~/.config/starship.toml` | ⚠️ Warnung |
| ZSH-Sessions | Prüft SHELL_SESSIONS_DISABLE in ~/.zshenv | ⚠️ Warnung |

> **Idempotenz:** Das Skript kann beliebig oft ausgeführt werden – bereits installierte Komponenten werden erkannt und übersprungen.

> **⏱️ Timeout-Konfiguration:** Der Terminal-Profil-Import wartet standardmäßig 20 Sekunden auf Bestätigung. Bei langsamen Systemen oder VMs kann dies erhöht werden:
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

### Was diese Befehle machen

| Flag | Bedeutung |
|------|-----------|
| `--adopt` | Übernimmt existierende Dateien (z.B. `~/.zshrc`) ins Repository |
| `-R` | Restow – aktualisiert bestehende Symlinks |
| `git reset --hard HEAD` | Stellt die Repository-Version wieder her |

> ⚠️ **ACHTUNG:** Der Befehl `git reset --hard HEAD` verwirft **alle lokalen Änderungen** im Repository **unwiderruflich**!

### Eigene Änderungen sichern

Falls du bereits eigene Anpassungen an den Dotfiles hast:

```zsh
# Vor dem Stow-Befehl
git stash                # Änderungen temporär sichern

# Nach dem Stow-Befehl
stow --adopt -R terminal
git stash pop            # Änderungen wiederherstellen
```

### Automatische Stow-Konfiguration

Die Datei `.stowrc` im Repository-Root konfiguriert Stow automatisch:

```
--ignore=\.DS_Store
--ignore=^\._
--ignore=\.localized
--ignore=starship\.toml
--no-folding
--target=~
```

Du musst diese Flags nicht manuell angeben.

---

## Ergebnis: Symlink-Übersicht

Nach erfolgreicher Installation sind folgende Symlinks aktiv:

| Symlink | Ziel | Zweck |
|---------|------|-------|
| `~/.zshenv` | `terminal/.zshenv` | Umgebungsvariablen (wird zuerst geladen) |
| `~/.zprofile` | `terminal/.zprofile` | Login Shell (Homebrew Init) |
| `~/.zshrc` | `terminal/.zshrc` | Interactive Shell Konfiguration |
| `~/.zlogin` | `terminal/.zlogin` | Post-Login (Background-Optimierungen) |
| `~/.config/alias/*.alias` | `terminal/.config/alias/*.alias` | 8 Alias-Dateien (homebrew, eza, bat, ripgrep, fd, fzf, fzf-tab, btop) |
| `~/.config/fzf/config` | `terminal/.config/fzf/config` | fzf globale Optionen |
| `~/.config/bat/config` | `terminal/.config/bat/config` | bat Theme und Style |
| `~/.config/ripgrep/config` | `terminal/.config/ripgrep/config` | ripgrep Defaults |
| `~/.config/fd/ignore` | `terminal/.config/fd/ignore` | fd globale Ignore-Patterns |

### Symlinks prüfen

```zsh
# Alle Shell-Konfigurationsdateien
ls -la ~/.zshenv ~/.zprofile ~/.zshrc ~/.zlogin

# Alias- und Tool-Konfigurationen
ls -la ~/.config/alias/ ~/.config/fzf/ ~/.config/bat/ ~/.config/ripgrep/ ~/.config/fd/
```

---

## Installation validieren

Der Health-Check hilft dir zu überprüfen, ob alle Komponenten korrekt installiert sind.

### Wann ausführen?

| Situation | Empfehlung |
|-----------|------------|
| Nach der Erstinstallation | ✅ Empfohlen – bestätigt erfolgreiche Installation |
| Nach `stow --adopt -R terminal` | ✅ Empfohlen – prüft ob Symlinks korrekt sind |
| Bei Problemen (Icons fehlen, Aliase funktionieren nicht) | ✅ Erste Anlaufstelle zur Diagnose |
| Nach macOS-Update | Optional – bei Problemen |
| Nach `brew upgrade` | Optional – bei Problemen |

### Ausführung

```zsh
# Im dotfiles-Verzeichnis ausführen
cd ~/dotfiles
./scripts/health-check.sh
```

### Was wird geprüft?

> **Dynamische Erkennung:** Der Health-Check erkennt automatisch neue Dateien im Repository. Wenn du eine neue Alias-Datei oder Tool-Konfiguration hinzufügst, wird sie automatisch geprüft.

| Komponente | Prüfung | Quelle |
|------------|---------|--------|
| **ZSH-Symlinks** | `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin` | `terminal/.z*` (dynamisch) |
| **Alias-Symlinks** | Alle `*.alias` Dateien | `terminal/.config/alias/` (dynamisch) |
| **Tool-Configs** | Alle `config`/`ignore` Dateien | `terminal/.config/*/` (dynamisch) |
| **CLI-Tools** | Alle Formulae aus Brewfile | `setup/Brewfile` (dynamisch) |
| **ZSH-Plugins** | zsh-syntax-highlighting, zsh-autosuggestions, fzf-tab | Homebrew + ~/.config/zsh/plugins/ |
| **Nerd Font** | MesloLG Nerd Font | `~/Library/Fonts/` |
| **Terminal-Profil** | `tshofmann` als Standard | Terminal.app defaults |
| **Starship** | `~/.config/starship.toml` vorhanden | Dateisystem |
| **ZSH-Sessions** | `SHELL_SESSIONS_DISABLE=1` | `~/.zshenv` |
| **Brewfile** | Alle Abhängigkeiten erfüllt | `brew bundle check` |

### Ergebnis interpretieren

**✅ Alle Prüfungen bestanden:**
```
✅ Health Check erfolgreich
   Alle Komponenten korrekt installiert.
```
→ Alles in Ordnung, keine Aktion erforderlich.

**⚠️ Warnungen:**
```
⚠️ Health Check mit Warnungen abgeschlossen
   Das Setup funktioniert, aber einige optionale Komponenten fehlen.
```
→ Das Setup funktioniert grundsätzlich. Warnungen betreffen meist optionale Komponenten (z.B. `mas` nicht installiert) oder Einstellungen, die beim nächsten Login aktiv werden.

**❌ Fehler:**
```
❌ Health Check fehlgeschlagen
   Behebe die Fehler und führe den Check erneut aus.
```
→ Mindestens eine kritische Komponente fehlt. Lies die Fehlermeldungen und:
1. Führe `stow --adopt -R terminal && git reset --hard HEAD` aus (bei Symlink-Fehlern)
2. Führe `brew bundle` aus (bei fehlenden Tools)
3. Siehe [Troubleshooting](troubleshooting.md) für spezifische Probleme

---

## Nächste Schritte

- [Konfiguration anpassen](configuration.md) – Starship-Theme ändern
- [Tools-Übersicht](tools.md) – Installierte CLI-Tools kennenlernen

---

## Probleme?

Falls etwas nicht funktioniert, siehe [Troubleshooting](troubleshooting.md).

---

[← Zurück zur Übersicht](../README.md)
