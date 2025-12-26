# ============================================================
# .zprofile - ZSH Login-Shell Konfiguration
# ============================================================
# Zweck   : Umgebungsvariablen für Login-Shells (einmalig)
# Pfad    : ~/.zprofile
# Laden   : .zshenv → [.zprofile] → .zshrc → .zlogin
# Docs    : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # Brewfile-Pfad für 'brew bundle' (ohne --file Flag nutzbar)
    export HOMEBREW_BUNDLE_FILE="$HOME/dotfiles/setup/Brewfile"
fi
