# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck   : Hauptkonfiguration für interaktive ZSH Shells
# Pfad    : ~/.zshrc
# Docs    : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# History-Konfiguration
# ------------------------------------------------------------
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=25000
SAVEHIST=25000

# Datei sicher erstellen (chmod 600 = nur Owner lesen/schreiben)
[[ -f "$HISTFILE" ]] || { touch "$HISTFILE" && chmod 600 "$HISTFILE"; }

# Core-Optionen
setopt EXTENDED_HISTORY      # Timestamp + Dauer speichern
setopt INC_APPEND_HISTORY    # Sofort schreiben (nicht erst bei Exit)
setopt HIST_IGNORE_SPACE     # Befehle mit führendem Space ignorieren
setopt HIST_IGNORE_DUPS      # Aufeinanderfolgende Duplikate ignorieren
setopt HIST_REDUCE_BLANKS    # Überflüssige Leerzeichen entfernen
setopt HIST_SAVE_NO_DUPS     # Keine Duplikate in Datei speichern

# ------------------------------------------------------------
# Completion-System initialisieren
# ------------------------------------------------------------
# compinit: Aktiviert Tab-Vervollständigung (z.B. gh <Tab>)
# Optimierung: Cache täglich erneuern, sonst -C (schneller Start)
# Docs: https://zsh.sourceforge.io/Doc/Release/Completion-System.html
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
    compinit -i                 # Volle Initialisierung wenn >24h alt
else
    compinit -i -C              # Cache nutzen wenn aktuell
fi

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
# Tool-Konfigurationen (native Config-Dateien)
# ------------------------------------------------------------
# fzf: Native Config-Datei für globale Defaults
# Docs: https://github.com/junegunn/fzf#environment-variables
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/config"

# ripgrep: Native Config-Datei
# Docs: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# bat: Nutzt automatisch ~/.config/bat/config
# Docs: https://github.com/sharkdp/bat#configuration-file

# ------------------------------------------------------------
# Tools initialisieren
# ------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
    # Key Bindings: Ctrl+R (History), Ctrl+T (Datei), Alt+C (cd)
    source <(fzf --zsh)

    # fd als fzf-Backend (schneller als find, respektiert .gitignore)
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
    fi

    # Ctrl+R History-Suche: Ctrl+Y kopiert ins Clipboard
    export FZF_CTRL_R_OPTS="
        --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
        --header 'Ctrl+Y: In Clipboard kopieren'"

    # Ctrl+T Vorschau mit bat (Syntax-Highlighting)
    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range=:500 {}'"
    fi

    # Alt+C Vorschau mit eza (Baumansicht)
    if command -v eza >/dev/null 2>&1; then
        export FZF_ALT_C_OPTS="--preview 'eza --tree --level=1 --icons --color=always {}'"
    fi
fi

# bat als Man-Page-Pager (Syntax-Highlighting für man)
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -plman'"
fi

if command -v zoxide >/dev/null 2>&1; then
    # Befehle: z <query> (jump), zi (interaktiv mit fzf)
    # zi-Vorschau mit eza (Dateiliste)
    if command -v eza >/dev/null 2>&1; then
        export _ZO_FZF_OPTS="--preview 'eza -la --icons --color=always {2..}' --height=40%"
    fi
    eval "$(zoxide init zsh)"
fi

if command -v gh >/dev/null 2>&1; then
    source <(gh completion -s zsh)  # GitHub CLI Completions
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)" # Shell-Prompt
fi

# ------------------------------------------------------------
# ZSH-Plugins (müssen am Ende geladen werden)
# ------------------------------------------------------------
# zsh-autosuggestions: History-basierte Vorschläge (→ = akzeptieren)
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting: Muss als letztes Plugin geladen werden
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh