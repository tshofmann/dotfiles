# dotfiles

> Dotfiles mit Catppuccin-Theme und modernen CLI-Tools.
> Mehr Informationen: <https://github.com/tshofmann/dotfiles>

- dotfiles: Nutzt `tldr (tealdeer)`

- Diese Hilfe (Schnellreferenz):

`dothelp`

- Alle Aliase+Funktionen interaktiv durchsuchen:

`fa {{suche}}`

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

- - → 7z (keine macOS-Befehle überschrieben):

`7za, 7zx, 7zl, 7zt, unrar, 7zf`

- cat → bat (mit Syntax-Highlighting):

`cat, catn, catd`

- ls → eza (mit Icons und Git-Status):

`ls, ll, la, tree`

- find → fd (schneller, intuitive Syntax):

`fd, fdf, fdd`

- grep → rg (schneller, respektiert .gitignore):

`rg, rgc, rgi`

- cd → zoxide (lernt häufige Verzeichnisse):

`z, zi, zf`

# Homebrew

- Homebrew Komplett-Update:

`brewup`

- Brewfile Versionsübersicht:

`brewv`

# Dotfiles-Wartung

- Health-Check:

`dothealth`

- Dokumentation neu generieren:

`dotdocs`

- Symlinks neu verlinken (nach Änderungen in terminal/ oder editor/):

`dotstow`

# Vollständige Dokumentation

- Jedes Tool hat ALLE Aliase+Funktionen dokumentiert:

`tldr {{7z|bat|brew|btop|eza|fastfetch|fd|ffmpeg|fzf|gh|git|lazygit|magick|rg|yazi|zoxide|zsh}}`

- Eigene Seiten (ohne offizielle tldr-Basis):

`tldr {{catppuccin|markdownlint|poppler|resvg|dotfiles}}`
