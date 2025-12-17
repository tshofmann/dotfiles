# ============================================================
# .zprofile - ZSH Login-Shell Konfiguration
# ============================================================
# Zweck   : Umgebungsvariablen für Login-Shells (einmalig)
# Pfad    : ~/.zprofile
# Quelle  : ~/dotfiles/terminal/.zprofile
# ============================================================

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi
