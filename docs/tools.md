# 🛠️ Tools

Übersicht aller installierten CLI-Tools und verfügbaren Aliase.

---

## Schnellreferenz für Einsteiger

Die wichtigsten Tastenkombinationen und Befehle auf einen Blick:

### Tastenkombinationen (global)

| Taste | Funktion | Beschreibung |
|-------|----------|--------------|
| `Ctrl+R` | History-Suche | Frühere Befehle fuzzy suchen |
| `Ctrl+T` | Datei einfügen | Datei suchen und in Kommandozeile einfügen |
| `Alt+C` | Verzeichnis wechseln | Interaktiv in Unterverzeichnis springen |
| `Tab` | Autovervollständigung | Befehle, Pfade, Optionen vervollständigen |
| `→` (Pfeil rechts) | Vorschlag übernehmen | zsh-autosuggestion akzeptieren |

### Die wichtigsten Aliase

| Alias | Statt | Funktion |
|-------|-------|----------|
| `ls` | `ls` | Dateien mit Icons anzeigen |
| `ll` | `ls -la` | Ausführliche Auflistung |
| `cat` | `cat` | Datei mit Syntax-Highlighting |
| `z <ort>` | `cd <pfad>` | Zu häufig besuchtem Verzeichnis springen |
| `brewup` | - | Alle Pakete + Apps aktualisieren |

### Erste Schritte nach der Installation

```zsh
# 1. System aktualisieren
brewup

# 2. Verzeichnis mit Icons anzeigen
ls

# 3. Datei mit Syntax-Highlighting anzeigen
cat ~/.zshrc

# 4. Frühere Befehle suchen (Ctrl+R drücken, tippen, Enter)

# 5. Zu einem Verzeichnis springen (lernt mit der Zeit)
z dotfiles
```

> 💡 **Tipp:** Alle Aliase haben Guard-Checks – fehlt ein Tool, funktioniert der Original-Befehl weiterhin.

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

### ZSH-Plugins

| Plugin | Beschreibung | Dokumentation |
|--------|--------------|---------------|
| **zsh-autosuggestions** | History-basierte Befehlsvorschläge beim Tippen | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| **zsh-syntax-highlighting** | Echtzeit Syntax-Highlighting für Kommandos | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |

### Mac App Store Apps

Diese Apps werden via `mas` installiert (Benutzer muss im App Store angemeldet sein):

| App | Beschreibung |
|-----|--------------|
| **Xcode** | Apple IDE für iOS/macOS Entwicklung |
| **Pages** | Textverarbeitung |
| **Numbers** | Tabellenkalkulation |
| **Keynote** | Präsentationen |

