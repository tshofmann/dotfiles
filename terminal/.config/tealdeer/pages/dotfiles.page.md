# dotfiles

> Dotfiles mit Catppuccin-Theme und modernen CLI-Tools.
> Mehr Informationen: <https://github.com/tshofmann/dotfiles>

- dotfiles: Nutzt `tldr (für dothelp), stow (für dotstow), fzf+fd (für dotedit)`

- Diese Hilfe (Schnellreferenz):

`dothelp`

- Alle Aliase+Funktionen interaktiv durchsuchen:

`cmds {{suche}}`

- Vollständige Tool-Dokumentation:

`tldr {{tool}}`

# Keybindings

- Vorschlag komplett übernehmen:

`→`

- Wort für Wort übernehmen:

`Alt+→`

- Vorschlag ignorieren:

`Escape`

# fzf-Shortcuts (Ctrl+X Prefix)

- History:

`Ctrl+X 1`

- Dateien:

`Ctrl+X 2`

- Verzeichnisse:

`Ctrl+X 3`

# Tool-Ersetzungen

- cat → bat (mit Syntax-Highlighting):

`cat, catn, catd, bat-theme`

- top → btop (moderner Ressourcen-Monitor):

`top`

- ls → eza (mit Icons und Git-Status):

`ls, ll, la, lt, lt3, lss, lst`

- find → fd (schneller, intuitive Syntax):

`fdf, fdd, fdh, fda, fdsh, fdpy, fdjs, fdmd, fdjson, fdyaml, jump, pick`

- grep → rg (schneller, respektiert .gitignore):

`rgc, rgi, rga, rgh, rgl, rgn, rgts, rgpy, rgmd, rgsh, rgrb, rggo, rg-live`

- cd → zoxide (lernt häufige Verzeichnisse):

`z, zi, zj`

# Homebrew

- Homebrew Komplett-Update:

`brew-up`

- Brewfile Wartungs-Dashboard(filter?):

`brew-list`

# Dotfiles-Wartung

- Health-Check:

`dothealth`

- Dokumentation neu generieren:

`dotdocs`

- Symlinks neu verlinken (nach Änderungen in Stow-Packages):

`dotstow`

- Dotfiles Config editieren(suche?):

`dotedit`

# Vollständige Dokumentation

- Jedes Tool hat ALLE Aliase+Funktionen dokumentiert:

`tldr {{7z|bat|brew|btop|eza|fastfetch|fd|ffmpeg|fzf|gh|git|kitty|lazygit|magick|rg|starship|yazi|zoxide|zsh}}`

- Eigene Seiten (ohne offizielle tldr-Basis):

`tldr {{catppuccin|dotfiles-restore|markdownlint|poppler|resvg|dotfiles}}`
