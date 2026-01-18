- dotfiles: Config `~/.config/fzf/config`

- dotfiles: Nutzt `pdftotext (PDF), 7zz (Archive), identify (Bilder), ffprobe (Video/Audio)`

# dotfiles: Globale Tastenkürzel (in allen fzf-Dialogen)

- dotfiles: Vorschau ein-/ausblenden:

`<Ctrl />`

- dotfiles: Alle auswählen (im Multi-Modus):

`<Ctrl a>`

- dotfiles: Eintrag zur Auswahl hinzufügen:

`<Tab>`
# dotfiles: Helper-Skripte (~/.config/fzf/)

- dotfiles: `action` – Führt Aktionen Shell-Injection-sicher aus

- dotfiles: `config` – Native fzf-Konfiguration (FZF_DEFAULT_OPTS_FILE)

- dotfiles: `fa` – Preview-Befehle für fa (Alias-Browser) in fzf

- dotfiles: `fkill` – Prozessliste für fzf

- dotfiles: `fman` – Subcommands für man/tldr Browser

- dotfiles: `init.zsh` – fzf Keybindings und fd-Backend aktivieren

- dotfiles: `lib.zsh` – Geteilte Utilities für alle fzf-Skripte

- dotfiles: `preview` – Zeigt Vorschau für Dateien und Verzeichnisse
# dotfiles: Funktionen (aus fzf.alias)

- dotfiles: Prozess Browser (`<Enter>` Beenden, `<Tab>` Mehrfach, `<Ctrl s>` Apps↔Alle):

`fkill {{signal}}`

- dotfiles: Man/tldr Browser (`<Ctrl s>` Modus wechseln (Liste + Preview), `<Enter>` öffnen):

`fman`

- dotfiles: fa Browser (`<Enter>` Übernehmen, `<Ctrl s>` tldr↔Code):

`fa {{suche}}`

- dotfiles: Env Browser (`<Enter>` Export→Edit, `<Ctrl y>` Kopieren):

`fenv`
# dotfiles: Shell-Keybindings (Ctrl+X Prefix)

- dotfiles: History durchsuchen mit Vorschau:

`<Ctrl x> 1`

- dotfiles: Datei suchen mit bat-Vorschau, Pfad einfügen:

`<Ctrl x> 2`

- dotfiles: Verzeichnis wechseln mit eza-Vorschau:

`<Ctrl x> 3`
# dotfiles: Tool-spezifische fzf-Funktionen
