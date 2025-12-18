# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck   : Hauptkonfiguration für interaktive ZSH Shells
# Pfad    : ~/.zshrc
# Docs    : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# Aliase laden
# ------------------------------------------------------------
# (N) = NULL_GLOB - kein Fehler wenn leer
# (-.) = Reguläre Dateien inkl. Symlinks darauf
# (on) = Alphabetisch sortiert
for alias_file in "$HOME/.config/alias"/*.alias(N-.on); do
    source "$alias_file"
done

# ------------------------------------------------------------
# Tools initialisieren
# ------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)     # Fuzzy Finder
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"   # Smartes cd
fi
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)" # Shell-Prompt
fi