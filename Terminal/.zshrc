# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck   : Hauptkonfiguration für interaktive ZSH Shells
# Pfad    : ~/.zshrc
# Quelle  : ~/dotfiles/Terminal/.zshrc
# ============================================================

# ------------------------------------------------------------
# Aliase laden
# ------------------------------------------------------------
# (N) = NULL_GLOB - kein Fehler wenn leer
# (.) = Nur reguläre Dateien
# (on) = Alphabetisch sortiert
for alias_file in "$HOME/.config/alias"/*.alias(N.on); do
    source "$alias_file"
done

# ------------------------------------------------------------
# Tools initialisieren
# ------------------------------------------------------------
source <(fzf --zsh)         # Fuzzy Finder
eval "$(zoxide init zsh)"   # Smartes cd
eval "$(starship init zsh)" # Prompt