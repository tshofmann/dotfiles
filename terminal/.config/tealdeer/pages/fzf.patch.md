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

- dotfiles: `help` – Subcommands für man/tldr Browser

- dotfiles: `init.zsh` – fzf Keybindings und fd-Backend aktivieren

- dotfiles: `lib.zsh` – Geteilte Utilities für alle fzf-Skripte

- dotfiles: `preview` – Zeigt Vorschau für Dateien und Verzeichnisse

- dotfiles: `procs` – Prozessliste für fzf

# dotfiles: Funktionen (aus fzf.alias)

- dotfiles: Prozess Browser (`<Enter>` Beenden, `<Tab>` Mehrfach, `<Ctrl s>` Apps↔Alle):

`procs {{signal}}`

- dotfiles: Man/tldr Browser (`<Ctrl s>` Modus wechseln (Liste + Preview), `<Enter>` öffnen):

`help {{suche}}`

- dotfiles: Befehl Browser (`<Enter>` Übernehmen, `<Ctrl s>` tldr↔Code):

`cmds {{suche}}`

- dotfiles: Variablen Browser (`<Enter>` Export→Edit, `<Ctrl y>` Kopieren):

`vars {{suche}}`

# dotfiles: Shell-Keybindings (Ctrl+X Prefix)

- dotfiles: History durchsuchen mit Vorschau:

`<Ctrl x> 1`

- dotfiles: Datei suchen mit bat-Vorschau, Pfad einfügen:

`<Ctrl x> 2`

- dotfiles: Verzeichnis wechseln mit eza-Vorschau:

`<Ctrl x> 3`
