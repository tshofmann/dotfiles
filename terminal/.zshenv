# ============================================================
# .zshenv - ZSH Environment (wird als erstes geladen)
# ============================================================
# Zweck   : Umgebungsvariablen die VOR allen anderen Configs geladen werden
# Pfad    : ~/.zshenv
# Laden   : [.zshenv] → .zprofile → .zshrc → .zlogin
# Docs    : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# macOS Session-Wiederherstellung deaktivieren
# ------------------------------------------------------------
# Deaktiviert separate History pro Tab zugunsten einer zentralen
# ~/.zsh_history. Muss hier stehen (vor /etc/zshrc_Apple_Terminal).
SHELL_SESSIONS_DISABLE=1