> **Hinweis:** Die Anmeldung im App Store muss manuell über App Store.app erfolgen – die Befehle `mas account` und `mas signin` sind auf macOS 12+ nicht verfügbar. Siehe [Troubleshooting → mas Probleme](troubleshooting.md#mac-app-store-mas-probleme).

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

**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `bip` | **Brew Install**: Interaktive Paketsuche → Installieren |
| `bup` | **Brew Update**: Veraltete Pakete → Upgrade |
| `brp` | **Brew Remove**: Installierte Pakete → Deinstallieren |
| `bsp [query]` | **Brew Search**: Suchen mit Info-Vorschau |

> **Hinweis:** Die mas-Aliase sind nur verfügbar wenn mas installiert ist. `brewup` enthält automatisch `mas upgrade` wenn mas vorhanden ist. Die interaktiven Funktionen benötigen fzf.

### fd.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `fdf` | `fd --type f` | Nur Dateien suchen |
| `fdd` | `fd --type d` | Nur Verzeichnisse suchen |
| `fdh` | `fd --hidden` | Inkl. versteckte Dateien |
| `fda` | `fd -u` | Alles (unrestricted = --hidden --no-ignore) |
| `fdsh` | `fd --extension sh` | Shell-Skripte |
| `fdpy` | `fd --extension py` | Python-Dateien |
| `fdjs` | `fd -e js -e ts` | JavaScript/TypeScript |
| `fdmd` | `fd --extension md` | Markdown-Dateien |
| `fdjson` | `fd --extension json` | JSON-Dateien |
| `fdyaml` | `fd -e yaml -e yml` | YAML-Dateien |

**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `cdf [path]` | **Fuzzy CD**: fd + fzf + eza – Verzeichnisnavigation mit Baum-Vorschau |
| `fe [path]` | **Fuzzy Edit**: Datei suchen → Vorschau mit bat → Editor öffnen |
| `fo [path]` | **Fuzzy Open**: Datei suchen → `open` (macOS) |

> **Hinweis:** fd respektiert automatisch `.gitignore` und ist deutlich schneller als find. Die interaktiven Funktionen benötigen fzf.

### btop.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `top` | `btop` | top durch btop ersetzen |
| `htop` | `btop` | htop durch btop ersetzen |

> **Hinweis:** btop bietet CPU, RAM, Disk, Netzwerk und Prozess-Überwachung in einer ansprechenden TUI. Für einfache Terminals: `btop --low-color`.

### git.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ga` | `git add` | Dateien stagen |
| `gc` | `git commit` | Commit |
| `gcm` | `git commit -m` | Commit mit Message |
| `gacm` | `git add --all && git commit -m` | Add all + Commit |
| `gp` | `git push` | Push |
| `gpl` | `git pull` | Pull |
| `gco` | `git checkout` | Checkout |
| `gs` | `git status` | Status |
| `gd` | `git diff` | Diff |

**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `glog` | Commit-History: Vorschau mit bat, Ctrl+Y=SHA kopieren |
| `gbr` | Branch wechseln: Log-Vorschau, Ctrl+D=Branch löschen |
| `gst` | Status mit Diff-Vorschau: Enter=Add, Ctrl+R=Restore |
| `gstash` | Stash-Browser: Enter=Apply, Ctrl+D=Drop, Ctrl+P=Pop |

> **Hinweis:** Die interaktiven Funktionen benötigen fzf und werden nur geladen wenn fzf installiert ist.

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
| `rgc` | `rg -C 3` | Suche mit Kontext (3 Zeilen) |
| `rgi` | `rg --ignore-case` | Case-insensitive (immer) |
| `rga` | `rg -uuu` | Alle Dateien (ignoriert nichts) |
| `rgh` | `rg --hidden` | Inkl. versteckte Dateien |
| `rgl` | `rg --files-with-matches` | Nur Dateinamen mit Treffern |
| `rgn` | `rg --count` | Treffer-Anzahl pro Datei |
| `rgts` | `rg -t ts -t js` | TypeScript/JavaScript |
| `rgpy` | `rg -t py` | Python |
| `rgmd` | `rg -t md` | Markdown |
| `rgsh` | `rg -t sh` | Shell-Skripte |
| `rgrb` | `rg -t ruby` | Ruby |
| `rggo` | `rg -t go` | Go |

**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `rgf [query]` | **Live-Grep**: ripgrep + fzf + bat – Echtzeit-Suche während der Eingabe |

> **Hinweis:** `--smart-case` ist global in `~/.config/ripgrep/config` konfiguriert – alle Aliase erben diese Einstellung automatisch. Die interaktive Funktion `rgf` benötigt fzf.

### gh.alias

**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `ghpr` | PRs durchsuchen: Enter=Checkout, Ctrl+O=Browser, Ctrl+D=Diff |
| `ghis` | Issues durchsuchen: Enter=Browser, Ctrl+E=Bearbeiten |
| `ghrun` | Actions Runs: Enter=Logs, Ctrl+O=Browser, Ctrl+R=Rerun |
| `ghrepo` | Repositories: Enter=Klonen, Ctrl+O=Browser |

> **Hinweis:** Alle gh-Funktionen benötigen sowohl gh CLI als auch fzf.

### fzf.alias – Generische Utilities

fzf ist als "Enhancer" in die jeweiligen Tool-Alias-Dateien integriert. Diese Datei enthält nur generische Funktionen:

**Zoxide + fzf:**

| Funktion | Beschreibung |
|----------|--------------|
| `zf` | zoxide + fzf mit eza-Vorschau, Ctrl+D zum Löschen |

> **`zi` vs `zf` – Wann welches verwenden?**
>
> `zi` ist ein zoxide built-in (keine eigene Funktion in fzf.alias).
>
> | Befehl | Quelle | Vorschau | Lösch-Option | Empfehlung |
> |--------|--------|----------|--------------|------------|
> | `zi` | zoxide (built-in) | Keine | Nein | Schnelle Navigation zu bekannten Verzeichnissen |
> | `zf` | fzf.alias (custom) | eza-Baumansicht | Ctrl+D | Exploration mit visueller Vorschau, Aufräumen alter Einträge |
>
> **Faustregel:** `zi` für Geschwindigkeit, `zf` für Übersicht.

**System-Utilities:**

| Funktion | Beschreibung |
|----------|--------------|
| `fkill` | **Fuzzy Kill**: Prozesse auswählen und beenden |
| `fman` | **Fuzzy Man**: Man-Pages durchsuchen mit bat-Vorschau |
| `fenv` | **Fuzzy Env**: Umgebungsvariablen durchsuchen, Enter=Kopieren |
| `fhist` | **Fuzzy History**: Shell-History, Ctrl+Y=Kopieren, Enter=Ausführen |

**Tool-spezifische fzf-Funktionen:**

Die folgenden Funktionen nutzen fzf, sind aber nach ihrem primären Zweck in den jeweiligen Tool-Dateien organisiert:

- **ripgrep.alias**: `rgf`
- **fd.alias**: `cdf`, `fe`, `fo`
- **git.alias**: `glog`, `gbr`, `gst`, `gstash`
- **homebrew.alias**: `bip`, `bup`, `brp`, `bsp`
- **gh.alias**: `ghpr`, `ghis`, `ghrun`, `ghrepo`

> **Design-Prinzip:** Aliase werden nach ihrem primären Zweck organisiert, nicht nach den verwendeten Tools. `rgf` nutzt fzf+bat, ist aber primär eine Suche – daher in `ripgrep.alias`.

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

# Man-Pages mit Syntax-Highlighting
man ls                 # Automatisch via MANPAGER

# Theme temporär wechseln
bat --theme="Dracula" file.py

# Theme-Vorschau mit fzf
bat-preview
```

> **Hinweis:** `-pp` = `--style=plain --paging=never` – verhält sich wie echtes `cat`. bat ist automatisch als `MANPAGER` konfiguriert für Syntax-Highlighting in Man-Pages.

---

### ripgrep (rg) – Schnelle Textsuche

```zsh
# Smart-Case Suche (Standard, da in ~/.config/ripgrep/config)
rg "TODO"              # case-insensitive da alles klein
rg "MyClass"           # case-sensitive da Großbuchstaben

# Mit Kontext (3 Zeilen vor/nach)
rgc "error"            # rg -C 3

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

# Nach Erweiterung (mit Aliassen)
fdmd                    # Alle Markdown-Dateien
fdpy                    # Alle Python-Dateien
fdjs                    # JavaScript + TypeScript

# Nach Erweiterung (direkt)
fd -e yaml              # Alle YAML-Dateien
fd -e json -e yaml      # JSON und YAML

# Mit Ausführung
fd -e json -x jq . {}   # Alle JSON-Dateien formatieren
fd -e md -x bat {}      # Alle Markdown mit bat anzeigen

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
btop --low-color       # Weniger Farben

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
| `Ctrl+Y` | (in Ctrl+R) Befehl ins Clipboard kopieren | – |
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
# Ctrl+Y kopiert den Befehl ins Clipboard ohne Ausführung

# Live-Grep (interaktive Suche in Dateien)
rgf                # Startet interaktive Suche
rgf "TODO"         # Startet mit Suchbegriff

# Datei suchen und in Kommandozeile einfügen
# Ctrl+T drücken → Vorschau mit bat

# Verzeichnis wechseln
# Alt+C drücken → Vorschau mit eza Tree
cdf                # Alternative: cd mit fzf-Auswahl

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
| `zi` | Interaktive Auswahl (zoxide built-in) | – |
| `zf` | Erweitertes zi mit fzf | eza (Baumansicht) |

```zsh
# Verzeichnis wechseln (lernt mit der Zeit)
z dotfiles         # Springt zu ~/dotfiles
z doc              # Springt zu häufig besuchtem Verzeichnis mit "doc"

# Interaktive Auswahl (zoxide built-in)
zi                 # fzf-Auswahl ohne Vorschau

# Erweiterte Auswahl mit eza-Vorschau
zf                 # fzf mit Baumansicht, Ctrl+D zum Löschen
```

> **Hinweis:** `zi` ist das zoxide built-in. Für visuelle Vorschau und Löschfunktion verwende `zf` (aus fzf.alias).

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

## ZSH-Plugins

### zsh-autosuggestions

Zeigt Befehlsvorschläge basierend auf der History beim Tippen an.

```zsh
# Vorschlag akzeptieren
# → (Pfeil rechts) oder End-Taste

# Vorschlag teilweise akzeptieren (Wort für Wort)
# Alt+→ (Option + Pfeil rechts)

# Vorschlag ignorieren
# Weiterschreiben oder Escape
```

### zsh-syntax-highlighting

Färbt Kommandos während der Eingabe ein:
- **Grün:** Gültiger Befehl
- **Rot:** Ungültiger Befehl oder Datei nicht gefunden
- **Unterstrichen:** Existierende Datei/Verzeichnis

> **Hinweis:** Diese Plugins werden automatisch geladen wenn installiert. Sie beeinträchtigen die Shell-Startzeit minimal (~20ms).

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
