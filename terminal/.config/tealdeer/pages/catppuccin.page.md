# catppuccin

> Catppuccin Mocha Theme-Konfiguration für alle Tools.
> Mehr Informationen: https://catppuccin.com/palette

- Zeige alle Theme-Dateien in diesem Repository:

`fd -HI -e theme -e tmTheme -e xccolortheme catppuccin ~/dotfiles`

- Themes aus offiziellen Catppuccin-Repositories (unverändert):

`Terminal.app: ~/dotfiles/setup/`
`Xcode: ~/dotfiles/setup/`
`bat: ~/.config/bat/themes/`
`btop: ~/.config/btop/themes/`
`lazygit: ~/.config/lazygit/config.yml`
`zsh-syntax: ~/.config/zsh/catppuccin_mocha-*`

- Themes aus Upstream mit lokalen Anpassungen:

`eza: ~/.config/eza/theme.yml (header)`
`fzf: ~/.config/fzf/config (bg)`
`starship: ~/.config/starship.toml (generiert (bootstrap))`

- Manuell konfiguriert (basierend auf catppuccin.com/palette):

`fastfetch: ~/.config/fastfetch/config.jsonc (kein offizielles Repo)`
`tealdeer: ~/.config/tealdeer/config.toml (kein offizielles Repo)`
`theme-colors: ~/.config/theme-colors (kein offizielles Repo)`

- Zentrale Shell-Farbvariablen in Skripten nutzen:

`source ~/.config/theme-colors && echo "\${C_GREEN}Erfolg\${C_RESET}"`

- Upstream Theme-Repositories:

`Terminal.app: github.com/catppuccin/Terminal.app`
`Xcode: github.com/catppuccin/xcode`
`bat: github.com/catppuccin/bat`
`btop: github.com/catppuccin/btop`
`eza: github.com/catppuccin/eza`
`fzf: github.com/catppuccin/fzf`
`lazygit: github.com/catppuccin/lazygit`
`starship: github.com/catppuccin/starship`
`zsh-syntax: github.com/catppuccin/zsh-syntax-highlighting`