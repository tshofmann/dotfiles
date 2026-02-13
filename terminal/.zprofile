# ============================================================
# .zprofile - ZSH Login-Shell Konfiguration
# ============================================================
# Zweck       : Umgebungsvariablen für Login-Shells (einmalig)
# Pfad        : ~/.zprofile
# Laden       : .zshenv → [.zprofile] → .zshrc → .zlogin
# Docs        : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# Dotfiles-Repository Pfad (Single Source of Truth)
# ------------------------------------------------------------
# .zprofile wird via Stow verlinkt: ~/.zprofile → ~/dotfiles/terminal/.zprofile
# Über den Symlink leiten wir den Repo-Pfad dynamisch ab.
if [[ -L "${(%):-%x}" ]]; then
    # Resolve: ~/.zprofile → ~/dotfiles/terminal/.zprofile → ~/dotfiles
    export DOTFILES_DIR="${${(%):-%x}:A:h:h}"
else
    export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
fi

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
# Dynamische Erkennung: Apple Silicon → Intel Mac → Linux
for _brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$_brew_path" ]]; then
        eval "$("$_brew_path" shellenv)"
        # Brewfile-Pfad für 'brew bundle' (ohne --file Flag nutzbar)
        export HOMEBREW_BUNDLE_FILE="$DOTFILES_DIR/setup/Brewfile"
        break
    fi
done
unset _brew_path
