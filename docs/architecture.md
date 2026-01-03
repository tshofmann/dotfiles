# 🏗️ Architektur

Technische Details zur Struktur und Funktionsweise dieses dotfiles-Repositories.

---

## Verzeichnisstruktur

```
dotfiles/
├── README.md                    # Kurzübersicht & Quickstart
├── LICENSE                      # MIT Lizenz
├── .stowrc                      # Stow-Konfiguration
├── .gitignore                   # Git-Ignore-Patterns
├── .githooks/                   # Git Hooks (GitHub-Standard)
│   └── pre-commit               # Docs-Validierung vor Commit
├── docs/                        # Dokumentation
│   ├── installation.md          # Installationsanleitung
│   ├── configuration.md         # Anpassungen
│   ├── troubleshooting.md       # Fehlerbehebung
│   ├── architecture.md          # Diese Datei
│   ├── tools.md                 # Tool-Übersicht
│   └── review-checklist.md      # Review-Prompt für Copilot
├── scripts/                     # Utility-Scripts
│   ├── health-check.sh          # Validierung der Installation
│   ├── validate-docs.sh         # Docs-Code-Synchronisation prüfen
│   └── validators/              # Modulare Validierungs-Komponenten
│       ├── lib.sh               # Shared Library (Logging, Registry)
│       ├── core/                # Kern-Validierungen (8 Module)
│       │   ├── macos.sh         # macOS-Kompatibilität
│       │   ├── bootstrap.sh     # Bootstrap-Skript
│       │   ├── brewfile.sh      # Brewfile-Pakete
│       │   ├── healthcheck.sh   # Health-Check-Tools
│       │   ├── starship.sh      # Starship-Prompt
│       │   ├── aliases.sh       # Alias-Anzahlen
│       │   ├── config.sh        # Config-Beispiele
│       │   └── symlinks.sh      # Symlink-Tabelle
│       └── extended/            # Erweiterte Validierungen (10 Module)
│           ├── alias-names.sh   # Alias-Namen vs. Code
│           ├── codeblocks.sh    # Shell-Commands in Docs
│           ├── copilot-instructions.sh # Copilot Instructions
│           ├── keybindings.sh   # Keybinding-Konsistenz
│           ├── readme.sh        # README Konsistenz
│           ├── structure.sh     # Verzeichnisstruktur
│           ├── style-consistency.sh # Code-Stil Konsistenz
│           ├── tealdeer-patches.sh  # Tealdeer-Patches vs. Aliase
│           ├── terminal-profile.sh  # Terminal-Profil
│           └── validator-count.sh   # Validator-Anzahl Konsistenz
├── setup/
│   ├── bootstrap.sh             # Automatisiertes Setup-Skript
│   ├── Brewfile                 # Homebrew-Abhängigkeiten
│   └── catppuccin-mocha.terminal  # Terminal.app Profil
└── terminal/
    ├── .zshenv                  # Umgebungsvariablen (wird zuerst geladen)
    ├── .zprofile                # Login-Shell Konfiguration
    ├── .zshrc                   # Interactive Shell Konfiguration
    ├── .zlogin                  # Post-Login (Background-Optimierungen)
    └── .config/
        ├── alias/               # Tool-Aliase (10 Dateien)
        │   ├── bat.alias        # bat-Aliase (cat-Ersatz)
        │   ├── btop.alias       # btop-Aliase (top-Ersatz)
        │   ├── eza.alias        # eza-Aliase (ls-Ersatz)
        │   ├── fastfetch.alias  # fastfetch-Aliase (neofetch-Ersatz)
        │   ├── fd.alias         # fd-Aliase (find-Ersatz)
        │   ├── fzf.alias        # fzf Tool-Kombinationen + fa()
        │   ├── gh.alias         # GitHub CLI Funktionen
        │   ├── git.alias        # Git-Aliase + lazygit
        │   ├── homebrew.alias   # Homebrew + mas Aliase + brewv()
        │   └── ripgrep.alias    # ripgrep-Aliase (grep-Ersatz)
        ├── shell-colors         # Catppuccin Mocha ANSI-Farbvariablen
        ├── bat/
        │   ├── config           # bat native Config
        │   └── themes/          # Catppuccin Mocha Theme
        ├── btop/
        │   ├── btop.conf        # btop Konfiguration
        │   └── themes/          # Catppuccin Mocha Theme
        ├── eza/
        │   └── theme.yml        # eza Catppuccin Theme
        ├── fd/
        │   └── ignore           # fd globale Ignore-Patterns
        ├── fzf/
        │   ├── config           # fzf globale Optionen (FZF_DEFAULT_OPTS_FILE)
        │   ├── fenv-reload      # Helper-Skript für fenv() Ctrl+S Toggle
        │   └── init.zsh         # fzf Shell-Integration (Keybindings, fd-Backend)
        ├── lazygit/
        │   └── config.yml       # lazygit Config mit Catppuccin Mocha
        ├── ripgrep/
        │   └── config           # ripgrep native Config (RIPGREP_CONFIG_PATH)
        ├── tealdeer/
        │   ├── config.toml      # tealdeer (tldr) Config mit Catppuccin Mocha
        │   └── pages/           # Custom tldr-Patches (10 Dateien, je Tool)
        └── zsh/
            └── catppuccin_mocha-zsh-syntax-highlighting.zsh  # Syntax-Highlighting Theme
```

