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
    # fzf Key Bindings:
    #   Ctrl+R  = History durchsuchen
    #   Ctrl+T  = Datei suchen und einfügen
    #   Alt+C   = Verzeichnis wechseln (cd)
    source <(fzf --zsh)

    # Ctrl+T Vorschau: bat für Dateien (Syntax-Highlighting)
    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range=:500 {}'"
    fi

    # Alt+C Vorschau: eza Tree für Verzeichnisse
    if command -v eza >/dev/null 2>&1; then
        export FZF_ALT_C_OPTS="--preview 'eza --tree --level=1 --icons --color=always {}'"
    fi
fi

if command -v zoxide >/dev/null 2>&1; then
    # zoxide Befehle:
    #   z <query>  = Zu Verzeichnis springen (lernt mit der Zeit)
    #   zi         = Interaktive Auswahl mit fzf
    # Vorschau für zi: eza mit Details
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