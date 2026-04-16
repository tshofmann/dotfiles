- dotfiles: Config `~/.config/fzf/config`

- dotfiles: Nutzt `bat, eza, fd, tldr, pdftotext, 7zz, identify, ffprobe`

# dotfiles: Globale Tastenkürzel (in allen fzf-Dialogen)

- dotfiles: Vorschau ein-/ausblenden:

`<Ctrl />`

- dotfiles: Alle auswählen (im Multi-Modus):

`<Ctrl a>`

- dotfiles: Eintrag zur Auswahl hinzufügen:

`<Tab>`

# dotfiles: Helper-Skripte (~/.config/fzf/)

- dotfiles: `action` – Führt Aktionen Shell-Injection-sicher aus

- dotfiles: `cmds` – Liste und Preview für cmds (Alias-Browser) in fzf

- dotfiles: `config` – Native fzf-Konfiguration (FZF_DEFAULT_OPTS_FILE)

- dotfiles: `gh` – GitHub CLI Listen für fzf (stabiles Tab-Format)

- dotfiles: `header-wrap` – Dynamischer fzf-Header-Umbruch nach verfügbarer Breite

- dotfiles: `help` – Subcommands für man/tldr Browser

- dotfiles: `init.zsh` – fzf Keybindings und fd-Backend aktivieren

- dotfiles: `lib.zsh` – Geteilte Utilities für alle fzf-Skripte

- dotfiles: `preview` – Zeigt Vorschau für Dateien und Verzeichnisse

- dotfiles: `procs` – Prozessliste für fzf (plattformübergreifend)

# dotfiles: Funktionen (aus fzf.alias)

- dotfiles: Prozess Browser (`<Enter>` Beenden, `<Tab>` Mehrfach, `<Ctrl s>` Apps ↔ Alle):

`procs {{signal}}`

- dotfiles: Man/tldr Browser (`<Enter>` öffnen, `<Ctrl s>` man ↔ tldr):

`help {{suche}}`

- dotfiles: Befehl Browser (`<Enter>` Übernehmen, `<Ctrl s>` tldr ↔ Code, `<Ctrl e>` Datei editieren):

`cmds {{suche}}`

- dotfiles: Variablen Browser (`<Enter>` Export → Edit, `<Ctrl y>` Wert kopieren):

`vars {{suche}}`

# dotfiles: Tools mit fzf-Integration

- dotfiles: Siehe `tldr 7z` für `7za`, `7zx`, `7zl`, `7zt`, `unrar`, `7zf`
- dotfiles: Siehe `tldr bat` für `cat`, `catn`, `catd`, `bat-theme`
- dotfiles: Siehe `tldr brew` für `brew-up`, `brew-list`, `brew-add`, `brew-rm`, `maso`, `masu`, `mass`, `masi`, `masl`
- dotfiles: Siehe `tldr dotfiles` für `dothelp`, `dh`, `dothealth`, `dotdocs`, `dotstow`, `dotedit`
- dotfiles: Siehe `tldr fd` für `fdf`, `fdd`, `fdh`, `fda`, `fdsh`, `fdpy`, `fdjs`, `fdmd`, `fdjson`, `fdyaml`, `jump`, `pick`
- dotfiles: Siehe `tldr gh` für `gh-open`, `gh-status`, `gh-pr`, `gh-issue`, `gh-run`, `gh-repo`, `gh-gist`
- dotfiles: Siehe `tldr git` für `git-add`, `git-commit`, `git-cm`, `git-acm`, `git-amend`, `git-push`, `git-pull`, `git-co`, `git-status`, `git-diff`, `git-log`, `git-branch`, `git-stage`, `git-stash`
- dotfiles: Siehe `tldr rg` für `rgc`, `rgi`, `rga`, `rgh`, `rgl`, `rgn`, `rgts`, `rgpy`, `rgmd`, `rgsh`, `rgrb`, `rggo`, `rg-live`
- dotfiles: Siehe `tldr yazi` für `y`
- dotfiles: Siehe `tldr zoxide` für `z`, `zi`, `zj`
