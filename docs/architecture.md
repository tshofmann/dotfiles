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
│   └── tools.md                 # Tool-Übersicht
├── scripts/                     # Utility-Scripts
│   ├── health-check.sh          # Validierung der Installation
│   └── validate-docs.sh         # Docs-Code-Synchronisation prüfen
├── setup/
│   ├── bootstrap.sh             # Automatisiertes Setup-Skript
│   ├── Brewfile                 # Homebrew-Abhängigkeiten
│   └── tshofmann.terminal       # Terminal.app Profil
└── terminal/
    ├── .zshenv                  # Umgebungsvariablen (wird zuerst geladen)
    ├── .zprofile                # Login-Shell Konfiguration
    ├── .zshrc                   # Interactive Shell Konfiguration
    └── .config/
        ├── fzf/
        │   └── config           # fzf globale Optionen (FZF_DEFAULT_OPTS_FILE)
        ├── bat/
        │   └── config           # bat native Config
        ├── ripgrep/
        │   └── config           # ripgrep native Config (RIPGREP_CONFIG_PATH)
        └── alias/
            ├── homebrew.alias   # Homebrew + mas Aliase
            ├── eza.alias        # eza-Aliase (ls-Ersatz)
            ├── bat.alias        # bat-Aliase (cat-Ersatz)
            ├── ripgrep.alias    # ripgrep-Aliase (grep-Ersatz)
            ├── fd.alias         # fd-Aliase (find-Ersatz)
            ├── fzf.alias        # fzf Tool-Kombinationen (20+ Funktionen)
            └── btop.alias       # btop-Aliase (top-Ersatz)
```

> **Wichtig:** Das Bootstrap-Skript erwartet exakt diese Struktur. Es befindet sich in `setup/` und referenziert das übergeordnete Verzeichnis (`..`) als `DOTFILES_DIR`. Ein Verschieben oder Umbenennen der Ordner führt zu Fehlern.

---

## Designentscheidungen

### Nur Apple Silicon (arm64)

Dieses Repository unterstützt **ausschließlich Apple Silicon Macs**:

| Aspekt | Entscheidung |
|--------|--------------|
| **Homebrew-Pfad** | `/opt/homebrew` (nicht `/usr/local`) |
| **Architektur-Check** | Explizit am Skript-Anfang |
| **Netzwerk-Check** | Verbindungstest vor Installation |
| **Kompatibilität** | Keine Rosetta-Fallbacks |

**Gründe:**
- Vereinfachte Wartung (kein Dual-Path-Handling)
- Intel-Support würde Code-Komplexität erhöhen
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
│                   (tshofmann.terminal)                      │
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

> **Wichtig:** Die Datei `tshofmann.terminal` enthält Base64-kodierte NSArchiver-Daten (Apple plist-Format). Font-Einstellungen können **nicht** durch direktes Editieren geändert werden – nur über die Terminal.app GUI mit anschließendem Export.

Siehe [Konfiguration → Schriftart wechseln](configuration.md#schriftart-wechseln) für den vollständigen Workflow.

---

## Brewfile-Details

Das Setup verwendet `brew bundle` für deklaratives Package-Management:

```ruby
# setup/Brewfile

# CLI-Tools
brew "fzf"                       # Fuzzy Finder
brew "gh"                        # GitHub CLI
brew "stow"                      # Symlink-Manager
brew "starship"                  # Shell-Prompt
brew "zoxide"                    # Smartes cd
brew "mas"                       # Mac App Store CLI

# Moderne CLI-Ersetzungen
brew "eza"                       # ls-Ersatz mit Icons
brew "bat"                       # cat mit Syntax-Highlighting
brew "ripgrep"                   # grep-Ersatz
brew "fd"                        # find-Ersatz
brew "btop"                      # top-Ersatz

# ZSH-Plugins
brew "zsh-syntax-highlighting"
brew "zsh-autosuggestions"

# Font
cask "font-meslo-lg-nerd-font"

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

### Tool-Konfiguration

Die Tools nutzen **native Config-Dateien** für globale Einstellungen und Shell-Umgebungsvariablen für tool-spezifische Integrationen.

#### Native Config-Dateien

| Tool | Config-Datei | Env-Variable |
|------|--------------|--------------|
| **fzf** | `~/.config/fzf/config` | `FZF_DEFAULT_OPTS_FILE` |
| **bat** | `~/.config/bat/config` | (automatisch erkannt) |
| **ripgrep** | `~/.config/ripgrep/config` | `RIPGREP_CONFIG_PATH` |

**Vorteile:**
- Globale Defaults zentral verwaltet
- Funktionen in Alias-Dateien enthalten nur spezifische Optionen
- Konsistente Darstellung über alle fzf-Funktionen

#### fzf Globale Config (`~/.config/fzf/config`)

```
--height=50%
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
--type-add=alias:*.alias
--type-add=conf:*.conf
```

#### bat Config (`~/.config/bat/config`)

```
--theme="Monokai Extended"
--style="numbers,changes"
--paging=auto
--pager="less --RAW-CONTROL-CHARS --quit-if-one-screen"
--map-syntax "*.alias:Bash"
--map-syntax ".zshrc:Bash"
--map-syntax "Brewfile:Ruby"
```

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

## Weiterführende Links

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [ZSH Documentation](https://zsh.sourceforge.io/Doc/)
- [Starship Configuration](https://starship.rs/config/)

---

[← Zurück zur Übersicht](../README.md)
