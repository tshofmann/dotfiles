# 🏗️ Architektur

Technische Details zur Struktur und Funktionsweise dieses dotfiles-Repositories.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen an der Verzeichnisstruktur werden automatisch reflektiert.

---

## Verzeichnisstruktur

```
dotfiles/
├── README.md                    # Kurzübersicht & Quickstart
├── LICENSE                      # MIT Lizenz
├── .stowrc                      # Stow-Konfiguration
├── .gitignore                   # Git-Ignore-Patterns
├── .githooks/                   # Git Hooks (GitHub-Standard)
│   └── pre-commit               # Docs-Generierung vor Commit
├── docs/                        # Dokumentation
│   ├── installation.md          # Installationsanleitung
│   ├── configuration.md         # Anpassungen
│   ├── architecture.md          # Diese Datei
│   ├── tools.md                 # Tool-Übersicht
│   └── review-checklist.md      # Review-Prompt für Copilot
├── scripts/                     # Utility-Scripts
│   ├── health-check.sh          # Validierung der Installation
│   ├── generate-docs.sh         # Dokumentations-Generator
│   ├── generators/              # Generator-Module
│   │   ├── lib.sh               # Gemeinsame Bibliothek
│   │   ├── tools.sh             # tools.md Generator
│   │   ├── installation.sh      # installation.md Generator
│   │   ├── architecture.sh      # architecture.md Generator
│   │   ├── configuration.sh     # configuration.md Generator
│   │   ├── readme.sh            # README.md Generator
│   │   └── tldr.sh              # tldr-Patches Generator
│   └── tests/                   # Unit-Tests
│       ├── run-tests.sh         # Test-Runner
│       ├── test_lib.sh          # lib.sh Tests
│       └── test_validators.sh   # Validator-Modul Tests
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
        ├── alias/               # Tool-Aliase
        │   ├── bat.alias
        │   ├── brew.alias
        │   ├── btop.alias
        │   ├── eza.alias
        │   ├── fastfetch.alias
        │   ├── fd.alias
        │   ├── fzf.alias
        │   ├── gh.alias
        │   ├── git.alias
        │   └── rg.alias
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
        ├── fastfetch/
        │   └── config.jsonc     # fastfetch System-Info Konfiguration
        ├── fzf/
        │   ├── config           # fzf globale Optionen
        │   ├── init.zsh         # fzf Shell-Integration
        │   └── ...              # Helper-Skripte
        ├── lazygit/
        │   └── config.yml       # lazygit Config mit Catppuccin
        ├── ripgrep/
        │   └── config           # ripgrep globale Optionen
        ├── starship.toml        # Starship Prompt-Konfiguration
        ├── tealdeer/
        │   ├── config.toml      # tealdeer Konfiguration
        │   └── pages/           # Custom tldr-Patches
        └── zsh/
            └── catppuccin_mocha-zsh-syntax-highlighting.zsh
```

---

## Kern-Konzepte

### Single Source of Truth

Der Code ist die einzige Wahrheit. Alle Dokumentation wird automatisch generiert:

| Quelle | Generiert |
|--------|-----------|
| `.alias`-Dateien | tools.md, tldr-Patches |
| `Brewfile` | tools.md (CLI-Tools), installation.md |
| `bootstrap.sh` | installation.md |
| Config-Dateien | configuration.md |
| Verzeichnisstruktur | architecture.md |

### Dokumentations-Generator

Der Generator (`scripts/generate-docs.sh`) wird automatisch via Pre-Commit Hook ausgeführt:

```zsh
# Manuell ausführen
./scripts/generate-docs.sh --generate

# Nur prüfen (CI)
./scripts/generate-docs.sh --check
```

### Guard-System

Alle `.alias`-Dateien prüfen ob das jeweilige Tool installiert ist:

```zsh
# Guard am Anfang jeder .alias-Datei
if ! command -v tool >/dev/null 2>&1; then
    return 0
fi
```

So bleiben Original-Befehle (`ls`, `cat`) erhalten wenn ein Tool fehlt.

---

## XDG Base Directory Specification

Das Setup folgt der [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

| Variable | Pfad | Verwendung |
|----------|------|------------|
| `XDG_CONFIG_HOME` | `~/.config` | Konfigurationsdateien |
| `XDG_DATA_HOME` | `~/.local/share` | Anwendungsdaten |
| `XDG_CACHE_HOME` | `~/.cache` | Cache-Dateien |

---

## Symlink-Strategie

GNU Stow mit `--no-folding` erstellt Symlinks für **Dateien**, nicht Verzeichnisse:

```zsh
# Stow mit --no-folding (via .stowrc)
stow --adopt -R terminal
```

Vorteile:
- Neue lokale Dateien werden nicht ins Repository übernommen
- Granulare Kontrolle über einzelne Dateien
- `.gitignore` in `~/.config/` bleibt erhalten

---

## Komponenten-Abhängigkeiten

```
Terminal.app Profil
       │
       ├── MesloLG Nerd Font ──┬── Starship Icons
       │                       └── eza Icons
       │
       └── Catppuccin Mocha ───┬── bat Theme
                               ├── fzf Colors
                               ├── btop Theme
                               ├── eza Theme
                               └── zsh-syntax-highlighting
```

Bei Icon-Problemen (□ oder ?) prüfen:
1. Font in Terminal.app korrekt? (`catppuccin-mocha` Profil)
2. Nerd Font installiert? (`brew list --cask | grep font`)
3. Terminal neu gestartet?

---

## ZSH-Ladereihenfolge

```
.zshenv        # Immer (Umgebungsvariablen)
    │
    ├── Login-Shell?
    │       │
    │       └── .zprofile (PATH, EDITOR, etc.)
    │
    └── Interactive?
            │
            └── .zshrc (Aliase, Prompt, Keybindings)
                    │
                    └── .zlogin (Background-Tasks)
```
