# dotfiles-restore

> Stellt den Zustand vor der dotfiles-Installation wieder her.
> Das Backup wird automatisch beim ersten Bootstrap erstellt.
> Mehr Informationen: <https://github.com/tshofmann/dotfiles#readme>

- Wiederherstellung starten (mit Bestätigung):

`./setup/restore.sh`

- Wiederherstellung ohne Bestätigung:

`./setup/restore.sh --yes`

- Hilfe anzeigen:

`./setup/restore.sh --help`

# Was passiert?

- Entfernt alle dotfiles-Symlinks aus ~

- Stellt gesicherte Originaldateien wieder her

- Setzt Terminal-Profil auf "Basic" zurück

# Backup-Speicherort

- Backup-Verzeichnis:

`.backup/`

- Manifest mit allen Dateien:

`.backup/manifest.json`

- Gesicherte Originaldateien:

`.backup/home/`

# Wichtig

- Das erste Backup wird NIE überschrieben (Idempotenz)

- Backup bleibt nach Restore erhalten

- Zum Löschen: `rm -rf .backup/`
