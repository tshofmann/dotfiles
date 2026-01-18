# ============================================================
# .zprofile - ZSH Login-Shell Konfiguration
# ============================================================
# Zweck       : Umgebungsvariablen für Login-Shells (einmalig)
# Pfad        : ~/.zprofile
# Laden       : .zshenv → [.zprofile] → .zshrc → .zlogin
# Docs        : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
# Dynamische Erkennung: Apple Silicon → Intel Mac → Linux
for _brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$_brew_path" ]]; then
        eval "$("$_brew_path" shellenv)"
        # Brewfile-Pfad für 'brew bundle' (ohne --file Flag nutzbar)
        export HOMEBREW_BUNDLE_FILE="$HOME/dotfiles/setup/Brewfile"
        break
    fi
done
unset _brew_path
