# ============================================================
# .zshenv - ZSH Environment (wird als erstes geladen)
# ============================================================
# Zweck       : Umgebungsvariablen die VOR allen anderen Configs geladen werden
# Pfad        : ~/.zshenv
# Laden       : [.zshenv] → .zprofile → .zshrc → .zlogin
# Docs        : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# XDG Base Directory Specification
# ------------------------------------------------------------
# Zentraler Config-Pfad ~/.config für alle Tools
#
# Wichtig für:
# - bat (config)
# - btop (btop.conf, themes)
# - fzf (config)
# - ripgrep (config)
# - und weitere Tools die XDG_CONFIG_HOME respektieren
# Docs: https://specifications.freedesktop.org/basedir-spec/latest/
export XDG_CONFIG_HOME="$HOME/.config"

# eza nutzt dirs::config_dir() was auf macOS ~/Library/Application Support
# zurückgibt statt XDG_CONFIG_HOME zu respektieren - daher explizit setzen
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"

# tealdeer nutzt auf macOS ebenfalls ~/Library/Application Support
# statt XDG_CONFIG_HOME - daher explizit setzen
export TEALDEER_CONFIG_DIR="$XDG_CONFIG_HOME/tealdeer"

# starship nutzt ~/.config/starship.toml als Default - für Konsistenz
# (ein Tool = ein Ordner) explizit auf starship/ Unterverzeichnis setzen
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# ------------------------------------------------------------
# Standard-Editor
# ------------------------------------------------------------
# Wird verwendet von: git commit, git rebase -i, Ctrl+X Ctrl+E (ZLE)
export EDITOR="code --wait"
export VISUAL="$EDITOR"

# ------------------------------------------------------------
# LS_COLORS - Dateifarben für Completion und GNU-Tools
# ------------------------------------------------------------
# Catppuccin Mocha Palette: di=Sapphire, ln=Mauve, ex=Green, etc.
# Verwendet von: zsh-completion (list-colors), ls (GNU), grep, etc.
# Docs: https://man7.org/linux/man-pages/man5/dir_colors.5.html
export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

# ------------------------------------------------------------
# macOS Session-Wiederherstellung deaktivieren
# ------------------------------------------------------------
# Eine zentrale ~/.zsh_history statt History pro Terminal-Tab
#
# Deaktiviert separate History pro Tab zugunsten einer zentralen
# ~/.zsh_history. Muss hier stehen (vor /etc/zshrc_Apple_Terminal).
SHELL_SESSIONS_DISABLE=1
