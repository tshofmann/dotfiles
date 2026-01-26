# catppuccin

> Catppuccin Mocha Theme-Konfiguration für alle Tools.
> Hinweis: Terminal.app und Xcode sind macOS-spezifisch.
> Mehr Informationen: https://catppuccin.com/palette

- Zeige alle Theme-Dateien in diesem Repository:

`fd -HI -e theme -e tmTheme -e xccolortheme catppuccin ~/dotfiles`

- Themes aus offiziellen Catppuccin-Repositories (unverändert):

`Terminal.app: ~/dotfiles/setup/`
`bat: ~/.config/bat/themes/`
`btop: ~/.config/btop/themes/`

- Themes aus Upstream mit lokalen Anpassungen:

`Xcode: ~/dotfiles/setup/ (header)`
`eza: ~/.config/eza/theme.yml (header)`
`fzf: ~/.config/fzf/config (bg+header)`
`kitty: ~/.config/kitty/current-theme.conf (header)`
`lazygit: ~/.config/lazygit/config.yml (mauve+header)`
`starship: ~/.config/starship/starship.toml (palettes+header)`
`yazi: ~/.config/yazi/theme.toml (mauve+text+header)`
`zsh-syntax: ~/.config/zsh/catppuccin_mocha-* (header)`

- Manuell konfiguriert (basierend auf catppuccin.com/palette):

`fastfetch: ~/.config/fastfetch/config.jsonc (kein offizielles Repo)`
`jq: ~/.config/theme-style (kein offizielles Repo)`
`tealdeer: ~/.config/tealdeer/config.toml (kein offizielles Repo)`
`theme-style: ~/.config/theme-style (kein offizielles Repo)`

- Zentrale Shell-Farbvariablen in Skripten nutzen:

`source ~/.config/theme-style && echo "\${C_GREEN}Erfolg\${C_RESET}"`

- Upstream Theme-Repositories:

`Terminal.app: github.com/catppuccin/Terminal.app`
`Xcode: github.com/catppuccin/xcode`
`bat: github.com/catppuccin/bat`
`btop: github.com/catppuccin/btop`
`eza: github.com/catppuccin/eza`
`fzf: github.com/catppuccin/fzf`
`kitty: github.com/catppuccin/kitty`
`lazygit: github.com/catppuccin/lazygit`
`starship: github.com/catppuccin/starship`
`yazi: github.com/catppuccin/yazi`
`zsh-syntax: github.com/catppuccin/zsh-syntax-highlighting`

