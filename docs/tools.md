# 🛠️ Tools

Übersicht aller installierten CLI-Tools und verfügbaren Aliase.

---

## Installierte CLI-Tools

Diese Tools werden via Brewfile installiert:

| Tool | Beschreibung | Dokumentation |
|------|--------------|---------------|
| **bat** | `cat` mit Syntax-Highlighting und Git-Integration | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| **btop** | Moderner Ressourcen-Monitor (`top`/`htop`-Ersatz) | [github.com/aristocratos/btop](https://github.com/aristocratos/btop) |
| **eza** | Moderner `ls`-Ersatz mit Icons und Git-Status | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| **fd** | Schneller `find`-Ersatz (respektiert `.gitignore`) | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| **fzf** | Fuzzy Finder für Kommandozeile und Dateien | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| **gh** | GitHub CLI – Issues, PRs, Repos von der Kommandozeile | [cli.github.com](https://cli.github.com/) |
| **mas** | Mac App Store CLI – Apps installieren und updaten | [github.com/mas-cli/mas](https://github.com/mas-cli/mas) |
| **ripgrep** | Ultraschneller `grep`-Ersatz (respektiert `.gitignore`) | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **starship** | Schneller, anpassbarer Shell-Prompt | [starship.rs](https://starship.rs/) |
| **stow** | GNU Stow – Symlink-Manager für Dotfiles | [gnu.org/software/stow](https://www.gnu.org/software/stow/) |
| **zoxide** | Smarter `cd`-Ersatz – merkt sich häufige Verzeichnisse | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |

---

## Aliase

Verfügbare Aliase aus `~/.config/alias/`:

> **Guard-System:** Alle Tool-Aliase prüfen zuerst ob das jeweilige Tool installiert ist (`command -v`). Ist ein Tool nicht vorhanden, bleiben die originalen Befehle (`ls`, `cat`, `grep`) erhalten.

### homebrew.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `brewup` | `brew update && brew upgrade && mas upgrade && brew autoremove && brew cleanup` | Vollständiges System-Update (inkl. App Store) |
| `maso` | `mas outdated` | Zeige veraltete App Store Apps |
| `masu` | `mas upgrade` | Aktualisiere alle App Store Apps |
| `mass` | `mas search <name>` | Suche im App Store |
| `masi` | `mas install <id>` | Installiere App via ID |
| `masl` | `mas list` | Liste installierte Apps |

> **Hinweis:** Die mas-Aliase sind nur verfügbar wenn mas installiert ist. `brewup` enthält automatisch `mas upgrade` wenn mas vorhanden ist.

### fd.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `fdf` | `fd --type f` | Nur Dateien suchen |
| `fdd` | `fd --type d` | Nur Verzeichnisse suchen |
| `fdh` | `fd --hidden` | Inkl. versteckte Dateien |
| `fda` | `fd --hidden --no-ignore` | Alles (ignoriert nichts) |
| `fde` | `fd --extension <ext>` | Nach Erweiterung suchen |
| `fdx` | `fd --exec <cmd>` | Mit Ausführung |
| `fd0` | `fd --print0` | Null-separiert (für xargs -0) |
| `fdsh` | `fd --extension sh` | Shell-Skripte |
| `fdpy` | `fd --extension py` | Python-Dateien |
| `fdjs` | `fd -e js -e ts` | JavaScript/TypeScript |
| `fdmd` | `fd --extension md` | Markdown-Dateien |
| `fdjson` | `fd --extension json` | JSON-Dateien |
| `fdyaml` | `fd -e yaml -e yml` | YAML-Dateien |

> **Hinweis:** fd respektiert automatisch `.gitignore` und ist deutlich schneller als find.

### btop.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `top` | `btop` | top durch btop ersetzen |
| `htop` | `btop` | htop durch btop ersetzen |
| `btop-low` | `btop --low-color` | Weniger Farben (einfache Terminals) |

> **Hinweis:** btop bietet CPU, RAM, Disk, Netzwerk und Prozess-Überwachung in einer ansprechenden TUI.

### eza.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ls` | `eza --icons=auto --group-directories-first` | ls-Ersatz mit Icons |
| `ll` | `eza -l --icons=auto --group-directories-first --header` | Ausführliche Auflistung |
| `la` | `eza -la --icons=auto --group-directories-first --header` | Alle Dateien inkl. versteckter |
| `lsg` | `eza -l --icons=auto --git --header` | Long-Format mit Git-Status |
| `lag` | `eza -la --icons=auto --git --header` | Alle Dateien mit Git-Status |
| `lt` | `eza --tree --icons=auto --level=2` | Baumansicht (2 Ebenen) |
| `lt3` | `eza --tree --icons=auto --level=3` | Baumansicht (3 Ebenen) |
| `lss` | `eza -l --icons=auto --sort=size --reverse --header` | Sortiert nach Größe |
| `lst` | `eza -l --icons=auto --sort=modified --reverse --header` | Sortiert nach Datum |

> **Hinweis:** `--icons=auto` erkennt automatisch ob das Terminal Icons unterstützt. Ordner werden immer zuerst angezeigt (`--group-directories-first`).

### bat.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `cat` | `bat -pp` | cat-Ersatz: Plain + kein Pager |
| `catp` | `bat --paging=never` | Mit Highlighting, ohne Pager |
| `catn` | `bat --style=numbers --paging=never` | Nur Zeilennummern |
| `catd` | `bat --diff` | Mit Git-Diff-Markierungen |
| `bat-themes` | `bat --list-themes` | Verfügbare Themes auflisten |
| `bat-langs` | `bat --list-languages` | Verfügbare Sprachen auflisten |
| `bat-preview` | `bat --list-themes \| fzf ...` | Theme-Vorschau (benötigt fzf) |

> **Hinweis:** `-pp` ist die Kurzform für `--style=plain --paging=never` – verhält sich wie das echte `cat`.

### ripgrep.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `rgs` | `rg --smart-case` | Smart-Case Suche (empfohlen) |
| `rgc` | `rg --smart-case -C 3` | Suche mit Kontext (3 Zeilen) |
| `rgi` | `rg --ignore-case` | Case-insensitive (immer) |
| `rga` | `rg -uuu` | Alle Dateien (ignoriert nichts) |
| `rgh` | `rg --hidden` | Inkl. versteckte Dateien |
| `rgl` | `rg --files-with-matches` | Nur Dateinamen mit Treffern |
| `rgn` | `rg --count` | Treffer-Anzahl pro Datei |
| `rgts` | `rg --smart-case -t ts -t js` | TypeScript/JavaScript |
| `rgpy` | `rg --smart-case -t py` | Python |
| `rgmd` | `rg --smart-case -t md` | Markdown |
| `rgsh` | `rg --smart-case -t sh` | Shell-Skripte |
| `rgrb` | `rg --smart-case -t ruby` | Ruby |
| `rggo` | `rg --smart-case -t go` | Go |

> **Hinweis:** `--smart-case` ist case-insensitive wenn der Suchbegriff nur Kleinbuchstaben enthält, sonst case-sensitive.

### Verwendung

```zsh
# System aktualisieren
brewup

# Was wird aktualisiert? (Vorschau)
brew outdated
```

---

## Tool-Nutzung

### eza – Moderner ls-Ersatz

```zsh
# Basis-Auflistung (Ordner zuerst, Icons automatisch)
ls                 # eza --icons=auto --group-directories-first

# Ausführliche Auflistung
ll                 # Long-Format mit Header
la                 # Alle Dateien inkl. versteckter

# Mit Git-Integration (in Git-Repos)
lsg                # Long-Format mit Git-Status
lag                # Alle Dateien mit Git-Status

# Baumansicht
lt                 # 2 Ebenen tief
lt3                # 3 Ebenen tief

# Sortierung
lss                # Nach Größe (größte zuerst)
lst                # Nach Änderungsdatum (neueste zuerst)
```

> **Hinweis:** `--icons=auto` erkennt automatisch ob das Terminal Nerd Font Icons unterstützt.

---

### bat – cat mit Syntax-Highlighting

```zsh
# cat-Ersatz (Plain, kein Pager)
cat README.md          # bat -pp

# Mit Syntax-Highlighting (ohne Pager)
catp README.md         # bat --paging=never

# Mit Zeilennummern
catn config.yaml       # bat --style=numbers --paging=never

# Git-Diff hervorheben
git diff | bat

# Theme temporär wechseln
bat --theme="Dracula" file.py

# Theme-Vorschau mit fzf
bat-preview
```

> **Hinweis:** `-pp` = `--style=plain --paging=never` – verhält sich wie echtes `cat`.

---

### ripgrep (rg) – Schnelle Textsuche

```zsh
# Smart-Case Suche (empfohlen)
rgs "TODO"             # case-insensitive da alles klein
rgs "MyClass"          # case-sensitive da Großbuchstaben

# Mit Kontext (3 Zeilen vor/nach)
rgc "error"            # rg --smart-case -C 3

# Nur in bestimmten Dateitypen
rgts "function"        # TypeScript/JavaScript
rgpy "def "            # Python
rgmd "##"              # Markdown

# Alle Dateien durchsuchen (ignoriert nichts)
rga "password"         # rg -uuu

# Nur Dateinamen mit Treffern
rgl "TODO"             # rg --files-with-matches
```

> **Hinweis:** `--smart-case` ist Standard in den Dateityp-Aliassen.

---

### fd – Schneller find-Ersatz

```zsh
# Datei nach Name suchen
fd readme               # Findet README.md, readme.txt, etc.

# Nur Dateien oder Verzeichnisse
fdf config              # Nur Dateien
fdd src                 # Nur Verzeichnisse

# Inkl. versteckter Dateien
fdh .env                # Findet .env, .envrc, etc.

# Nach Erweiterung
fde md                  # Alle Markdown-Dateien
fdpy                    # Alle Python-Dateien
fdjs                    # JavaScript + TypeScript

# Mit Ausführung
fdx bat {}              # Jede Datei mit bat anzeigen
fd -e json -x jq . {}   # Alle JSON-Dateien formatieren

# Alles suchen (ignoriert nichts)
fda password            # Durchsucht auch .git/, node_modules/, etc.
```

> **Hinweis:** fd ist das Standard-Backend für fzf (konfiguriert in `.zshrc`). Alle fzf-Suchen nutzen automatisch fd.

---

### btop – Ressourcen-Monitor

```zsh
# Monitor starten (ersetzt top/htop)
top                    # Startet btop
btop                   # Direkt aufrufen

# Für einfache Terminals
btop-low               # Weniger Farben

# Navigation in btop:
# m         → Menü
# Esc       → Zurück
# q         → Beenden
# f         → Filter (Prozesse)
# k         → Kill (Prozess)
# +/-       → Sortierung ändern
```

> **Hinweis:** btop zeigt CPU, RAM, Disk, Netzwerk und Prozesse in einer ansprechenden TUI mit Graphen.

---

### mas – Mac App Store CLI

```zsh
# Veraltete Apps anzeigen
maso                   # mas outdated

# Alle Apps aktualisieren
masu                   # mas upgrade

# App suchen
mass "Xcode"           # Zeigt App-ID und Name

# App installieren (benötigt App-ID)
masi 497799835         # Installiert Xcode

# Installierte Apps auflisten
masl                   # Zeigt ID und Name
```

> **Hinweis:** `brewup` aktualisiert automatisch auch App Store Apps wenn mas installiert ist.

---

### fzf – Fuzzy Finder

**Tastenkombinationen:**

| Taste | Funktion | Vorschau |
|-------|----------|----------|
| `Ctrl+R` | History durchsuchen | – |
| `Ctrl+T` | Datei suchen und einfügen | bat (Syntax-Highlighting) |
| `Alt+C` | Verzeichnis wechseln (cd) | eza (Tree-Ansicht) |

**fd-Integration:**

fzf nutzt automatisch fd als Backend (konfiguriert in `.zshrc`):
- Schneller als Standard-`find`
- Respektiert `.gitignore`
- Zeigt versteckte Dateien (außer `.git/`)

```zsh
# Datei suchen und öffnen
vim $(fzf)

# History durchsuchen
# Ctrl+R drücken, tippen, Enter

# Datei suchen und in Kommandozeile einfügen
# Ctrl+T drücken → Vorschau mit bat

# Verzeichnis wechseln
# Alt+C drücken → Vorschau mit eza Tree

# In Pipe verwenden
cat file.txt | fzf
```

> **Hinweis:** Die Vorschau-Funktionen benötigen bat und eza (via Brewfile installiert).

### gh – GitHub CLI

Die GitHub CLI wird mit Tab-Completion geladen (konfiguriert in `.zshrc`).

**Tab-Completion:** Drücke `Tab` nach `gh` für Befehls-Vorschläge. Dies erfordert das ZSH Completion-System (`compinit`), das automatisch in `.zshrc` initialisiert wird.

```zsh
# Authentifizieren (einmalig)
gh auth login

# Repository klonen
gh repo clone owner/repo

# Issue erstellen
gh issue create

# Pull Request erstellen
gh pr create

# Status prüfen
gh pr status

# Tab-Completion nutzen
gh <Tab>              # Zeigt alle Befehle
gh pr <Tab>           # Zeigt PR-Unterbefehle
```

### zoxide – Smarter cd

**Befehle:**

| Befehl | Funktion | Vorschau |
|--------|----------|----------|
| `z <query>` | Zu Verzeichnis springen | – |
| `zi` | Interaktive Auswahl (fzf) | eza (Dateiliste) |

```zsh
# Verzeichnis wechseln (lernt mit der Zeit)
z dotfiles         # Springt zu ~/dotfiles
z doc              # Springt zu häufig besuchtem Verzeichnis mit "doc"

# Interaktive Auswahl mit fzf
zi                 # Zeigt Liste mit eza-Vorschau
```

> **Hinweis:** Die `zi`-Vorschau zeigt den Verzeichnisinhalt mit eza und Icons.

### starship – Shell Prompt

Starship läuft automatisch. Konfiguration erfolgt über `~/.config/starship.toml`.

```zsh
# Preset wechseln
starship preset tokyo-night -o ~/.config/starship.toml

# Verfügbare Presets
starship preset --list

# Config editieren
$EDITOR ~/.config/starship.toml
```

### Preset-Kompatibilität

| Preset | Nerd Font erforderlich? | Beschreibung |
|--------|------------------------|---------------|
| `catppuccin-powerline` | ✅ Ja | Standard-Preset dieses Setups |
| `gruvbox-rainbow` | ✅ Ja | Retro-Farbschema mit Icons |
| `tokyo-night` | ✅ Ja | Dunkles Theme mit Powerline |
| `no-nerd-font` | ❌ Nein | Für Terminals ohne Nerd Font |
| `plain-text-symbols` | ❌ Nein | ASCII-only, keine Spezialzeichen |

> 📖 Vollständige Liste: [starship.rs/presets](https://starship.rs/presets/)
>
> ⚠️ Bei Presets mit Nerd Font-Anforderung müssen Font und Terminal-Profil korrekt konfiguriert sein. Siehe [Architektur → Komponenten-Abhängigkeiten](architecture.md#komponenten-abhängigkeiten).

---

## Font

### MesloLG Nerd Font

| Eigenschaft | Wert |
|-------------|------|
| **Name** | MesloLGLDZ Nerd Font (Dotted Zero Variante) |
| **Installiert via** | `brew install --cask font-meslo-lg-nerd-font` |
| **Speicherort** | `~/Library/Fonts/` |
| **Zweck** | Icons und Powerline-Symbole im Terminal |

> **Hinweis:** MesloLG gibt es in mehreren Varianten: `NFM` (Mono), `NF`, `NFP` (Propo). Das Terminal-Profil verwendet die `LDZNF`-Variante (L = Large, DZ = Dotted Zero).

### Warum Nerd Fonts?

Nerd Fonts sind gepatchte Schriftarten mit zusätzlichen Glyphen:

- **Powerline-Symbole** – für Prompt-Segmente
- **Devicons** – Sprach- und Framework-Icons
- **Font Awesome** – Allgemeine Icons
- **Octicons** – GitHub-Icons

Diese werden von Starship und anderen modernen CLI-Tools verwendet.

### Alternative Fonts

Falls MesloLG nicht gefällt, andere Nerd Fonts installieren:

```zsh
# Suche verfügbare Nerd Fonts
brew search nerd-font

# Beispiele
brew install --cask font-fira-code-nerd-font
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-hack-nerd-font
```

> **Hinweis:** Nach Font-Änderung muss das Terminal-Profil angepasst werden:
> Terminal.app → Einstellungen → Profile → Text → Schrift ändern

---

## Eigene Tools hinzufügen

### Brewfile erweitern

```zsh
# Brewfile editieren
$EDITOR ~/dotfiles/setup/Brewfile

# Beispiel: bat (besseres cat) hinzufügen
echo 'brew "bat"' >> ~/dotfiles/setup/Brewfile

# Installieren (HOMEBREW_BUNDLE_FILE ist in .zprofile gesetzt)
brew bundle
```

### Eigene Aliase

Siehe [Konfiguration → Aliase erweitern](configuration.md#aliase-erweitern).

---

## Weiterführende Links

- [Homebrew Formulae](https://formulae.brew.sh/)
- [Nerd Fonts](https://www.nerdfonts.com/)
- [Starship Presets](https://starship.rs/presets/)

---

[← Zurück zur Übersicht](../README.md)
