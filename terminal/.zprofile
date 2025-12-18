# ============================================================
# .zprofile - ZSH Login-Shell Konfiguration
# ============================================================
# Zweck   : Umgebungsvariablen für Login-Shells (einmalig)
# Pfad    : ~/.zprofile
# Quelle  : ~/dotfiles/terminal/.zprofile
# Docs    : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
