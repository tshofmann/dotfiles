- dotfiles: Config `~/.config/fzf/ (config, init.zsh, Helper-Skripte)`

- dotfiles: Nutzt `bat (Preview), eza (Verzeichnis-Preview), fd (Default-Command), tldr (fman)`

# dotfiles: Globale Tastenkürzel (in allen fzf-Dialogen)

- dotfiles: Vorschau ein-/ausblenden:

`<Ctrl />`

- dotfiles: Alle auswählen (im Multi-Modus):

`<Ctrl a>`

- dotfiles: Einzelnen Eintrag zur Auswahl hinzufügen:

`<Tab>`
# dotfiles: Helper-Skripte (~/.config/fzf/)

- dotfiles: `config` – Globale fzf-Optionen (Farben, Layout, Keybindings)

- dotfiles: `init.zsh` – Shell-Integration (Ctrl+X Keybindings, FZF_DEFAULT_COMMAND)

- dotfiles: `preview-file` – Datei-Vorschau mit bat und Syntax-Highlighting

- dotfiles: `preview-dir` – Verzeichnis-Vorschau mit eza --tree

- dotfiles: `fman-preview` – Man-Page/tldr Vorschau für fman-Funktion

- dotfiles: `fa-preview` – Alias/Funktions-Code-Vorschau für fa-Funktion

- dotfiles: `fkill-list` – Prozessliste für fkill-Funktion

- dotfiles: `safe-action` – Sichere Aktionen (copy, edit, git-diff, etc.)


# dotfiles: Funktionen (aus fzf.alias)

- dotfiles: Prozess Browser (`<Enter>` Beenden, `<Tab>` Mehrfach, `<Ctrl s>` Apps↔Alle):

`fkill {{signal}}`

- dotfiles: Man/tldr Browser (`<Ctrl s>` Modus wechseln, `<Enter>` je nach Modus öffnen):

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
