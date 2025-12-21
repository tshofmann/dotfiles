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
| Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit |
| Homebrew | Installiert/prüft Homebrew unter `/opt/homebrew` | ❌ Exit |
| Brewfile | Installiert CLI-Tools via `brew bundle` | ❌ Exit |
| MesloLG Nerd Font | Prüft Font-Installation | ❌ Exit |
| Terminal-Profil | Importiert `tshofmann.terminal` als Standard | ⚠️ Warnung |
| Starship-Theme | Generiert `~/.config/starship.toml` | ⚠️ Warnung |

> **Idempotenz:** Das Skript kann beliebig oft ausgeführt werden – bereits installierte Komponenten werden erkannt und übersprungen.

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
| `~/.zshrc` | `~/dotfiles/terminal/.zshrc` | Interactive Shell Konfiguration |
| `~/.zprofile` | `~/dotfiles/terminal/.zprofile` | Login Shell (Homebrew Init) |
| `~/.config/alias/homebrew.alias` | `~/dotfiles/terminal/.config/alias/homebrew.alias` | Homebrew Aliase |

### Symlinks prüfen

```zsh
ls -la ~/.zshrc ~/.zprofile ~/.config/alias/
```

---

## Nächste Schritte

- [Konfiguration anpassen](configuration.md) – Starship-Theme ändern
- [Tools-Übersicht](tools.md) – Installierte CLI-Tools kennenlernen

---

## Probleme?

Falls etwas nicht funktioniert, siehe [Troubleshooting](troubleshooting.md).

---

[← Zurück zur Übersicht](../README.md)
