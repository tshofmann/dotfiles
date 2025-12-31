# ============================================================
# .zshenv - ZSH Environment (wird als erstes geladen)
# ============================================================
# Zweck   : Umgebungsvariablen die VOR allen anderen Configs geladen werden
# Pfad    : ~/.zshenv
# Laden   : [.zshenv] → .zprofile → .zshrc → .zlogin
# Docs    : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# XDG Base Directory Specification
# ------------------------------------------------------------
# Standard-Pfad für Konfigurationsdateien. Wichtig für:
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

# ------------------------------------------------------------
# macOS Session-Wiederherstellung deaktivieren
# ------------------------------------------------------------
# Deaktiviert separate History pro Tab zugunsten einer zentralen
# ~/.zsh_history. Muss hier stehen (vor /etc/zshrc_Apple_Terminal).
SHELL_SESSIONS_DISABLE=1
