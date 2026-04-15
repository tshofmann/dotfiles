---
name: 'ZSH Shell-Konventionen'
description: 'ZSH-Fallen, Variablen-Quoting, Shell-Syntax und Konventionen für Shell-Skripte'
applyTo: '**/*.{sh,zsh}'
---

# ZSH Shell-Konventionen

## ZSH ist die Ziel-Shell

POSIX sh nur in `setup/install.sh` und `setup/lib/logging.sh` (weil zsh auf frischen Linux-Systemen fehlen kann).

## ZSH-Fallen

### Arithmetik mit set -e

```zsh
# FALSCH – Post-Inkrement gibt den ALTEN Wert zurück:
((count++))
# count=0 → (( count++ )) evaluiert zu 0 → Exit-Code 1 → set -e bricht ab!

# RICHTIG:
(( count++ )) || true

# Bei Vergleichen ist || true NICHT nötig:
(( count >= max )) && break  # OK – Vergleich gibt true/false
```

### fzf Preview mit ZSH-Syntax

```zsh
# Explizit wrappen:
--preview='zsh -c '\''[[ -f "$1" ]] && cat "$1"'\'' -- {}'
```

### Regex für Befehle – Bindestriche erlauben

```zsh
[a-z][a-z0-9_-]*   # RICHTIG (findet bat-theme)
[a-z][a-z0-9_]*    # FALSCH
```

## Variablen und Syntax

- **Immer quoten:** `"$var"` statt `$var`
- **ZSH-Features nutzen:** `[[ ]]`, `${var##pattern}`, Arrays
- **Niemals `/Users/<name>`** – öffentlich sichtbar → `~` oder `$HOME`

## Logging-Systeme

Drei separate Systeme je nach Kontext:

| Kontext | Shell | Logging |
| ------- | ----- | ------- |
| `.github/scripts/` | ZSH | `source "${0:A:h}/lib/log.sh"` → `log()`, `ok()`, `warn()`, `err()` |
| `setup/install.sh` | POSIX sh | `. "$SCRIPT_DIR/lib/logging.sh"` |
| `setup/modules/*.sh` | ZSH | Via `_core.sh` bereitgestellt |
