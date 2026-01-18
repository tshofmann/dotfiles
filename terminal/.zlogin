# ============================================================
# .zlogin - ZSH Post-Login Konfiguration
# ============================================================
# Zweck       : Aufgaben nach dem Login (läuft nach .zshrc)
# Pfad        : ~/.zlogin
# Laden       : .zshenv → .zprofile → .zshrc → [.zlogin]
# Docs        : https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files
# ============================================================

# ------------------------------------------------------------
# Completion-Cache kompilieren (im Hintergrund)
# ------------------------------------------------------------
# Kompiliert .zcompdump zu .zcompdump.zwc für schnelleres Laden.
# Läuft im Hintergrund (&!) - blockiert den Shell-Start nicht.
{
    zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
    if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
        zcompile "$zcompdump"
    fi
} &!
