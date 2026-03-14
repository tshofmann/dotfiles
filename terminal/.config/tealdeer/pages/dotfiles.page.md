# dotfiles

> Dotfiles mit Catppuccin-Theme und modernen CLI-Tools.
> Mehr Informationen: <https://github.com/tshofmann/dotfiles>

- Diese Hilfe (Schnellreferenz):

`dothelp`

- Alle Aliase+Funktionen interaktiv durchsuchen:

`cmds {{suche}}`

- Vollständige Tool-Dokumentation:

`tldr {{tool}}`

# Autosuggestions (History-Vorschläge beim Tippen)

- Vorschlag komplett übernehmen:

`→`

- Wort für Wort übernehmen:

`Alt+→`

- Vorschlag ignorieren:

`Escape`

# fzf-Shortcuts (interaktive Suche, Ctrl+X Prefix)

- Befehlsverlauf durchsuchen:

`Ctrl+X 1`

- Dateien im Verzeichnis suchen:

`Ctrl+X 2`

- In Unterverzeichnis wechseln:

`Ctrl+X 3`

# Tool-Ersetzungen (moderne CLI-Alternativen)

- cat → bat (mit Syntax-Highlighting):

`cat, catn, catd, bat-theme`

- top → btop (moderner Ressourcen-Monitor):

`top, htop`

- ls → eza (mit Icons und Git-Status):

`ls, ll, la, lt, lt3, lss, lst`

- find → fd (schneller, intuitive Syntax):

`fdf, fdd, fdh, fda, fdsh, fdpy, fdjs, fdmd, fdjson, fdyaml, jump, pick`

- grep → rg (schneller, respektiert .gitignore):

`rgc, rgi, rga, rgh, rgl, rgn, rgts, rgpy, rgmd, rgsh, rgrb, rggo, rg-live`

- cd → zoxide (lernt häufige Verzeichnisse):

`z, zi, zj`

# Homebrew (inkl. Mac App Store)

- Homebrew Komplett-Update:

`brew-up`

- Zeige veraltete Mac App Store Apps:

`maso`

- Alle Mac App Store Apps aktualisieren:

`masu`

- Im Mac App Store nach Apps suchen (gibt ID zurück):

`mass`

- App aus Mac App Store installieren (benötigt ID):

`masi`

- Alle installierten Mac App Store Apps auflisten:

`masl`

- Brewfile Wartungs-Dashboard:

`brew-list {{filter}}`

- Brew Install Browser:

`brew-add {{suche}}`

- Brew Remove Browser:

`brew-rm {{suche}}`

# Dotfiles-Wartung

- Health-Check:

`dothealth`

- Dokumentation neu generieren:

`dotdocs`

- Symlinks neu verlinken (nach Änderungen in Stow-Packages):

`dotstow`

- Config Browser:

`dotedit {{suche}}`

# Vollständige Dokumentation

- Jedes Tool hat ALLE Aliase+Funktionen dokumentiert:

`tldr {{7z|bat|brew|btop|eza|fastfetch|fd|ffmpeg|fzf|gh|git|kitty|lazygit|magick|rg|starship|yazi|zoxide|zsh}}`

- Eigene Seiten (ohne offizielle tldr-Basis):

`tldr {{catppuccin|dotfiles-restore|markdownlint|poppler|resvg|dotfiles}}`
