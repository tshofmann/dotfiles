# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck       : Hauptkonfiguration für interaktive ZSH Shells
# Pfad        : ~/.zshrc
# Laden       : .zshenv → .zprofile → [.zshrc] → .zlogin
# Theme       : ~/.config/theme-style (tldr catppuccin)
# Docs        : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# History-Konfiguration
# ------------------------------------------------------------
# Zentrale History-Datei mit Timestamps und Duplikat-Filterung

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=50000
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
setopt HIST_FIND_NO_DUPS     # Bei History-Suche Duplikate überspringen
setopt HIST_EXPIRE_DUPS_FIRST # Duplikate zuerst löschen wenn History voll
setopt HIST_VERIFY           # History-Expansion (!!) erst in Buffer laden

# ------------------------------------------------------------
# Globbing-Optionen
# ------------------------------------------------------------
# Extended Glob aktiviert #, ##, ^, ~ als Pattern-Operatoren
# Benötigt für (#q...) Glob-Qualifier-Syntax (z.B. bei compinit)
setopt EXTENDED_GLOB

# ------------------------------------------------------------
# Completion-System initialisieren
# ------------------------------------------------------------
# zsh/complist: Ermöglicht Pfeiltasten-Navigation im Completion-Menü
# Muss VOR compinit geladen werden! (-i ignoriert Fehler wenn nicht vorhanden)
zmodload -i zsh/complist

# Tab-Vervollständigung mit täglicher Cache-Erneuerung
# Cache wird täglich erneuert, sonst schneller Start mit -C
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
    compinit -i                 # Volle Initialisierung wenn >24h alt
else
    compinit -i -C              # Cache nutzen wenn aktuell
fi

# Completion-Styles
#   menu select   = Pfeiltasten-Navigation statt nur Tab-Durchlauf
#   list-colors   = Dateifarben aus LS_COLORS + Auswahl-Highlight (ma=)
#                   → wird nach theme-style source gesetzt (braucht RGB-Variablen)
#   matcher-list  = Sequentiell: exakt → case-insensitive → Teilwort → Substring
#   completer     = _complete zuerst, _approximate als Fallback (1 Tippfehler)
#   max-errors    = 1 numeric = exakt 1 Fehler erlaubt (nicht prozentual)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# ------------------------------------------------------------
# Aliase laden
# ------------------------------------------------------------
# Farben und modulare Alias-Dateien aus ~/.config/alias/

# Catppuccin Mocha ANSI-Farben und Text-Styles ($C_GREEN, $C_BOLD, etc.)
# RGB-Werte für LS_COLORS ($RGB_SAPPHIRE, $RGB_MAUVE, etc.)
[[ -f "$HOME/.config/theme-style" ]] && source "$HOME/.config/theme-style"

# LS_COLORS für Completion und Directory-Listings (True-Color 24-bit)
# Verwendet von: zsh list-colors, eza, ls (GNU/Linux), grep
# RGB-Werte + LSCOLORS (macOS/BSD) kommen aus theme-style
# Docs: https://man7.org/linux/man-pages/man5/dir_colors.5.html
#
# Catppuccin Mocha Mapping (harmonisiert mit eza/fzf):
#   di=Mauve  ln=Blue  so=Green  pi=Yellow  ex=Green
#   bd=Mauve/Sky  cd=Mauve/Yellow  su=Crust/Red
#   sg=Crust/Sky  tw=Crust/Green  ow=Crust/Yellow
#
# Guard: Nur setzen wenn RGB-Variablen aus theme-style vorhanden sind
if [[ -n ${RGB_MAUVE-} && -n ${RGB_BLUE-} && -n ${RGB_GREEN-} && -n ${RGB_YELLOW-} ]]; then
    export LS_COLORS="di=38;2;${RGB_MAUVE}:ln=38;2;${RGB_BLUE}:so=38;2;${RGB_GREEN}:pi=38;2;${RGB_YELLOW}:ex=38;2;${RGB_GREEN}:bd=38;2;${RGB_MAUVE};48;2;${RGB_SKY}:cd=38;2;${RGB_MAUVE};48;2;${RGB_YELLOW}:su=38;2;${RGB_CRUST};48;2;${RGB_RED}:sg=38;2;${RGB_CRUST};48;2;${RGB_SKY}:tw=38;2;${RGB_CRUST};48;2;${RGB_GREEN}:ow=38;2;${RGB_CRUST};48;2;${RGB_YELLOW}"

    # Completion-Farben: LS_COLORS für Dateitypen + Catppuccin Highlight für Auswahl
    # ma= Auswahl-Highlight: Bold + Mauve Text auf Surface1 Hintergrund (wie fzf/btop)
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} "ma=1;38;2;${RGB_MAUVE};48;2;${RGB_SURFACE1}"
fi

# Lädt alle .alias-Dateien aus ~/.config/alias/
for alias_file in "$HOME/.config/alias"/*.alias(N-.on); do
    source "$alias_file"
done

# ------------------------------------------------------------
# Tool-Konfigurationen
# ------------------------------------------------------------
# Umgebungsvariablen für XDG-konforme Config-Pfade

export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/config"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
# bat nutzt automatisch ~/.config/bat/config

# eza: Icons automatisch aktivieren wenn Terminal unterstützt wird
export EZA_ICONS_AUTO=1

# ------------------------------------------------------------
# Tools initialisieren
# ------------------------------------------------------------
# Shell-Integrationen für fzf, zoxide, gh, starship

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
# Autosuggestions und Syntax-Highlighting (Reihenfolge wichtig!)

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
#   Grün           Gültiger Befehl
#   Rot            Ungültiger Befehl
#   Unterstrichen  Existierende Datei/Verzeichnis
# WICHTIG: Muss als letztes Plugin geladen werden
[[ -f "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
