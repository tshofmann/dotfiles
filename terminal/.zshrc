# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck   : Hauptkonfiguration für interaktive ZSH Shells
# Pfad    : ~/.zshrc
# Laden   : .zshenv → .zprofile → [.zshrc] → .zlogin
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
# compinit aktiviert Tab-Vervollständigung (z.B. git <Tab>)
# Cache wird täglich erneuert, sonst schneller Start mit -C
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
    compinit -i                 # Volle Initialisierung wenn >24h alt
else
    compinit -i -C              # Cache nutzen wenn aktuell
fi

# ------------------------------------------------------------
# fzf-tab: Fuzzy Tab-Completion
# ------------------------------------------------------------
# KRITISCH: Muss nach compinit aber vor zsh-autosuggestions geladen werden!
# Docs: https://github.com/Aloxaf/fzf-tab
FZF_TAB_DIR="${HOME}/.config/zsh/plugins/fzf-tab"
if [[ -f "$FZF_TAB_DIR/fzf-tab.plugin.zsh" ]]; then
    source "$FZF_TAB_DIR/fzf-tab.plugin.zsh"
fi

# ------------------------------------------------------------
# Aliase laden
# ------------------------------------------------------------
# Lädt alle .alias-Dateien aus ~/.config/alias/
for alias_file in "$HOME/.config/alias"/*.alias(N-.on); do
    source "$alias_file"
done

# ------------------------------------------------------------
# Tool-Konfigurationen
# ------------------------------------------------------------
# Config-Dateien für fzf, ripgrep und bat liegen in ~/.config/
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/config"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
# bat nutzt automatisch ~/.config/bat/config

# eza: Icons automatisch aktivieren wenn Terminal unterstützt wird
export EZA_ICONS_AUTO=1

# ------------------------------------------------------------
# Tools initialisieren
# ------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
    # Ctrl+R = History, Ctrl+T = Datei suchen, Alt+C = Verzeichnis wechseln
    source <(fzf --zsh)

    # fd als Backend (schneller als find, ignoriert .git)
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
    fi

    # CTRL-T: Dateien suchen mit erweiterten Optionen
    export FZF_CTRL_T_OPTS="
        --walker-skip .git,node_modules,target,.venv,__pycache__,.cache
        --preview 'bat -n --color=always --line-range=:200 {} 2>/dev/null || eza --tree --level=2 --icons --color=always {} 2>/dev/null || cat {}'
        --bind 'ctrl-/:change-preview-window(down|hidden|)'
        --header 'CTRL-/: Preview umschalten'"

    # CTRL-R: History mit erweiterten Optionen
    export FZF_CTRL_R_OPTS="
        --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
        --preview 'echo {2..} | bat --color=always -l zsh --style=plain'
        --preview-window 'down:3:wrap:hidden'
        --bind '?:toggle-preview'
        --header 'CTRL-Y: Kopieren | ?: Preview'"

    # ALT-C: Verzeichnis wechseln mit erweiterten Optionen
    export FZF_ALT_C_OPTS="
        --walker-skip .git,node_modules,target,.venv,__pycache__,.cache
        --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || tree -C {} | head -50'
        --header 'Verzeichnis wählen'"

    # Fuzzy completion mit fd (für vim **<TAB>, etc.)
    if command -v fd >/dev/null 2>&1; then
        _fzf_compgen_path() {
            fd --hidden --follow --exclude .git --exclude node_modules . "$1"
        }
        _fzf_compgen_dir() {
            fd --type d --hidden --follow --exclude .git --exclude node_modules . "$1"
        }
    fi
fi

# Man-Pages mit Syntax-Highlighting
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -plman'"
fi

if command -v zoxide >/dev/null 2>&1; then
    # z <query> = schnell wechseln, zi = interaktiv mit fzf
    if command -v eza >/dev/null 2>&1; then
        export _ZO_FZF_OPTS="--preview 'eza -la --icons --color=always {2..}'"
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
# ZSH-Plugins (am Ende laden)
# ------------------------------------------------------------
# Autosuggestions: Zeigt Vorschläge aus History (→ zum Akzeptieren)
[[ -f "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax-Highlighting: Muss als letztes geladen werden
[[ -f "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
