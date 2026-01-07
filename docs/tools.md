# 🛠️ Tools

Übersicht aller installierten CLI-Tools und verfügbaren Aliase.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen direkt im Code (`.alias`-Dateien, `Brewfile`) vornehmen.

---

## Schnellreferenz für Einsteiger

Die wichtigsten Tastenkombinationen und Befehle auf einen Blick:

### Tastenkombinationen (global)

| Taste | Funktion | Beschreibung |
|-------|----------|--------------|
| `Ctrl+X 1` | History-Suche | Frühere Befehle fuzzy suchen |
| `Ctrl+X 2` | Datei einfügen | Datei suchen und in Kommandozeile einfügen |
| `Ctrl+X 3` | Verzeichnis wechseln | Interaktiv in Unterverzeichnis springen |
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

# 4. Frühere Befehle suchen (Ctrl+X 1 drücken, tippen, Enter)

# 5. Zu einem Verzeichnis springen (lernt mit der Zeit)
z dotfiles
```

> 💡 **Tipp:** Alle Aliase haben Guard-Checks – fehlt ein Tool, funktioniert der Original-Befehl weiterhin.

---

## Alias-Suche und Dokumentation

### fa – Interaktive Alias-Suche

Die `fa`-Funktion (fzf alias) durchsucht alle Aliase und Funktionen:

```zsh
fa              # Alle Aliase/Funktionen durchsuchen
fa commit       # Nach "commit" filtern
```

| Keybinding | Aktion |
|------------|--------|
| `Enter` | Befehl übernehmen (ins Edit-Buffer) |
| `Ctrl+C` | Preview: Code-Definition |
| `Ctrl+T` | Preview: tldr für Tool-Kategorie |

### brewv – Versionsübersicht

```zsh
brewv           # Alle Formulae, Casks und MAS-Apps mit Versionen
```

---

## tldr mit dotfiles-Erweiterungen

Die `tldr`-Befehle zeigen neben der offiziellen Dokumentation auch **dotfiles-spezifische Aliase und Funktionen**:

```zsh
tldr git      # + Aliase (ga, gc, gp) + Funktionen (glog, gbr, gst)
tldr fzf      # + Tastenkürzel + Funktionen (zf, fkill, fman, ...)
tldr brew     # + brewup, mas-Aliase, fzf-Funktionen
tldr bat      # + cat, catn, catd Aliase
tldr rg       # + rgc, rgi, rga + rgf Funktion
```

Die Erweiterungen sind als Patches implementiert – sie werden automatisch an die offizielle Dokumentation angehängt und beginnen mit `# dotfiles:`.

---

## Installierte CLI-Tools

Diese Tools werden via Brewfile installiert:

| Tool | Beschreibung | Dokumentation |
|------|--------------|---------------|
| **fzf** | Fuzzy Finder | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| **gh** | GitHub CLI | [cli.github.com](https://cli.github.com/) |
| **stow** | Symlink-Manager | [gnu.org/software/stow](https://www.gnu.org/software/stow/) |
| **starship** | Shell-Prompt | [starship.rs](https://starship.rs/) |
| **tealdeer** | tldr-Client für vereinfachte Man-Pages | [github.com/tealdeer-rs/tealdeer](https://github.com/tealdeer-rs/tealdeer) |
| **zoxide** | Smartes cd | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| **mas** | Mac App Store CLI | [github.com/mas-cli/mas](https://github.com/mas-cli/mas) |
| **eza** | Moderner ls-Ersatz mit Icons | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| **bat** | cat mit Syntax-Highlighting | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| **ripgrep** | Ultraschneller grep-Ersatz | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **fd** | Schneller find-Ersatz | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| **btop** | Ressourcen-Monitor (top-Ersatz) | [github.com/aristocratos/btop](https://github.com/aristocratos/btop) |
| **fastfetch** | Schnelle System-Info (neofetch-Ersatz) | [github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **lazygit** | Terminal-UI für Git | [github.com/jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |
| **zsh-syntax-highlighting** | Syntax-Highlighting für Kommandos | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |
| **zsh-autosuggestions** | History-basierte Vorschläge | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
### ZSH-Plugins

| Plugin | Beschreibung | Dokumentation |
|--------|--------------|---------------|
| **zsh-autosuggestions** | History-basierte Befehlsvorschläge beim Tippen | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| **zsh-syntax-highlighting** | Echtzeit Syntax-Highlighting für Kommandos | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |

### Casks (Fonts & Tools)

Diese Pakete werden via `brew install --cask` installiert:

| App | Beschreibung | Dokumentation |
|-----|--------------|---------------|
| **font-meslo-lg-nerd-font** | Nerd Font für Terminal-Icons | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| **claude-code** | Terminal-basierter KI-Coding-Assistent | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
### Mac App Store Apps

Diese Apps werden via `mas` installiert (Benutzer muss im App Store angemeldet sein):

| App | Beschreibung |
|-----|--------------|
| **Xcode** | Apple IDE für iOS/macOS |
| **Pages** | Textverarbeitung |
| **Numbers** | Tabellenkalkulation |
| **Keynote** | Präsentationen |
> **Hinweis:** Die Anmeldung im App Store muss manuell über App Store.app erfolgen – die Befehle `mas account` und `mas signin` sind auf macOS 12+ nicht verfügbar.

---

## Aliase

Verfügbare Aliase aus `~/.config/alias/`:

> **Guard-System:** Alle Tool-Aliase prüfen zuerst ob das jeweilige Tool installiert ist (`command -v`). Ist ein Tool nicht vorhanden, bleiben die originalen Befehle (`ls`, `cat`, `grep`) erhalten.


<a name="batalias"></a>

### bat.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `cat` | `bat -pp` | Ersetzt cat mit Syntax-Highlighting (plain style) |
| `catn` | `bat --style=numbers --paging=never` | Mit Zeilennummern, ohne Pager (bat allein hat Pager) |
| `catd` | `bat --diff` | Zeigt Git-Diff-Markierungen an |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `bat-theme` | Theme Browser (Enter=Aktivieren) |
> **Hinweis:** Globale Optionen (Theme, Style, Syntax-Mappings)


<a name="brewalias"></a>

### brew.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `maso` | `mas outdated` | Zeige veraltete Mac App Store Apps |
| `masu` | `mas upgrade` | Alle Mac App Store Apps aktualisieren |
| `mass` | `mas search` | Im Mac App Store nach Apps suchen (gibt ID zurück) |
| `masi` | `mas install` | App aus Mac App Store installieren (benötigt ID) |
| `masl` | `mas list` | Alle installierten Mac App Store Apps auflisten |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `brewup` | Homebrew Komplett-Update (update, upgrade, autoremove, cleanup, mas) |
| `brewv` | Brewfile Versionsübersicht (zeigt installierte Versionen aller Pakete) |
| `bip` | Brew Install Browser (Enter=Installieren, Tab=Mehrfach) |
| `brp` | Brew Remove Browser (Enter=Entfernen, Tab=Mehrfach) |
> **Hinweis:** Kein Guard für brew – ohne Homebrew ist dieses


<a name="btopalias"></a>

### btop.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `top` | `btop` | Systemmonitor mit modernem Interface |
| `htop` | `btop` | Bessere Alternative zu htop |
> **Hinweis:** Konfiguration in ~/.config/btop/btop.conf


<a name="ezaalias"></a>

### eza.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ls` | `eza --group-directories-first` | Verzeichnisse zuerst anzeigen mit Icons |
| `ll` | `eza -l --group-directories-first --header` | Lange Listenansicht mit Details |
| `la` | `eza -la --group-directories-first --header` | Alle Dateien inklusive versteckte |
| `llg` | `eza -l --git --group-directories-first --header` | Lange Liste mit Git-Status |
| `lag` | `eza -la --git --group-directories-first --header` | Alle Dateien mit Git-Status |
| `lt` | `eza --tree --level=2` | Verzeichnisbaum bis Tiefe 2 |
| `lt3` | `eza --tree --level=3` | Verzeichnisbaum bis Tiefe 3 |
| `lss` | `eza -l --sort=size --reverse --header` | Nach Größe sortieren (größte zuerst) |
| `lst` | `eza -l --sort=modified --reverse --header` | Nach Änderungsdatum sortieren (neueste zuerst) |
> **Hinweis:** EZA_ICONS_AUTO=1 ist in .zshrc gesetzt, daher kein


<a name="fastfetchalias"></a>

### fastfetch.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ff` | `fastfetch` | Schnelle System-Info (Standardanzeige) |
| `neofetch` | `fastfetch` | Neofetch-Kompatibilität |
> **Hinweis:** Konfiguration in ~/.config/fastfetch/config.jsonc


<a name="fdalias"></a>

### fd.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `fdf` | `fd --type f` | Nur Dateien suchen |
| `fdd` | `fd --type d` | Nur Verzeichnisse suchen |
| `fdh` | `fd --hidden` | Inklusive versteckte Dateien |
| `fda` | `fd -u` | Uneingeschränkt: alle Dateien inklusive .gitignore |
| `fdsh` | `fd --extension sh` | Shell-Skripte finden |
| `fdpy` | `fd --extension py` | Python-Dateien finden |
| `fdjs` | `fd -e js -e ts` | JavaScript/TypeScript Dateien |
| `fdmd` | `fd --extension md` | Markdown-Dateien finden |
| `fdjson` | `fd --extension json` | JSON-Dateien finden |
| `fdyaml` | `fd -e yaml -e yml` | YAML-Dateien finden |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `cdf` | Verzeichnis wechseln (Enter=Wechseln, Ctrl+Y=Pfad kopieren) |
| `fo` | Datei öffnen (Enter=Öffnen, Ctrl+Y=Pfad kopieren) |
> **Hinweis:** Globale Ignore-Patterns (.git/, node_modules/, etc.)


<a name="fzfalias"></a>

### fzf.alias

**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `zf` | zoxide Browser (Enter=Wechseln, Ctrl+D=Löschen, Ctrl+Y=Kopieren) |
| `fkill` | Prozess Browser (Enter=Beenden, Tab=Mehrfach, Ctrl+S=Apps↔Alle) |
| `fman` | Man/tldr Browser (Ctrl+S=Modus wechseln, Enter=je nach Modus öffnen) |
| `fa` | fa Browser (Enter=Übernehmen, Ctrl+S=tldr↔Code) |
| `fenv` | Env Browser (Enter=Export→Edit, Ctrl+Y=Kopieren) |
> **Hinweis:** Shell-Keybindings via Ctrl+X Prefix (in init.zsh):


<a name="ghalias"></a>

### gh.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `gho` | `gh browse` | Repository im Browser öffnen |
| `ghst` | `gh status` | GitHub Status: Zugewiesene Issues, PRs, Mentions |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `ghpr` | PRs durchsuchen (Enter=Checkout, Ctrl+D=Diff, Ctrl+O=Browser) |
| `ghis` | Issues durchsuchen (Enter=Browser, Ctrl+E=Bearbeiten) |
| `ghrun` | Actions Runs (Enter=Logs, Ctrl+R=Rerun, Ctrl+O=Browser) |
| `ghrepo` | Repo Browser (Enter=Klonen, Ctrl+O=Browser) |
| `ghgist` | Gists durchsuchen (Enter=Anzeigen, Ctrl+E=Bearbeiten, Ctrl+O=Browser) |
> **Hinweis:** Erfordert gh auth login für Authentifizierung.


<a name="gitalias"></a>

### git.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ga` | `git add` | Dateien zum Staging hinzufügen |
| `gc` | `git commit` | Einen neuen Commit erstellen |
| `gcm` | `git commit -m` | Commit mit Nachricht |
| `gacm` | `git add --all && git commit -m` | Alle Änderungen stagen und einen Commit erstellen |
| `gp` | `git push` | Änderungen pushen |
| `gpl` | `git pull` | Änderungen pullen |
| `gco` | `git checkout` | Branch wechseln oder Datei zurücksetzen |
| `gs` | `git status` | Status des Repositories anzeigen |
| `gd` | `git diff` | Änderungen anzeigen |
| `lg` | `lazygit` | Terminal-UI für Git (lazygit) |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `glog` | Commit-History mit bat-Vorschau (Enter=Anzeigen, Ctrl+Y=SHA kopieren) |
| `gbr` | Branch wechseln mit Log-Vorschau (Enter=Checkout, Ctrl+D=Löschen) |
| `gst` | Status mit Diff-Vorschau (Enter=Add, Tab=Mehrfach, Ctrl+R=Reset) |
| `gstash` | Stash-Browser (Enter=Apply, Ctrl+P=Pop, Ctrl+D=Drop) |
> **Hinweis:** Interaktive Git-Funktionen (mit fzf) sind unten


<a name="rgalias"></a>

### rg.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `rgc` | `rg -C 3` | Suche mit 3 Zeilen Kontext vor und nach Treffer |
| `rgi` | `rg --ignore-case` | Suche ohne Berücksichtigung von Groß-/Kleinschreibung |
| `rga` | `rg -uuu` | Suche in allen Dateien ohne Einschränkungen |
| `rgh` | `rg --hidden` | Suche inklusive versteckter Dateien |
| `rgl` | `rg --files-with-matches` | Zeige nur Dateinamen mit Treffern |
| `rgn` | `rg --count` | Zähle Treffer pro Datei |
| `rgts` | `rg -t ts -t js` | Suche in TypeScript/JavaScript Dateien |
| `rgpy` | `rg -t py` | Suche in Python-Dateien |
| `rgmd` | `rg -t md` | Suche in Markdown-Dateien |
| `rgsh` | `rg -t sh` | Suche in Shell-Skripten |
| `rgrb` | `rg -t ruby` | Suche in Ruby-Dateien |
| `rggo` | `rg -t go` | Suche in Go-Dateien |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `rgf` | Live-Grep (Enter=Datei öffnen, Ctrl+Y=Pfad kopieren) |
> **Hinweis:** Globale Optionen (--smart-case, --line-number, --heading)


# 🛠️ Tools

Übersicht aller installierten CLI-Tools und verfügbaren Aliase.

> Diese Dokumentation wird automatisch aus dem Code generiert.
> Änderungen direkt im Code (`.alias`-Dateien, `Brewfile`) vornehmen.

---

## Schnellreferenz für Einsteiger

Die wichtigsten Tastenkombinationen und Befehle auf einen Blick:

### Tastenkombinationen (global)

| Taste | Funktion | Beschreibung |
|-------|----------|--------------|
| `Ctrl+X 1` | History-Suche | Frühere Befehle fuzzy suchen |
| `Ctrl+X 2` | Datei einfügen | Datei suchen und in Kommandozeile einfügen |
| `Ctrl+X 3` | Verzeichnis wechseln | Interaktiv in Unterverzeichnis springen |
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

# 4. Frühere Befehle suchen (Ctrl+X 1 drücken, tippen, Enter)

# 5. Zu einem Verzeichnis springen (lernt mit der Zeit)
z dotfiles
```

> 💡 **Tipp:** Alle Aliase haben Guard-Checks – fehlt ein Tool, funktioniert der Original-Befehl weiterhin.

---

## Alias-Suche und Dokumentation

### fa – Interaktive Alias-Suche

Die `fa`-Funktion (fzf alias) durchsucht alle Aliase und Funktionen:

```zsh
fa              # Alle Aliase/Funktionen durchsuchen
fa commit       # Nach "commit" filtern
```

| Keybinding | Aktion |
|------------|--------|
| `Enter` | Befehl übernehmen (ins Edit-Buffer) |
| `Ctrl+C` | Preview: Code-Definition |
| `Ctrl+T` | Preview: tldr für Tool-Kategorie |

### brewv – Versionsübersicht

```zsh
brewv           # Alle Formulae, Casks und MAS-Apps mit Versionen
```

---

## tldr mit dotfiles-Erweiterungen

Die `tldr`-Befehle zeigen neben der offiziellen Dokumentation auch **dotfiles-spezifische Aliase und Funktionen**:

```zsh
tldr git      # + Aliase (ga, gc, gp) + Funktionen (glog, gbr, gst)
tldr fzf      # + Tastenkürzel + Funktionen (zf, fkill, fman, ...)
tldr brew     # + brewup, mas-Aliase, fzf-Funktionen
tldr bat      # + cat, catn, catd Aliase
tldr rg       # + rgc, rgi, rga + rgf Funktion
```

Die Erweiterungen sind als Patches implementiert – sie werden automatisch an die offizielle Dokumentation angehängt und beginnen mit `# dotfiles:`.

---

## Installierte CLI-Tools

Diese Tools werden via Brewfile installiert:

| Tool | Beschreibung | Dokumentation |
|------|--------------|---------------|
| **fzf** | Fuzzy Finder | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| **gh** | GitHub CLI | [cli.github.com](https://cli.github.com/) |
| **stow** | Symlink-Manager | [gnu.org/software/stow](https://www.gnu.org/software/stow/) |
| **starship** | Shell-Prompt | [starship.rs](https://starship.rs/) |
| **tealdeer** | tldr-Client für vereinfachte Man-Pages | [github.com/tealdeer-rs/tealdeer](https://github.com/tealdeer-rs/tealdeer) |
| **zoxide** | Smartes cd | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| **mas** | Mac App Store CLI | [github.com/mas-cli/mas](https://github.com/mas-cli/mas) |
| **eza** | Moderner ls-Ersatz mit Icons | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| **bat** | cat mit Syntax-Highlighting | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| **ripgrep** | Ultraschneller grep-Ersatz | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **fd** | Schneller find-Ersatz | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| **btop** | Ressourcen-Monitor (top-Ersatz) | [github.com/aristocratos/btop](https://github.com/aristocratos/btop) |
| **fastfetch** | Schnelle System-Info (neofetch-Ersatz) | [github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **lazygit** | Terminal-UI für Git | [github.com/jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |
| **zsh-syntax-highlighting** | Syntax-Highlighting für Kommandos | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |
| **zsh-autosuggestions** | History-basierte Vorschläge | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
### ZSH-Plugins

| Plugin | Beschreibung | Dokumentation |
|--------|--------------|---------------|
| **zsh-autosuggestions** | History-basierte Befehlsvorschläge beim Tippen | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| **zsh-syntax-highlighting** | Echtzeit Syntax-Highlighting für Kommandos | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |

### Casks (Fonts & Tools)

Diese Pakete werden via `brew install --cask` installiert:

| App | Beschreibung | Dokumentation |
|-----|--------------|---------------|
| **font-meslo-lg-nerd-font** | Nerd Font für Terminal-Icons | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| **claude-code** | Terminal-basierter KI-Coding-Assistent | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
### Mac App Store Apps

Diese Apps werden via `mas` installiert (Benutzer muss im App Store angemeldet sein):

| App | Beschreibung |
|-----|--------------|
| **Xcode** | Apple IDE für iOS/macOS |
| **Pages** | Textverarbeitung |
| **Numbers** | Tabellenkalkulation |
| **Keynote** | Präsentationen |
> **Hinweis:** Die Anmeldung im App Store muss manuell über App Store.app erfolgen – die Befehle `mas account` und `mas signin` sind auf macOS 12+ nicht verfügbar.

---

## Aliase

Verfügbare Aliase aus `~/.config/alias/`:

> **Guard-System:** Alle Tool-Aliase prüfen zuerst ob das jeweilige Tool installiert ist (`command -v`). Ist ein Tool nicht vorhanden, bleiben die originalen Befehle (`ls`, `cat`, `grep`) erhalten.


<a name="batalias"></a>

### bat.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `cat` | `bat -pp` | Ersetzt cat mit Syntax-Highlighting (plain style) |
| `catn` | `bat --style=numbers --paging=never` | Mit Zeilennummern, ohne Pager (bat allein hat Pager) |
| `catd` | `bat --diff` | Zeigt Git-Diff-Markierungen an |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `bat-theme` | Theme Browser (Enter=Aktivieren) |
> **Hinweis:** Globale Optionen (Theme, Style, Syntax-Mappings)


<a name="brewalias"></a>

### brew.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `maso` | `mas outdated` | Zeige veraltete Mac App Store Apps |
| `masu` | `mas upgrade` | Alle Mac App Store Apps aktualisieren |
| `mass` | `mas search` | Im Mac App Store nach Apps suchen (gibt ID zurück) |
| `masi` | `mas install` | App aus Mac App Store installieren (benötigt ID) |
| `masl` | `mas list` | Alle installierten Mac App Store Apps auflisten |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `brewup` | Homebrew Komplett-Update (update, upgrade, autoremove, cleanup, mas) |
| `brewv` | Brewfile Versionsübersicht (zeigt installierte Versionen aller Pakete) |
| `bip` | Brew Install Browser (Enter=Installieren, Tab=Mehrfach) |
| `brp` | Brew Remove Browser (Enter=Entfernen, Tab=Mehrfach) |
> **Hinweis:** Kein Guard für brew – ohne Homebrew ist dieses


<a name="btopalias"></a>

### btop.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `top` | `btop` | Systemmonitor mit modernem Interface |
| `htop` | `btop` | Bessere Alternative zu htop |
> **Hinweis:** Konfiguration in ~/.config/btop/btop.conf


<a name="ezaalias"></a>

### eza.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ls` | `eza --group-directories-first` | Verzeichnisse zuerst anzeigen mit Icons |
| `ll` | `eza -l --group-directories-first --header` | Lange Listenansicht mit Details |
| `la` | `eza -la --group-directories-first --header` | Alle Dateien inklusive versteckte |
| `llg` | `eza -l --git --group-directories-first --header` | Lange Liste mit Git-Status |
| `lag` | `eza -la --git --group-directories-first --header` | Alle Dateien mit Git-Status |
| `lt` | `eza --tree --level=2` | Verzeichnisbaum bis Tiefe 2 |
| `lt3` | `eza --tree --level=3` | Verzeichnisbaum bis Tiefe 3 |
| `lss` | `eza -l --sort=size --reverse --header` | Nach Größe sortieren (größte zuerst) |
| `lst` | `eza -l --sort=modified --reverse --header` | Nach Änderungsdatum sortieren (neueste zuerst) |
> **Hinweis:** EZA_ICONS_AUTO=1 ist in .zshrc gesetzt, daher kein


<a name="fastfetchalias"></a>

### fastfetch.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ff` | `fastfetch` | Schnelle System-Info (Standardanzeige) |
| `neofetch` | `fastfetch` | Neofetch-Kompatibilität |
> **Hinweis:** Konfiguration in ~/.config/fastfetch/config.jsonc


<a name="fdalias"></a>

### fd.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `fdf` | `fd --type f` | Nur Dateien suchen |
| `fdd` | `fd --type d` | Nur Verzeichnisse suchen |
| `fdh` | `fd --hidden` | Inklusive versteckte Dateien |
| `fda` | `fd -u` | Uneingeschränkt: alle Dateien inklusive .gitignore |
| `fdsh` | `fd --extension sh` | Shell-Skripte finden |
| `fdpy` | `fd --extension py` | Python-Dateien finden |
| `fdjs` | `fd -e js -e ts` | JavaScript/TypeScript Dateien |
| `fdmd` | `fd --extension md` | Markdown-Dateien finden |
| `fdjson` | `fd --extension json` | JSON-Dateien finden |
| `fdyaml` | `fd -e yaml -e yml` | YAML-Dateien finden |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `cdf` | Verzeichnis wechseln (Enter=Wechseln, Ctrl+Y=Pfad kopieren) |
| `fo` | Datei öffnen (Enter=Öffnen, Ctrl+Y=Pfad kopieren) |
> **Hinweis:** Globale Ignore-Patterns (.git/, node_modules/, etc.)


<a name="fzfalias"></a>

### fzf.alias

**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `zf` | zoxide Browser (Enter=Wechseln, Ctrl+D=Löschen, Ctrl+Y=Kopieren) |
| `fkill` | Prozess Browser (Enter=Beenden, Tab=Mehrfach, Ctrl+S=Apps↔Alle) |
| `fman` | Man/tldr Browser (Ctrl+S=Modus wechseln, Enter=je nach Modus öffnen) |
| `fa` | fa Browser (Enter=Übernehmen, Ctrl+S=tldr↔Code) |
| `fenv` | Env Browser (Enter=Export→Edit, Ctrl+Y=Kopieren) |
> **Hinweis:** Shell-Keybindings via Ctrl+X Prefix (in init.zsh):


<a name="ghalias"></a>

### gh.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `gho` | `gh browse` | Repository im Browser öffnen |
| `ghst` | `gh status` | GitHub Status: Zugewiesene Issues, PRs, Mentions |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `ghpr` | PRs durchsuchen (Enter=Checkout, Ctrl+D=Diff, Ctrl+O=Browser) |
| `ghis` | Issues durchsuchen (Enter=Browser, Ctrl+E=Bearbeiten) |
| `ghrun` | Actions Runs (Enter=Logs, Ctrl+R=Rerun, Ctrl+O=Browser) |
| `ghrepo` | Repo Browser (Enter=Klonen, Ctrl+O=Browser) |
| `ghgist` | Gists durchsuchen (Enter=Anzeigen, Ctrl+E=Bearbeiten, Ctrl+O=Browser) |
> **Hinweis:** Erfordert gh auth login für Authentifizierung.


<a name="gitalias"></a>

### git.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `ga` | `git add` | Dateien zum Staging hinzufügen |
| `gc` | `git commit` | Einen neuen Commit erstellen |
| `gcm` | `git commit -m` | Commit mit Nachricht |
| `gacm` | `git add --all && git commit -m` | Alle Änderungen stagen und einen Commit erstellen |
| `gp` | `git push` | Änderungen pushen |
| `gpl` | `git pull` | Änderungen pullen |
| `gco` | `git checkout` | Branch wechseln oder Datei zurücksetzen |
| `gs` | `git status` | Status des Repositories anzeigen |
| `gd` | `git diff` | Änderungen anzeigen |
| `lg` | `lazygit` | Terminal-UI für Git (lazygit) |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `glog` | Commit-History mit bat-Vorschau (Enter=Anzeigen, Ctrl+Y=SHA kopieren) |
| `gbr` | Branch wechseln mit Log-Vorschau (Enter=Checkout, Ctrl+D=Löschen) |
| `gst` | Status mit Diff-Vorschau (Enter=Add, Tab=Mehrfach, Ctrl+R=Reset) |
| `gstash` | Stash-Browser (Enter=Apply, Ctrl+P=Pop, Ctrl+D=Drop) |
> **Hinweis:** Interaktive Git-Funktionen (mit fzf) sind unten


<a name="rgalias"></a>

### rg.alias

| Alias | Befehl | Beschreibung |
|-------|--------|--------------|
| `rgc` | `rg -C 3` | Suche mit 3 Zeilen Kontext vor und nach Treffer |
| `rgi` | `rg --ignore-case` | Suche ohne Berücksichtigung von Groß-/Kleinschreibung |
| `rga` | `rg -uuu` | Suche in allen Dateien ohne Einschränkungen |
| `rgh` | `rg --hidden` | Suche inklusive versteckter Dateien |
| `rgl` | `rg --files-with-matches` | Zeige nur Dateinamen mit Treffern |
| `rgn` | `rg --count` | Zähle Treffer pro Datei |
| `rgts` | `rg -t ts -t js` | Suche in TypeScript/JavaScript Dateien |
| `rgpy` | `rg -t py` | Suche in Python-Dateien |
| `rgmd` | `rg -t md` | Suche in Markdown-Dateien |
| `rgsh` | `rg -t sh` | Suche in Shell-Skripten |
| `rgrb` | `rg -t ruby` | Suche in Ruby-Dateien |
| `rggo` | `rg -t go` | Suche in Go-Dateien |
**Interaktive Funktionen (mit fzf):**

| Funktion | Beschreibung |
|----------|--------------|
| `rgf` | Live-Grep (Enter=Datei öffnen, Ctrl+Y=Pfad kopieren) |
> **Hinweis:** Globale Optionen (--smart-case, --line-number, --heading)
