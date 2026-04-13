# 🚀 Installation

Diese Anleitung führt dich durch die vollständige Installation der dotfiles.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen in `setup/modules/*.sh` und `setup/Brewfile` vornehmen.
>
> ⚠️ **Plattform-Status:** Auf **macOS** produktiv getestet. Linux-Bootstrap (Fedora, Debian, Arch) in Docker/Headless validiert – Desktop (Wayland) und echte Hardware noch ausstehend.

## Inhalt

- [Voraussetzungen](#voraussetzungen)
  - [macOS (getestet ✅)](#macos-getestet-)
  - [Linux (vorbereitet 🔧)](#linux-vorbereitet-)
  - [Wann wird `sudo` benötigt?](#wann-wird-sudo-benötigt)
- [Schritt 1: Install-Skript ausführen](#schritt-1-install-skript-ausführen)
  - [Was das Skript macht](#was-das-skript-macht)
- [Schritt 2: Terminal neu starten](#schritt-2-terminal-neu-starten)
- [Schritt 3: Verifizierung](#schritt-3-verifizierung)
- [Installierte Pakete](#installierte-pakete)
  - [Homebrew Formulae](#homebrew-formulae)
  - [Homebrew Casks](#homebrew-casks)
  - [Mac App Store](#mac-app-store)
- [Technische Details](#technische-details)
  - [XDG Base Directory Specification](#xdg-base-directory-specification)
  - [Symlink-Strategie](#symlink-strategie)
  - [Setup-Datei-Erkennung](#setup-datei-erkennung)
- [Troubleshooting](#troubleshooting)
  - [Icon-Probleme (□ oder ?)](#icon-probleme--oder-)
- [Deinstallation / Wiederherstellung](#deinstallation--wiederherstellung)
  - [Was passiert?](#was-passiert)
  - [Optionen](#optionen)
  - [Backup-Speicherort](#backup-speicherort)
  - [Was bleibt bestehen?](#was-bleibt-bestehen)
  - [Optional: Pakete & Repository entfernen](#optional-pakete--repository-entfernen)

## Voraussetzungen

### macOS (getestet ✅)

| Anforderung | Details |
| ----------- | ------- |
| **Apple Silicon oder Intel Mac** | arm64 (M1, M2, …) oder x86_64 |
| **macOS Tahoe (26+)** | Getestet auf Tahoe (26) |
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

```bash
curl -fsSL https://github.com/tshofmann/dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C ~ && mv ~/dotfiles-main ~/dotfiles && ~/dotfiles/setup/install.sh
```

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
| Architektur-Check | Prüft ob arm64 oder x86_64 | ❌ Exit |
| macOS-Version-Check | Prüft ob macOS Tahoe (26+) installiert ist | ❌ Exit |
| Debian-Version-Check | Prüft ob Debian Trixie (13+) auf 32-bit ARM | ❌ Exit |
| Netzwerk-Check | Prüft Internetverbindung | ❌ Exit |
| Schreibrechte-Check | Prüft ob `$HOME` schreibbar ist | ❌ Exit |
| Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit |
| Build-Tools | Installiert Build-Essentials (Linux) | ❌ Exit |
| Homebrew | Installiert/prüft Homebrew (arm64/x86_64/Linuxbrew) | ❌ Exit |
| Brewfile | Installiert CLI-Tools via `brew bundle` | ❌ Exit |
| APT-Pakete | Installiert verfügbare CLI-Tools via apt | ⚠️ Warnung |
| Cargo-Tools | Installiert fehlende Tools via cargo | ⚠️ Warnung |
| NPM-Tools | Installiert npm-Pakete (falls Node vorhanden) | ⚠️ Warnung |
| Binary-Symlinks | Erstellt Symlinks für abweichende Binary-Namen | ⚠️ Warnung |
| Backup | Sichert existierende Konfigurationen | 🔒 Sicher |
| Stow Symlinks | Verlinkt Dotfile-Packages dynamisch | ⚠️ Kritisch |
| Git Hooks | Aktiviert Pre-Commit Validierung | ✓ Schnell |
| Font-Verifikation | Prüft Nerd Font Installation | ❌ Exit |
| Terminal-Profil | Importiert `catppuccin-mocha.terminal` als Standard | ⚠️ Warnung |
| bat Cache | Baut Theme-Cache für Syntax-Highlighting | ✓ Schnell |
| tldr Cache | Lädt tldr-Pages herunter | ⚠️ Netzwerk |
| Xcode-Theme | Installiert Catppuccin Mocha Theme | ⚠️ Warnung |
| ZSH-Sessions | Prüft SHELL_SESSIONS_DISABLE in ~/.zshenv | ⚠️ Warnung |

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

### Homebrew Formulae

| Paket | Beschreibung |
| ----- | ------------ |
| [`bat`](https://github.com/sharkdp/bat) | cat-Ersatz mit Syntax-Highlighting |
| [`btop`](https://github.com/aristocratos/btop) | Ressourcen-Monitor |
| [`exiftool`](https://exiftool.org) | EXIF/Bild-Metadaten lesen und entfernen |
| [`eza`](https://github.com/eza-community/eza) | ls-Ersatz mit Git-Status und Icons |
| [`fastfetch`](https://github.com/fastfetch-cli/fastfetch) | System-Info |
| [`fd`](https://github.com/sharkdp/fd) | find-Ersatz, schnell und intuitiv |
| [`ffmpeg`](https://ffmpeg.org/) | Video/Audio-Codec |
| [`fzf`](https://github.com/junegunn/fzf) | Fuzzy Finder |
| [`gh`](https://cli.github.com/) | GitHub CLI |
| [`git-filter-repo`](https://github.com/newren/git-filter-repo) | Git-History umschreiben |
| [`imagemagick`](https://imagemagick.org/) | Bild-Manipulation |
| [`jq`](https://jqlang.org/) | JSON-Prozessor |
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
| [`github`](https://desktop.github.com/) | GitHub Desktop GUI |
| [`kitty`](https://sw.kovidgoyal.net/kitty/) | GPU-Terminal mit Image-Support |
| [`visual-studio-code`](https://code.visualstudio.com/) | Editor |
| [`font-jetbrains-mono-nerd-font`](https://github.com/ryanoasis/nerd-fonts) | Nerd Font |
| [`font-meslo-lg-nerd-font`](https://github.com/ryanoasis/nerd-fonts) | Nerd Font |

### Mac App Store

| Paket | Beschreibung |
| ----- | ------------ |
| [Keynote](https://apps.apple.com/app/id409183694) | Präsentationen |
| [Numbers](https://apps.apple.com/app/id409203825) | Tabellenkalkulation |
| [Pages](https://apps.apple.com/app/id409201541) | Textverarbeitung |
| [Pixelmator Pro](https://apps.apple.com/app/id1289583905) | Bildbearbeitung |
| [Xcode](https://apps.apple.com/app/id497799835) | Apple IDE |

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

1. **Nerd Font im Terminal?** – Terminal-Profil muss einen Nerd Font verwenden (z.B. JetBrainsMono Nerd Font)
2. **Nerd Font installiert?** – `brew list --cask | grep font`
3. **Terminal neu gestartet?** – Nach Font-Installation erforderlich

---

## Deinstallation / Wiederherstellung

Falls du die dotfiles-Installation rückgängig machen möchtest:

```zsh
~/dotfiles/setup/restore.sh
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
| `--cleanup`, `-c` | Erweiterte Deinstallation: Pakete + Repository entfernen |
| `--dry-run`, `-n` | Zeigt was `--cleanup` tun würde (keine Aktion) |
| `--help`, `-h` | Hilfe anzeigen |

### Backup-Speicherort

Das Backup wird beim ersten Bootstrap automatisch erstellt:

```text
~/dotfiles/.backup/
├── manifest.json    # Metadaten aller gesicherten Dateien
├── backup.log       # Protokoll der Backup-Operationen
└── home/            # Gesicherte Originaldateien (Struktur von ~)
```

> **Wichtig:** Das erste Backup wird NIE überschrieben (Idempotenz). Selbst bei mehrfacher Bootstrap-Ausführung bleibt das ursprüngliche Backup erhalten.
>
> **💡 Tipp:** Nach erfolgreicher Wiederherstellung kann das Backup manuell gelöscht werden: `rm -rf ~/dotfiles/.backup/`

### Was bleibt bestehen?

`restore.sh` entfernt nur Symlinks und stellt Backups wieder her. **Nicht entfernt** werden:

- Über Homebrew installierte Pakete (Formulae, Casks, Mac App Store Apps)
- Homebrew selbst
- Das Repository `~/dotfiles`

Das ist Absicht: Pakete könnten unabhängig von den dotfiles installiert worden sein oder von anderer Software benötigt werden.

### Optional: Pakete & Repository entfernen

Falls du auch die über das Brewfile installierten Pakete und das Repository entfernen möchtest, nutze den integrierten Cleanup-Befehl:

```zsh
~/dotfiles/setup/restore.sh --cleanup
```

Dieser führt nach der Wiederherstellung interaktiv durch:

1. **Formulae** – CLI-Tools (z.B. bat, eza, fzf, ripgrep)
2. **Casks** – GUI-Anwendungen (z.B. VS Code, Kitty)
3. **Mac App Store Apps** – Falls `mas` installiert ist
4. **Taps** – Homebrew-Repositories
5. **Repository** – Löscht `~/dotfiles` nach Bestätigung

Jede Kategorie wird einzeln abgefragt – du entscheidest, was entfernt wird.

> **💡 Tipp:** Mit `--dry-run` siehst du vorab, was entfernt würde:
>
> ```zsh
> ~/dotfiles/setup/restore.sh --cleanup --dry-run
> ```
>
> **Hinweis:** Homebrew selbst wird **nicht** deinstalliert. Falls gewünscht, folge der [offiziellen Anleitung](https://docs.brew.sh/FAQ#how-do-i-uninstall-homebrew).

<details>
<summary>Alternative: Manuell entfernen</summary>

**Schritt 1 – Prüfen, was entfernt würde:**

```zsh
brew bundle list --file=~/dotfiles/setup/Brewfile --all
```

**Schritt 2 – Pakete entfernen** (nur was du nicht mehr brauchst):

```zsh
brew uninstall bat eza fd fzf ripgrep   # Beispiel: einzelne Formulae
brew uninstall --cask kitty             # Beispiel: einzelne Casks
```

> ⚠️ **Vorsicht:** Entferne Pakete einzeln statt pauschal. Casks wie Visual Studio Code oder Kitty haben eigene Einstellungen und Daten, die bei der Deinstallation verloren gehen.

**Schritt 3 – Repository entfernen** (erst wenn alles geprüft ist):

```zsh
rm -rf ~/dotfiles
```

</details>
