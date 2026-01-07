# ============================================================
# init.zsh - fzf Shell-Integration
# ============================================================
# Zweck   : fzf Keybindings und fd-Backend aktivieren
# Pfad    : ~/.config/fzf/init.zsh
# Docs    : https://github.com/junegunn/fzf#usage
# ============================================================
# Hinweis : Wird via .zshrc geladen. Keybindings:
#           Ctrl+X 1 = History, Ctrl+X 2 = Datei, Ctrl+X 3 = Verzeichnis
# ============================================================

# Shell-Integration aktivieren
source <(fzf --zsh)

# Keybindings umlegen auf Ctrl+X Prefix (Alt+C funktioniert nicht ohne Meta-Taste)
bindkey -r '^R'                          # Standard-Binding entfernen
bindkey -r '^T'                          # Standard-Binding entfernen
bindkey '^X1' fzf-history-widget         # Ctrl+X 1 = History
bindkey '^X2' fzf-file-widget            # Ctrl+X 2 = Dateien
bindkey '^X3' fzf-cd-widget              # Ctrl+X 3 = Verzeichnisse

# fd als Backend (schneller als find, respektiert .gitignore)
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
fi

# Ctrl+X 1: History-Suche mit Kopier-Funktion
export FZF_CTRL_R_OPTS="
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --header 'Ctrl+Y: Kopieren'"

# Ctrl+X 2: Dateisuche mit Syntax-Highlighting Vorschau
if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range=:500 {}'"
fi

# Ctrl+X 3: Verzeichniswechsel mit Baum-Vorschau
if command -v eza >/dev/null 2>&1; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=1 --icons --color=always {}'"
fi