> **Wichtig:** Das Bootstrap-Skript erwartet exakt diese Struktur. Es befindet sich in `setup/` und referenziert das übergeordnete Verzeichnis (`..`) als `DOTFILES_DIR`. Ein Verschieben oder Umbenennen der Ordner führt zu Fehlern.

---

## Designentscheidungen

### Nur Apple Silicon (arm64) + macOS 14+

Dieses Repository unterstützt **ausschließlich Apple Silicon Macs mit macOS 14 (Sonoma) oder neuer**:

| Aspekt | Entscheidung |
|--------|--------------|
| **Homebrew-Pfad** | `/opt/homebrew` (nicht `/usr/local`) |
| **Architektur-Check** | Explizit am Skript-Anfang (`uname -m`) |
| **macOS-Version-Check** | Mindestens Version 14 (`sw_vers -productVersion`) |
| **Netzwerk-Check** | Verbindungstest vor Installation |
| **Kompatibilität** | Keine Rosetta-Fallbacks, keine Legacy-Unterstützung |

**Gründe:**
- Vereinfachte Wartung (kein Dual-Path-Handling)
- Intel-Support würde Code-Komplexität erhöhen
- macOS 14+ entspricht [Homebrew Tier 1 Support](https://docs.brew.sh/Support-Tiers)
- Persönliches Setup – keine Notwendigkeit für Rückwärtskompatibilität

### Idempotenz

Das Bootstrap-Skript ist **idempotent** – es kann beliebig oft ausgeführt werden:

```zsh
# Sicher wiederholbar
./setup/bootstrap.sh
./setup/bootstrap.sh
./setup/bootstrap.sh  # Identisches Ergebnis
```

**Implementierung:**
- `command -v` prüft ob Tools bereits installiert
- `brew bundle` überspringt installierte Formulae
- Font-Check prüft Existenz vor Installation
- Terminal-Profil-Import ist wiederholbar

### XDG Base Directory Specification

Alle Tool-Konfigurationen folgen der [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/):

| Variable | Wert | Gesetzt in |
|----------|------|------------|
| `XDG_CONFIG_HOME` | `$HOME/.config` | `.zshenv` |
| `EZA_CONFIG_DIR` | `$XDG_CONFIG_HOME/eza` | `.zshenv` |
| `TEALDEER_CONFIG_DIR` | `$XDG_CONFIG_HOME/tealdeer` | `.zshenv` |
| `RIPGREP_CONFIG_PATH` | `$XDG_CONFIG_HOME/ripgrep/config` | `.zshrc` |
| `BAT_CONFIG_PATH` | (nutzt XDG automatisch) | – |

**macOS-Besonderheit:**

Die Rust-Library `dirs` gibt auf macOS `~/Library/Application Support` zurück statt `~/.config`. Tools wie `eza` nutzen diese Library und respektieren `XDG_CONFIG_HOME` nicht direkt. Daher wird `EZA_CONFIG_DIR` explizit in `.zshenv` gesetzt.

**Warum XDG:**
- Standardisierter Pfad für alle CLI-Tools
- Configs in `terminal/.config/` werden via Stow nach `~/.config/` verlinkt
- Keine Konflikte mit macOS-Standard (`~/Library/Application Support`)
- Einheitliche Struktur für alle Tools (bat, btop, fzf, ripgrep, eza, fd, gh)

### Stow statt manuelle Symlinks

[GNU Stow](https://www.gnu.org/software/stow/) verwaltet Symlinks deklarativ:

| Vorteil | Beschreibung |
|---------|--------------|
| **Deklarativ** | Struktur in `terminal/` spiegelt Ziel in `~` |
| **Sicher** | Erkennt Konflikte automatisch |
| **Reversibel** | `stow -D terminal` entfernt alle Symlinks |
| **Gruppiert** | Mehrere Packages möglich (`terminal`, `git`, etc.) |

**Konfiguration via `.stowrc`:**

```
--ignore=\.DS_Store
--ignore=^\._
--ignore=\.localized
--ignore=starship\.toml
--no-folding
--target=~
```

`--no-folding` verhindert, dass Stow ganze Verzeichnisse verlinkt statt einzelner Dateien. Das ist wichtig, damit andere Programme (nicht aus dem Repo) in denselben Verzeichnissen Dateien anlegen können.

> 📝 **Für Entwickler:** Git Hooks und Utility-Scripts sind in [CONTRIBUTING.md](../CONTRIBUTING.md) dokumentiert.

---

## Komponenten-Abhängigkeiten

Die visuelle Terminal-Darstellung basiert auf drei eng gekoppelten Komponenten:

```
┌─────────────────────────────────────────────────────────────┐
│                    Terminal.app Profil                      │
│                (catppuccin-mocha.terminal)                  │
│         Font: MesloLGLDZNerdFont (binär kodiert)            │
└────────────────────────┬────────────────────────────────────┘
                         │ referenziert
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              MesloLG Nerd Font (Homebrew Cask)              │
│      Enthält: Powerline-Symbole, Devicons, OS-Icons         │
└────────────────────────┬────────────────────────────────────┘
                         │ benötigt von
                         ▼
┌─────────────────────────────────────────────────────────────┐
│            Starship Preset (catppuccin-powerline)           │
│          Verwendet: , , 󰀵, , 󰈙 und weitere                  │
└─────────────────────────────────────────────────────────────┘
```

### Tool-Integrationen

```
┌─────────────────────────────────────────────────────────────┐
│                         fzf                                 │
│              Fuzzy Finder (Ctrl+T, Alt+C, Ctrl+R)           │
└──────────┬─────────────────┬─────────────────┬──────────────┘
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │     fd      │   │     bat     │   │     eza     │
    │  (Backend)  │   │  (Preview)  │   │  (Preview)  │
    │ Ctrl+T/Alt+C│   │   Ctrl+T    │   │    Alt+C    │
    └─────────────┘   └─────────────┘   └─────────────┘

┌─────────────────────────────────────────────────────────────┐
│                       zoxide (z, zi)                        │
└──────────┬─────────────────┬────────────────────────────────┘
           │                 │
    ┌──────▼──────┐   ┌──────▼──────┐
    │     fzf     │   │     eza     │
    │ (zi Auswahl)│   │  (Preview)  │
    └─────────────┘   └─────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    brewup (Alias)                           │
│         brew update → brew upgrade → mas upgrade →          │
│              brew autoremove → brew cleanup                 │
└─────────────────────────────────────────────────────────────┘
```

### Abhängigkeitsmatrix

| Wenn du änderst… | …musst du auch anpassen |  
|------------------|------------------------|
| **Nerd Font** (z.B. anderer Font-Name) | Terminal-Profil neu exportieren |
| **Starship-Preset** (auf eines mit Powerline-Symbolen) | Nerd Font muss installiert sein |
| **Terminal-Profil** | Muss auf installierten Nerd Font verweisen |
| **fd deinstallieren** | fzf fällt auf Standard-find zurück |
| **mas deinstallieren** | brewup funktioniert ohne App Store Updates |

### Technische Details

> **Wichtig:** Die Datei `catppuccin-mocha.terminal` enthält Base64-kodierte NSArchiver-Daten (Apple plist-Format). Font-Einstellungen können **nicht** durch direktes Editieren geändert werden – nur über die Terminal.app GUI mit anschließendem Export.

Siehe [Konfiguration → Schriftart wechseln](configuration.md#schriftart-wechseln) für den vollständigen Workflow.

---

## Brewfile-Details

Das Setup verwendet `brew bundle` für deklaratives Package-Management:

```ruby
# setup/Brewfile

# CLI-Tools
brew "fzf"                       # Fuzzy Finder
brew "gh"                        # GitHub CLI
brew "lazygit"                   # Terminal-UI für Git
brew "stow"                      # Symlink-Manager
brew "starship"                  # Shell-Prompt
brew "tealdeer"                  # tldr-Client
brew "zoxide"                    # Smartes cd
brew "mas"                       # Mac App Store CLI

# Moderne CLI-Ersetzungen
brew "eza"                       # ls-Ersatz mit Icons
brew "bat"                       # cat mit Syntax-Highlighting
brew "ripgrep"                   # grep-Ersatz
brew "fd"                        # find-Ersatz
brew "btop"                      # top-Ersatz
brew "fastfetch"                 # neofetch-Ersatz

# ZSH-Plugins
brew "zsh-syntax-highlighting"
brew "zsh-autosuggestions"

# Casks (Fonts & Tools)
cask "font-meslo-lg-nerd-font"
cask "claude-code"

# Mac App Store Apps (via mas)
mas "Xcode", id: 497799835
mas "Pages", id: 409201541
mas "Numbers", id: 409203825
mas "Keynote", id: 409183694
```

### Installationsverhalten

Das Skript verwendet spezifische Flags:

```zsh
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --file="$BREWFILE"
```

| Flag | Zweck |
|------|-------|
| `HOMEBREW_NO_AUTO_UPDATE=1` | Kein automatisches `brew update` |
| `--no-upgrade` | Bestehende Formulae nicht upgraden |

**Konsequenz:** Schnellere, reproduzierbare Installationen – aber defekte Formulae werden nicht automatisch repariert.

### Status prüfen

```zsh
# Prüfen ob alle Abhängigkeiten erfüllt sind
brew bundle check

# Detaillierte Liste
brew bundle list
```

> **Hinweis:** Die Umgebungsvariable `HOMEBREW_BUNDLE_FILE` (gesetzt in `.zprofile`) ermöglicht die Nutzung von `brew bundle` ohne `--file` Flag.

### Reparatur bei Problemen

```zsh
# Vollständige Reparatur
brew update && brew upgrade && brew autoremove && brew cleanup

# Dann erneut installieren
brew bundle
```

---

## Shell-Konfiguration

### `.zshenv` (Umgebungsvariablen)

Wird als **allererste** Datei bei jedem zsh-Start geladen (vor allen anderen):

```zsh
# macOS zsh Session-Wiederherstellung deaktivieren
SHELL_SESSIONS_DISABLE=1
```

| Variable | Zweck |
|----------|-------|
| `SHELL_SESSIONS_DISABLE` | Deaktiviert macOS Session-History in `~/.zsh_sessions/` |

> **Wichtig:** Diese Variable muss in `.zshenv` stehen, da `/etc/zshrc_Apple_Terminal` vor `.zprofile` und `.zshrc` geladen wird.

### `.zprofile` (Login-Shell)

Wird einmal beim Login ausgeführt:

```zsh
# Homebrew-Umgebung initialisieren
eval "$(/opt/homebrew/bin/brew shellenv)"

# Brewfile-Pfad für 'brew bundle'
export HOMEBREW_BUNDLE_FILE="$HOME/dotfiles/setup/Brewfile"
```

| Variable | Zweck |
|----------|-------|
| `HOMEBREW_PREFIX` | Homebrew-Installationspfad (`/opt/homebrew`) |
| `HOMEBREW_CELLAR` | Installierte Formulae |
| `HOMEBREW_REPOSITORY` | Homebrew Git-Repository |
| `HOMEBREW_BUNDLE_FILE` | Standard-Pfad für `brew bundle` |

### `.zshrc` (Interactive Shell)

Wird bei jeder neuen Terminal-Session ausgeführt:

1. **History-Konfiguration:** HISTFILE, HISTSIZE, SAVEHIST + setopt-Optionen
2. **Alias-Loading:** Lädt alle `*.alias` Dateien aus `~/.config/alias/`
3. **Tool-Initialisierung:** fzf, zoxide, gh, starship (mit `command -v` Guards)

```zsh
# Alias-Glob mit ZSH-Qualifiers
for alias_file in ~/.config/alias/*.alias(N-.on); do
    source "$alias_file"
done
```

| Qualifier | Bedeutung |
|-----------|-----------|
| `N` | NULL_GLOB – kein Fehler bei leerer Liste |
| `-` | Folge Symlinks |
| `.` | Nur reguläre Dateien |
| `on` | Sortiere nach Name |

### `.zlogin` (Post-Login)

Wird **nach** `.zshrc` geladen, nur bei Login-Shells:

```zsh
# Background-Kompilierung der Completion-Cache-Datei
{
    zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
    if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
        zcompile "$zcompdump"
    fi
} &!
```

| Aspekt | Beschreibung |
|--------|--------------|
| **Zweck** | Kompiliert `.zcompdump` zu `.zcompdump.zwc` im Hintergrund |
| **Timing** | Läuft NACH dem Prompt, blockiert nicht den Shell-Start |
| **`&!`** | Disown – Prozess läuft unabhängig weiter |
| **Bedingung** | Nur wenn `.zwc` fehlt oder älter als `.zcompdump` ist |

> **Hinweis:** Bei aktuellem Setup kein messbarer Performance-Unterschied (~0.1s). Die Optimierung ist eine "Zero-Cost Versicherung" für zukünftige Completions (kubectl, nvm, docker etc.).

### Tool-Konfiguration

Die Tools nutzen **native Config-Dateien** für globale Einstellungen und Shell-Umgebungsvariablen für tool-spezifische Integrationen.

#### Native Config-Dateien

| Tool | Config-Datei | Env-Variable |
|------|--------------|--------------|
| **fzf** | `~/.config/fzf/config` | `FZF_DEFAULT_OPTS_FILE` |
| **bat** | `~/.config/bat/config` | (automatisch erkannt) |
| **ripgrep** | `~/.config/ripgrep/config` | `RIPGREP_CONFIG_PATH` |
| **fd** | `~/.config/fd/ignore` | (automatisch erkannt) |
| **tealdeer** | `~/.config/tealdeer/config.toml` | `TEALDEER_CONFIG_DIR` |

**Vorteile:**
- Globale Defaults zentral verwaltet
- Funktionen in Alias-Dateien enthalten nur spezifische Optionen
- Konsistente Darstellung über alle fzf-Funktionen

#### fzf Globale Config (`~/.config/fzf/config`)

```
--height=~50%
--layout=reverse
--border=rounded
--margin=0,1
--color=header:italic
--color=prompt:bold
--preview-window=right:60%:wrap
--bind=ctrl-/:toggle-preview
--bind=ctrl-a:select-all
```

#### fzf Shell-Integration (in `.zshrc`)

| Variable | Wert | Beschreibung |
|----------|------|--------------|
| `FZF_DEFAULT_COMMAND` | `fd --type f ...` | Backend für Standard-Suche |
| `FZF_CTRL_T_OPTS` | `--preview 'bat ...'` | Datei-Vorschau mit Syntax-Highlighting |
| `FZF_ALT_C_OPTS` | `--preview 'eza --tree ...'` | Verzeichnis-Vorschau mit Baumansicht |

**Key Bindings:** `Ctrl+R` (History), `Ctrl+T` (Datei einfügen), `Alt+C` (cd)

#### ripgrep Config (`~/.config/ripgrep/config`)

```
--smart-case
--line-number
--heading
--type-add=zsh:*.zsh
--type-add=zsh:*.zshrc
--type-add=zsh:*.zprofile
--type-add=zsh:*.zshenv
--type-add=alias:*.alias
--type-add=conf:*.conf
--type-add=conf:*.config
--type-add=conf:*rc
```

#### fd Global Ignore (`~/.config/fd/ignore`)

Globale Ausschluss-Patterns für fd (auch bei `--hidden`), Auszug:

```
.git/
.DS_Store
._*
__MACOSX/
__pycache__/
node_modules/
dist/
build/
```

> **Tipp:** `fd -u` (unrestricted) ignoriert diese Datei komplett. Vollständige Liste: `cat ~/.config/fd/ignore`

#### bat Config (`~/.config/bat/config`)

```
--theme="Catppuccin Mocha"
--style="numbers,changes"
--paging=auto
--pager="less --RAW-CONTROL-CHARS --quit-if-one-screen"
--map-syntax "*.alias:Bash"
--map-syntax ".zshrc:Bash"
--map-syntax "Brewfile:Ruby"
```

> **Hinweis:** Das Catppuccin Mocha Theme liegt in `terminal/.config/bat/themes/` und wird via Stow verlinkt. Nach dem Stow-Befehl muss `bat cache --build` ausgeführt werden, um das Theme zu registrieren.

#### zoxide (Smarter cd)

| Variable | Wert | Beschreibung |
|----------|------|--------------|
| `_ZO_FZF_OPTS` | `--preview 'eza -la ...'` | Vorschau für `zi` (interaktive Auswahl) |

**Befehle:** `z <query>` (jump), `zi` (interaktiv mit fzf)

#### gh (GitHub CLI)

Lädt Tab-Completion via `source <(gh completion -s zsh)`.

#### starship (Prompt)

Initialisiert über `eval "$(starship init zsh)"`. Konfiguration in `~/.config/starship.toml`.

---

## Completion-System

### Initialisierung (compinit)

Das ZSH Completion-System ermöglicht Tab-Vervollständigung für Befehle, Optionen und Argumente:

```zsh
# Terminal
gh <Tab>       # zeigt: api, auth, browse, codespace, ...
gh pr <Tab>    # zeigt: checkout, close, comment, create, ...
```

### Optimierte Ladezeit

Die `.zshrc` verwendet einen optimierten Ansatz:

```zsh
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
    compinit -i                 # Volle Initialisierung wenn >24h alt
else
    compinit -i -C              # Cache nutzen wenn aktuell
fi
```

| Aspekt | Beschreibung |
|--------|--------------|
| **Cache-Datei** | `~/.zcompdump` – enthält kompilierte Completion-Definitionen |
| **24h-Check** | `(#qN.mh+24)` – Glob-Qualifier prüft Alter der Datei |
| **`-C` Flag** | Überspringt Rebuild, nutzt bestehenden Cache |
| **`-i` Flag** | Ignoriert unsichere Verzeichnisse (Homebrew) |

### Performance-Impact

| Modus | Startup-Zeit | Wann |
|-------|--------------|------|
| Mit Cache (`-C`) | ~90ms | Cache < 24h alt |
| Ohne Cache | ~140ms | Cache > 24h alt oder fehlt |

### Wichtige Reihenfolge

```
compinit → alias-files → fzf → zoxide → gh completion → starship
```

`compinit` muss **vor** `gh completion` geladen werden, da `gh completion -s zsh` die Funktion `compdef` verwendet.

---

## Starship-Konfiguration

### Preset-Generierung

```zsh
# Standard (catppuccin-powerline)
starship preset catppuccin-powerline -o ~/.config/starship.toml

# Mit benutzerdefiniertem Preset
STARSHIP_PRESET="tokyo-night" ./setup/bootstrap.sh
```

### Warum nicht versioniert?

`starship.toml` wird standardmäßig ausgeschlossen:

| Datei | Eintrag |
|-------|---------|
| `.gitignore` | `terminal/.config/starship.toml` |
| `.stowrc` | `--ignore=starship\.toml` |

**Gründe:**
- Preset wird dynamisch generiert
- Erlaubt lokale Anpassungen ohne Git-Konflikte
- Kann bei Bedarf versioniert werden (siehe [Konfiguration](configuration.md))

---

## Nicht-versionierte Konfigurationen

Einige Konfigurationen enthalten sensitive Daten oder werden dynamisch generiert und sind daher **nicht** im Repository enthalten:

### Sensitive Dateien (`~/.config/gh/`)

Die GitHub CLI speichert OAuth-Tokens und Session-Daten:

```
~/.config/gh/
├── config.yml      # Einstellungen (git_protocol, editor, aliases)
└── hosts.yml       # OAuth-Tokens für github.com (SENSITIVE!)
```

| Datei | Inhalt | Sensitivität |
|-------|--------|--------------|
| `config.yml` | Allgemeine Einstellungen | ⚠️ Kann versioniert werden |
| `hosts.yml` | OAuth-Tokens | 🔴 **Niemals versionieren!** |

**Wiederherstellung:** Nach `gh auth login` werden beide Dateien automatisch erstellt.

### Dynamisch generierte Dateien

| Datei | Generiert durch | Funktion |
|-------|-----------------|----------|
| `~/.config/starship.toml` | `starship preset catppuccin-powerline -o ~/.config/starship.toml` | Shell-Prompt Konfiguration |
| `~/.zoxide.db` | zoxide automatisch | Verzeichnis-History für `z` |
| `~/Library/Application Support/lazygit/config.yml` | Stow (symlinked von `~/.config/lazygit/`) | lazygit Theme + Einstellungen |

> **Hinweis:** `starship.toml` wird beim Bootstrap generiert. Lokale Anpassungen bleiben bei Updates erhalten, solange das Preset nicht erneut ausgeführt wird.

### Backup-Empfehlung

Für Rechner-Migration diese Dateien sichern (ohne OAuth-Tokens):

```zsh
# Sichere nicht-sensitive gh-Config
cp ~/.config/gh/config.yml ~/backup/

# hosts.yml NICHT sichern – neu authentifizieren mit:
# gh auth login
```

---

## Weiterführende Links

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [ZSH Documentation](https://zsh.sourceforge.io/Doc/)
- [Starship Configuration](https://starship.rs/config/)

---

[← Zurück zur Übersicht](../README.md)
