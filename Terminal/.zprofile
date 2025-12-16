# ============================================================
# .zprofile - ZSH Login-Shell Konfiguration
# ============================================================
# Zweck   : Umgebungsvariablen für Login-Shells (einmalig)
# Pfad    : ~/.zprofile
# Quelle  : ~/dotfiles/Terminal/.zprofile
# ============================================================

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
eval "$(/opt/homebrew/bin/brew shellenv)"
