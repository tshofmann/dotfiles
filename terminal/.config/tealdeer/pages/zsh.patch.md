# dotfiles: Konfigurationsdateien

- dotfiles: `~/.zshenv` – Umgebungsvariablen (XDG-Pfade)

- dotfiles: `~/.zshrc` – Hauptkonfiguration für interaktive Shells

- dotfiles: Lade-Reihenfolge: `.zshenv → .zprofile → .zshrc → .zlogin`

# dotfiles: XDG Base Directory

- dotfiles: `$XDG_CONFIG_HOME` → `~/.config` für alle Tool-Configs

- dotfiles: `$EZA_CONFIG_DIR` und `$TEALDEER_CONFIG_DIR` und `$STARSHIP_CONFIG` explizit gesetzt (macOS)

# dotfiles: History-Konfiguration

- dotfiles: Zentrale History in `~/.zsh_history` (25.000 Einträge)

- dotfiles: `SHELL_SESSIONS_DISABLE=1` – keine separate History pro Tab

- dotfiles: Führende Leerzeichen verbergen Befehle aus History (`HIST_IGNORE_SPACE`)

# dotfiles: Alias-System

- dotfiles: Alle `.alias`-Dateien aus `~/.config/alias/` werden geladen

- dotfiles: Farben aus `~/.config/theme-style` (`$C_GREEN`, `$C_RED`, etc.)

# dotfiles: Tool-Integrationen

- dotfiles: fzf – `~/.config/fzf/init.zsh` und `config`

- dotfiles: zoxide – z &lt;query&gt; = schnell wechseln, zi = interaktiv mit fzf

- dotfiles: bat – Man-Pages mit Syntax-Highlighting (`$MANPAGER`)

- dotfiles: starship – Shell-Prompt (tldr starship)

- dotfiles: gh – GitHub CLI Completions

# dotfiles: ZSH-Plugins

- dotfiles: zsh-autosuggestions – Vorschläge aus History:

`→ Vorschlag komplett übernehmen, Alt+→ Wort für Wort übernehmen, Escape Vorschlag ignorieren`

- dotfiles: zsh-syntax-highlighting – Farbige Befehlsvalidierung:

`Grün=Gültiger Befehl, Rot=Ungültiger Befehl, Unterstrichen=Existierende Datei/Verzeichnis`

# dotfiles: Completion-System

- dotfiles: Tab-Vervollständigung mit täglicher Cache-Erneuerung

- dotfiles: `compinit` läuft nur einmal täglich vollständig
