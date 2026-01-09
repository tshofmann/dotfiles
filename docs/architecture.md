# 🏗️ Architektur

Technische Details zur Struktur und Funktionsweise dieses dotfiles-Repositories.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Die Verzeichnisstruktur wird dynamisch aus dem Dateisystem erzeugt.

---

## Verzeichnisstruktur

```
dotfiles/
├── .githooks/
│   └── pre-commit # Verhindert Commits mit veralteter Dokumentation
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── config.yml
│   │   └── feature_request.md
│   ├── workflows/
│   │   └── validate.yml # Validiert Shell-Syntax, Dokumentation und Alias-Format
│   ├── CODEOWNERS
│   ├── CODE_OF_CONDUCT.md # Verhaltenskodex
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── SECURITY.md # Sicherheitsrichtlinie
│   ├── copilot-instructions.md # Instructions für dotfiles
│   └── dependabot.yml # Hält GitHub Actions automatisch aktuell
├── .gitattributes # Zeilenenden und Dateibehandlung normalisieren
├── .gitignore # Dateien von Versionskontrolle ausschließen
├── .stowrc # Ignore-Patterns und Standard-Optionen für GNU Stow
├── docs/
│   ├── architecture.md # Architektur
│   ├── configuration.md # Konfiguration
│   ├── installation.md # Installation
│   └── tools.md # Tools
├── scripts/
│   ├── generators/
│   │   ├── architecture.sh # Generiert Architektur-Dokumentation aus Verzeichnisstruktur
│   │   ├── configuration.sh # Generiert Konfigurations-Dokumentation aus Config-Dateien
│   │   ├── installation.sh # Generiert Installationsdokumentation aus bootstrap.sh
│   │   ├── lib.sh # Parser, Hilfsfunktionen, Konfiguration
│   │   ├── readme.sh # Generiert Haupt-README aus Template + dynamischen Daten
│   │   ├── tldr.sh # Generiert tldr-Patches aus .alias-Dateien
│   │   └── tools.sh # Generiert Tool-Dokumentation aus .alias-Dateien
│   ├── tests/
│   │   └── test_generators.sh # Testet Parser-Funktionen aus scripts/generators/lib.sh
│   ├── generate-docs.sh # Generiert alle Dokumentation aus Code-Kommentaren
│   └── health-check.sh # Prüft ob alle Komponenten korrekt INSTALLIERT sind
├── setup/
│   ├── Brewfile # Deklarative Homebrew-Abhängigkeiten (CLI-Tools & Font)
│   ├── Catppuccin Mocha.xccolortheme # Xcode Theme
│   ├── bootstrap.sh # Homebrew, CLI-Tools, Nerd Font & Terminal-Profil
│   └── catppuccin-mocha.terminal # Terminal.app Profil
├── terminal/
│   ├── .config/
│   │   ├── alias/
│   │   │   ├── bat.alias # Aliase für bat mit verschiedenen Ausgabe-Stilen
│   │   │   ├── brew.alias # Aliase für Homebrew Paketverwaltung
│   │   │   ├── btop.alias # Aliase für btop – moderner top/htop-Ersatz
│   │   │   ├── dotfiles.alias # Zentrale Einstiegspunkte für dotfiles-Hilfe
│   │   │   ├── eza.alias # Aliase für eza mit Icons und Git-Integration
│   │   │   ├── fastfetch.alias # Aliase für fastfetch – schnelle System-Übersicht
│   │   │   ├── fd.alias # Aliase für fd – schnelle Alternative zu find
│   │   │   ├── fzf.alias # Tool-unspezifische fzf-Utilities
│   │   │   ├── gh.alias # Interaktive GitHub-Workflows mit gh CLI
│   │   │   ├── git.alias # Aliase für häufige Git-Operationen
│   │   │   ├── rg.alias # Aliase für ripgrep mit häufig genutzten Optionen
│   │   │   └── zoxide.alias # Funktionen für zoxide mit fzf-Integration
│   │   ├── bat/
│   │   │   ├── themes/
│   │   │   │   └── Catppuccin Mocha.tmTheme # Syntax-Theme (XML)
│   │   │   └── config # Native bat-Konfiguration (cat mit Syntax-Highlighting)
│   │   ├── btop/
│   │   │   ├── themes/
│   │   │   │   └── catppuccin_mocha.theme
│   │   │   └── btop.conf
│   │   ├── eza/
│   │   │   └── theme.yml # Dateityp-Farben für eza (ls-Ersatz)
│   │   ├── fastfetch/
│   │   │   └── config.jsonc
│   │   ├── fd/
│   │   │   └── ignore # Globale Ausschlüsse für fd (auch bei --hidden)
│   │   ├── fzf/
│   │   │   ├── config # Native fzf-Konfiguration (FZF_DEFAULT_OPTS_FILE)
│   │   │   ├── fa-preview # Preview-Befehle für fa (Alias-Browser) in fzf
│   │   │   ├── fkill-list # Generiert Prozessliste für fzf (Apps oder Alle)
│   │   │   ├── fman-preview # Generiert man oder tldr Preview für fzf
│   │   │   ├── fzf-lib # Geteilte Utilities für fa-preview etc.
│   │   │   ├── init.zsh # fzf Keybindings und fd-Backend aktivieren
│   │   │   ├── preview-dir # Zeigt Verzeichnisinhalt mit eza/ls (Shell-Injection-sicher)
│   │   │   ├── preview-file # Zeigt Dateiinhalt mit bat/cat (Shell-Injection-sicher)
│   │   │   └── safe-action # Führt Aktionen Shell-Injection-sicher aus
│   │   ├── lazygit/
│   │   │   └── config.yml # lazygit Konfiguration mit Catppuccin Mocha Theme
│   │   ├── ripgrep/
│   │   │   └── config # Native ripgrep-Konfiguration (RIPGREP_CONFIG_PATH)
│   │   ├── tealdeer/
│   │   │   ├── pages/
│   │   │   │   ├── bat.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   ├── brew.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   ├── btop.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   ├── dotfiles.page.md # dotfiles
│   │   │   │   ├── eza.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   ├── fastfetch.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   ├── fd.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   ├── fzf.patch.md # Globale Tastenkürzel (in allen fzf-Dialogen)
│   │   │   │   ├── gh.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   ├── git.patch.md # tldr-Patch (auto-generiert)
│   │   │   │   └── rg.patch.md # tldr-Patch (auto-generiert)
│   │   │   └── config.toml # Vereinfachte Man-Pages mit Beispielen (tldr)
│   │   ├── zsh/
│   │   │   └── catppuccin_mocha-zsh-syntax-highlighting.zsh
│   │   └── shell-colors # Zentrale ANSI-Farbvariablen für Shell-Funktionen
│   ├── .zlogin # Aufgaben nach dem Login (läuft nach .zshrc)
│   ├── .zprofile # Umgebungsvariablen für Login-Shells (einmalig)
│   ├── .zshenv # Umgebungsvariablen die VOR allen anderen Configs geladen werden
│   └── .zshrc # Hauptkonfiguration für interaktive ZSH Shells
├── CONTRIBUTING.md # Contributing
├── LICENSE # MIT Lizenz
└── README.md # dotfiles
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

## Setup-Datei-Erkennung

Bootstrap erkennt Theme-Dateien automatisch nach Dateiendung:

| Dateiendung | Sortiert | Warnung bei mehreren |
|-------------|----------|----------------------|
| `.terminal` | Ja | Ja |
| `.xccolortheme` | Ja | Ja |

**Aktuell in `setup/`:** `catppuccin-mocha.terminal`

Dies ermöglicht:
- Freie Benennung der Theme-Dateien
- Deterministisches Verhalten (alphabetisch erste bei mehreren)
- Explizite Warnung wenn mehrere Dateien existieren

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
                               ├── zsh-syntax-highlighting
                               └── Xcode Theme
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
