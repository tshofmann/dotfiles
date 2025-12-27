# Sicherheitsrichtlinie

## Unterstützte Versionen

| Version | Unterstützt |
|---------|-------------|
| main    | ✅          |

## Sicherheitslücke melden

Falls du eine Sicherheitslücke in diesem Repository entdeckst:

1. **Öffne KEIN öffentliches Issue**
2. Sende eine E-Mail an den Repository-Owner oder nutze [GitHub Security Advisories](https://github.com/tshofmann/dotfiles/security/advisories/new)
3. Beschreibe das Problem so detailliert wie möglich
4. Gib uns Zeit zu reagieren, bevor du das Problem öffentlich machst

## Best Practices für Nutzer

### Vor der Installation prüfen

Bevor du dieses Repository auf deinem System installierst:

1. **Code reviewen** – Lies die Skripte durch, insbesondere `setup/bootstrap.sh`
2. **Keine Secrets committen** – Die `.gitignore` schließt sensible Dateien aus
3. **Fork verwenden** – Für eigene Anpassungen einen Fork erstellen

### Nach der Installation

- Keine Passwörter oder API-Keys in den Dotfiles speichern
- Sensible Befehle mit führendem Space eingeben (werden nicht in History gespeichert)
- Regelmäßig `brew update && brew upgrade` ausführen

## Bekannte Sicherheitsaspekte

### Externe Skript-Ausführung

Das Bootstrap-Skript lädt das Homebrew-Installationsskript von GitHub:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Dies ist die [offizielle Homebrew-Installationsmethode](https://brew.sh/). Bei Bedenken kann das Skript vorher heruntergeladen und geprüft werden.

### History-Sicherheit

Die ZSH-Konfiguration enthält `HIST_IGNORE_SPACE` – Befehle mit führendem Space werden nicht gespeichert:

```bash
 export API_KEY="secret"  # Führender Space → nicht in History
```
