# ============================================================
# fzf - Shell-Integration
# ============================================================
# Zweck   : fzf Keybindings und fd-Backend aktivieren
# Laden   : Via .zshrc
# Docs    : https://github.com/junegunn/fzf#usage
# ============================================================
# Keybindings:
#   Ctrl+R = History durchsuchen (Ctrl+Y kopiert)
#   Ctrl+T = Datei suchen
#   Alt+C  = Verzeichnis wechseln
# ============================================================

# Shell-Integration aktivieren
source <(fzf --zsh)

# fd als Backend (schneller als find, respektiert .gitignore)
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
fi

# Ctrl+R: History-Suche mit Kopier-Funktion
export FZF_CTRL_R_OPTS="
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --header 'Ctrl+Y: Kopieren'"

# Ctrl+T: Dateisuche mit Syntax-Highlighting Vorschau
if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range=:500 {}'"
fi

# Alt+C: Verzeichniswechsel mit Baum-Vorschau
if command -v eza >/dev/null 2>&1; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=1 --icons --color=always {}'"
fi
