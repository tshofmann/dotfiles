# kitty

> GPU-beschleunigtes Terminal mit Image-Protokoll und Shell-Integration.
> Konfiguriert via `~/.config/kitty/kitty.conf` (dotfiles).
> Mehr Informationen: https://sw.kovidgoyal.net/kitty/

- Config-Dateien anzeigen:

`ls ~/.config/kitty/`

- Kitty mit Debug-Modus starten:

`kitty --debug-input`

- SSH mit automatischer Kitty-Terminfo-Installation:

`kitten ssh benutzer@host`

- Theme wechseln (interaktiv):

`kitten themes`

- Aktuelles Theme anzeigen:

`cat ~/.config/kitty/current-theme.conf`

- Bildvorschau direkt im Terminal (Kitty-Protokoll):

`kitten icat bild.png`

- Config neu laden ohne Neustart:

`ctrl+shift+f5`

- dotfiles: Catppuccin Mocha Theme (eingebaut seit v0.26)
- dotfiles: Shell-Integration für ZSH (Jump-to-Prompt, Last-Command-Output)
- dotfiles: macOS-optimiert (Option als Alt, Titlebar-Farbe)
- dotfiles: Yazi-Previews funktionieren (Image-Protokoll)
