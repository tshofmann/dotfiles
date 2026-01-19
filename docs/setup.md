# 🚀 Installation

Diese Anleitung führt dich durch die vollständige Installation der dotfiles auf einem frischen Apple Silicon Mac.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen in `setup/modules/*.sh` und `setup/Brewfile` vornehmen.

## Voraussetzungen

| Anforderung | Details |
| ----------- | ------- |
| **Apple Silicon Mac** | M1, M2, … (arm64) – Intel-Macs werden nicht unterstützt |
| **macOS 26+** | Tahoe oder neuer – getestet auf 26 (Tahoe) |
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
| ------ | ------------ | ---------- |
| Architektur-Check | Prüft ob arm64 (Apple Silicon) | ❌ Exit |
| Architektur-Check | Prüft ob arm64 (Apple Silicon) | ❌ Exit |
| macOS-Version-Check | Prüft ob macOS 26+ (Tahoe) installiert ist | ❌ Exit |
| Netzwerk-Check | Prüft Internetverbindung | ❌ Exit |
| Schreibrechte-Check | Prüft ob `$HOME` schreibbar ist | ❌ Exit |
| Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit |
| Build-Tools | Installiert Build-Essentials (Linux) | ❌ Exit |
| Homebrew | Installiert/prüft Homebrew unter `/opt/homebrew` | ❌ Exit |
| Brewfile | Installiert CLI-Tools via `brew bundle` | ❌ Exit |
| Stow Symlinks | Verlinkt terminal/ und editor/ Configs | ⚠️ Kritisch |
| Git Hooks | Aktiviert Pre-Commit Validierung | ✓ Schnell |
| Font-Verifikation | Prüft MesloLG Nerd Font Installation | ❌ Exit |
| Terminal-Profil | Importiert `catppuccin-mocha.terminal` als Standard | ⚠️ Warnung |
| Starship-Theme | Generiert `~/.config/starship.toml` | ⚠️ Warnung |
| bat Cache | Baut Theme-Cache für Syntax-Highlighting | ✓ Schnell |
| tldr Cache | Lädt tldr-Pages herunter | ⚠️ Netzwerk |
| Xcode-Theme | Installiert Catppuccin Mocha Theme | ⚠️ Warnung |
| ZSH-Sessions | Prüft SHELL_SESSIONS_DISABLE in ~/.zshenv | ⚠️ Warnung |

