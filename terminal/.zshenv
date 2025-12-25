# ============================================================
# .zshenv - ZSH Environment (wird als erstes geladen)
# ============================================================
# Zweck   : Umgebungsvariablen die VOR allen anderen Configs geladen werden
# Pfad    : ~/.zshenv
# Quelle  : ~/dotfiles/terminal/.zshenv
# Docs    : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# macOS zsh Session-Wiederherstellung deaktivieren
# ------------------------------------------------------------
# macOS Terminal.app speichert standardmäßig separate History pro Tab/Fenster
# in ~/.zsh_sessions/. Diese Variable deaktiviert das Feature zugunsten
# einer zentralen ~/.zsh_history (konfiguriert in .zshrc).
#
# WICHTIG: Muss in .zshenv gesetzt werden, da /etc/zshrc_Apple_Terminal
# VOR .zprofile und .zshrc geladen wird.
# Ref: /etc/zshrc_Apple_Terminal (Zeile "SHELL_SESSIONS_DISABLE")
SHELL_SESSIONS_DISABLE=1
