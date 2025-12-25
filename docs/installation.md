# 🚀 Installation

Diese Anleitung führt dich durch die vollständige Installation der dotfiles auf einem frischen Apple Silicon Mac.

## Voraussetzungen

| Anforderung | Details |
|-------------|---------|
| **Apple Silicon Mac** | M1, M2, … (arm64) – Intel-Macs werden nicht unterstützt |
| **macOS 26 (Tahoe)** | Ältere Versionen sind nicht getestet und können zu unerwarteten Fehlern führen |
| **Internetverbindung** | Für Homebrew-Installation und Download der Formulae/Casks |
| **Admin-Rechte** | `sudo`-Passwort erforderlich für Xcode CLI Tools Installation |

> **Hinweis:** Die Architektur-Prüfung erfolgt automatisch beim Start von `bootstrap.sh`. Bei Intel-Macs bricht das Skript mit einer Fehlermeldung ab.

---

## Schritt 1: Bootstrap-Skript ausführen

```zsh
git clone https://github.com/tshofmann/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./setup/bootstrap.sh
```

> ⚠️ **Wichtig:** Nach Abschluss des Bootstrap-Skripts wird das Terminal automatisch neu gestartet. Fahre danach mit Schritt 2 fort.

### Was das Skript macht

Das Bootstrap-Skript führt folgende Aktionen in dieser Reihenfolge aus:

| Aktion | Beschreibung | Bei Fehler |
|--------|--------------|------------|
| Architektur-Check | Prüft ob arm64 (Apple Silicon) | ❌ Exit |
| Netzwerk-Check | Prüft Internetverbindung | ❌ Exit |
| Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit |
| Homebrew | Installiert/prüft Homebrew unter `/opt/homebrew` | ❌ Exit |
| Brewfile | Installiert CLI-Tools via `brew bundle` | ❌ Exit |
| MesloLG Nerd Font | Prüft Font-Installation | ❌ Exit |
| Terminal-Profil | Importiert `tshofmann.terminal` als Standard | ⚠️ Warnung |
| Starship-Theme | Generiert `~/.config/starship.toml` | ⚠️ Warnung |
| ZSH-Sessions | Deaktiviert macOS Session-History | ✅ Immer |

> **Idempotenz:** Das Skript kann beliebig oft ausgeführt werden – bereits installierte Komponenten werden erkannt und übersprungen.

> **⏱️ Timeout-Konfiguration:** Der Terminal-Profil-Import wartet standardmäßig 20 Sekunden auf Bestätigung. Bei langsamen Systemen oder VMs kann dies erhöht werden:
> ```bash
> PROFILE_IMPORT_TIMEOUT=60 ./setup/bootstrap.sh
> ```

> **📦 Komponenten-Abhängigkeiten:** Terminal-Profil, Nerd Font und Starship-Preset sind eng gekoppelt. Wenn Icons als □ oder ? angezeigt werden, liegt es meist an einer fehlenden oder falschen Font-Konfiguration. Details: [Architektur → Komponenten-Abhängigkeiten](architecture.md#komponenten-abhängigkeiten)

---

## Schritt 2: Konfigurationsdateien verlinken

Nach dem Terminal-Neustart:

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
| `~/.zshrc` | `terminal/.zshrc` | Interactive Shell Konfiguration |
| `~/.zprofile` | `terminal/.zprofile` | Login Shell (Homebrew Init) |
| `~/.config/alias/*.alias` | `terminal/.config/alias/*.alias` | 7 Alias-Dateien (homebrew, eza, bat, ripgrep, fd, fzf, btop) |
| `~/.config/fzf/config` | `terminal/.config/fzf/config` | fzf globale Optionen |
| `~/.config/bat/config` | `terminal/.config/bat/config` | bat Theme und Style |
| `~/.config/ripgrep/config` | `terminal/.config/ripgrep/config` | ripgrep Defaults |

### Symlinks prüfen

```zsh
ls -la ~/.zshrc ~/.zprofile ~/.config/alias/
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
./setup/health-check.sh
```

### Was wird geprüft?

| Komponente | Prüfung |
|------------|---------|
| **Symlinks** | `.zshrc`, `.zprofile`, alle Alias-Dateien, Tool-Configs |
| **CLI-Tools** | fzf, stow, starship, zoxide, eza, bat, ripgrep, fd, btop, gh |
| **Nerd Font** | MesloLG Nerd Font in `~/Library/Fonts/` |
| **Terminal-Profil** | `tshofmann` als Standard- und Startup-Profil |
| **Starship** | `~/.config/starship.toml` vorhanden |
| **ZSH-Sessions** | `~/.zsh_sessions_disable` vorhanden |
| **Brewfile** | Alle Abhängigkeiten installiert |

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
