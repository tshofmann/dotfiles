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
# Aliase laden
# ------------------------------------------------------------
# Catppuccin Mocha ANSI-Farben für Shell-Funktionen
[[ -f "$HOME/.config/shell-colors" ]] && source "$HOME/.config/shell-colors"

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
# fzf: Shell-Integration (Ctrl+X 1=History, Ctrl+X 2=Datei, Ctrl+X 3=Verzeichnis)
if command -v fzf >/dev/null 2>&1; then
    [[ -f "$HOME/.config/fzf/init.zsh" ]] && source "$HOME/.config/fzf/init.zsh"
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
# Autosuggestions: Zeigt Vorschläge aus History
#   →        Vorschlag komplett übernehmen
#   Alt+→    Wort für Wort übernehmen
#   Escape   Vorschlag ignorieren
[[ -f "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Catppuccin Mocha Theme für zsh-syntax-highlighting
# WICHTIG: Muss VOR dem Plugin geladen werden!
[[ -f "$HOME/.config/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]] && \
    source "$HOME/.config/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh"

# Syntax-Highlighting: Farben zeigen Befehlsgültigkeit
#   Grün          Gültiger Befehl
#   Rot           Ungültiger Befehl
#   Unterstrichen Existierende Datei/Verzeichnis
# WICHTIG: Muss als letztes Plugin geladen werden
[[ -f "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
