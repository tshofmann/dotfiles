# ============================================================
# .zlogin - Post-Login Shell Konfiguration
# ============================================================
# Wird nach .zshrc geladen, NUR bei Login-Shells.
# Ideal für Aufgaben, die nicht den interaktiven Prompt blockieren sollen.
#
# Lade-Reihenfolge: .zshenv → .zprofile → .zshrc → .zlogin
# ============================================================

# ------------------------------------------------------------
# zcompdump Kompilierung (Background)
# ------------------------------------------------------------
# Kompiliert die Completion-Cache-Datei (.zcompdump) zu .zcompdump.zwc
# für potenziell schnellere Ladezeiten bei wachsender Completion-Liste.
#
# Warum hier und nicht in .zshrc?
# - Läuft NACH dem Prompt, blockiert nicht den Shell-Start
# - Der &! (disown) führt es im Hintergrund aus
# - Bei aktuellem Setup (2024) kein messbarer Unterschied, aber:
#   - Vorbereitung für kubectl, nvm, docker etc.
#   - Zero-Cost "Versicherung" für die Zukunft
#
# Die Prüfungen stellen sicher, dass nur kompiliert wird wenn:
# - .zcompdump existiert und nicht leer ist (-s)
# - .zcompdump.zwc fehlt ODER älter als .zcompdump ist
{
    zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
    if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
        zcompile "$zcompdump"
    fi
} &!