> **Idempotenz:** Das Skript kann beliebig oft ausgeführt werden – bereits installierte Komponenten werden erkannt und übersprungen.
>
> **⏱️ Timeout-Konfiguration:** Der Terminal-Profil-Import wartet standardmäßig 20 Sekunden auf Registrierung im System. Bei langsamen Systemen oder VMs kann dies erhöht werden:
>
> ```bash
> PROFILE_IMPORT_TIMEOUT=60 ./setup/bootstrap.sh
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
> **📦 Komponenten-Abhängigkeiten:** Terminal-Profil, Nerd Font und Starship-Preset sind eng gekoppelt. Wenn Icons als □ oder ? angezeigt werden, siehe [Troubleshooting](#troubleshooting) unten.

---

## Schritt 2: Terminal neu starten

Nach Abschluss des Bootstrap-Skripts:

**Terminal.app beenden und neu öffnen** (Cmd+Q, dann neu starten)

Das ist alles! Das Bootstrap-Skript hat bereits:

- ✅ Alle Konfigurationsdateien verlinkt (via Stow)
- ✅ Git-Hooks aktiviert
- ✅ bat-Cache für das Catppuccin Theme gebaut
- ✅ tldr-Pages heruntergeladen
- ✅ Kitty-Theme konfiguriert (falls installiert)

> **💡 Warum Terminal neu starten?** Terminal.app muss neu gestartet werden, damit das importierte Catppuccin-Mocha-Profil vollständig aktiv wird.

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

### Homebrew Formulae

| Paket | Beschreibung |
| ----- | ------------ |
| [`bat`](https://github.com/sharkdp/bat) | cat-Ersatz mit Syntax-Highlighting |
| [`btop`](https://github.com/aristocratos/btop) | Ressourcen-Monitor |
| [`eza`](https://github.com/eza-community/eza) | ls-Ersatz mit Git-Status und Icons |
| [`fastfetch`](https://github.com/fastfetch-cli/fastfetch) | System-Info |
| [`fd`](https://github.com/sharkdp/fd) | find-Ersatz, schnell und intuitiv |
| [`ffmpeg`](https://ffmpeg.org/) | Video/Audio-Codec |
| [`fzf`](https://github.com/junegunn/fzf) | Fuzzy Finder |
| [`gh`](https://cli.github.com/) | GitHub CLI |
| [`imagemagick`](https://imagemagick.org/) | Bild-Manipulation |
| [`lazygit`](https://github.com/jesseduffield/lazygit) | Git-TUI |
| [`markdownlint-cli2`](https://github.com/DavidAnson/markdownlint-cli2) | Markdown-Linter |
| [`poppler`](https://poppler.freedesktop.org/) | PDF-Rendering |
| [`resvg`](https://github.com/RazrFalcon/resvg) | SVG-Rendering |
| [`ripgrep`](https://github.com/BurntSushi/ripgrep) | grep-Ersatz, schnellste Textsuche |
| [`sevenzip`](https://7-zip.org/) | Archiv-Extraktion |
| [`shellcheck`](https://www.shellcheck.net/) | Shell-Script-Linter (für Bash) |
| [`starship`](https://starship.rs/) | Shell-Prompt |
| [`stow`](https://www.gnu.org/software/stow/) | Symlink-Manager |
| [`tealdeer`](https://tealdeer-rs.github.io/tealdeer/) | tldr-Client |
| [`yazi`](https://yazi-rs.github.io/) | File Manager |
| [`zoxide`](https://github.com/ajeetdsouza/zoxide) | Smartes cd mit Frecency |
| [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) | History-Vorschläge |
| [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting) | Syntax-Highlighting |
| [`mas`](https://github.com/mas-cli/mas) | Mac App Store CLI |

### Homebrew Casks

| Paket | Beschreibung |
| ----- | ------------ |
| [`claude-code`](https://docs.anthropic.com/en/docs/claude-code) | Agentic Coding |
| [`kitty`](https://sw.kovidgoyal.net/kitty/) | GPU-Terminal mit Image-Support |
| [`visual-studio-code`](https://code.visualstudio.com/) | Editor |
| [`font-meslo-lg-nerd-font`](https://github.com/ryanoasis/nerd-fonts) | Nerd Font für Prompt, eza, yazi |

### Mac App Store

| Paket | Beschreibung |
| ----- | ------------ |
| [Xcode](https://apps.apple.com/app/id497799835) | Apple IDE |
| [Pages](https://apps.apple.com/app/id409201541) | Textverarbeitung |
| [Numbers](https://apps.apple.com/app/id409203825) | Tabellenkalkulation |
| [Keynote](https://apps.apple.com/app/id409183694) | Präsentationen |

> **Hinweis:** Die Anmeldung im App Store muss manuell erfolgen – die Befehle `mas account` und `mas signin` sind auf macOS 12+ nicht verfügbar.

---

## Technische Details

### XDG Base Directory Specification

Das Setup folgt der [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

| Variable | Pfad | Verwendung |
| -------- | ---- | ---------- |
| `XDG_CONFIG_HOME` | `~/.config` | Konfigurationsdateien |
| `XDG_DATA_HOME` | `~/.local/share` | Anwendungsdaten |
| `XDG_CACHE_HOME` | `~/.cache` | Cache-Dateien |

### Symlink-Strategie

GNU Stow mit `--no-folding` erstellt Symlinks für **Dateien**, nicht Verzeichnisse:

```zsh
# Stow mit --no-folding (via .stowrc)
stow --adopt -R terminal editor
```

Vorteile:

- Neue lokale Dateien werden nicht ins Repository übernommen
- Granulare Kontrolle über einzelne Dateien
- `.gitignore` in `~/.config/` bleibt erhalten

### Setup-Datei-Erkennung

Bootstrap erkennt Theme-Dateien automatisch nach Dateiendung:

| Dateiendung | Sortiert | Warnung bei mehreren |
| ----------- | -------- | -------------------- |
| `.terminal` | Ja | Ja |
| `.xccolortheme` | Ja | Ja |

Dies ermöglicht:

- Freie Benennung der Theme-Dateien
- Deterministisches Verhalten (alphabetisch erste bei mehreren)
- Explizite Warnung wenn mehrere Dateien existieren

---

## Troubleshooting

### Icon-Probleme (□ oder ?)

Bei fehlenden oder falschen Icons prüfen:

1. **Font in Terminal.app korrekt?** – `catppuccin-mocha` Profil muss MesloLG Nerd Font verwenden
2. **Nerd Font installiert?** – `brew list --cask | grep font`
3. **Terminal neu gestartet?** – Nach Font-Installation erforderlich
