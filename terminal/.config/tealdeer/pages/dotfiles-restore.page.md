# dotfiles-restore

> Stellt den Zustand vor der dotfiles-Installation wieder her.
> Das Backup wird automatisch beim ersten Bootstrap erstellt.
> Mehr Informationen: <https://github.com/tshofmann/dotfiles#readme>

- Wiederherstellung starten (mit Bestätigung):

`./setup/restore.sh`

- Wiederherstellung ohne Bestätigung:

`./setup/restore.sh --yes`

- Vollständige Deinstallation (Symlinks + Pakete + Repository):

`./setup/restore.sh --cleanup`

- Vorschau: Was würde --cleanup entfernen (ohne Aktion):

`./setup/restore.sh --cleanup --dry-run`

- Vollständige Deinstallation ohne Bestätigung:

`./setup/restore.sh --cleanup --yes`

- Hilfe anzeigen:

`./setup/restore.sh --help`

# Was passiert?

- Entfernt alle dotfiles-Symlinks aus ~

- Stellt gesicherte Originaldateien wieder her

- Setzt Terminal-Profil auf "Basic" zurück

# Mit --cleanup zusätzlich:

- Entfernt Homebrew-Pakete aus dem Brewfile (interaktiv pro Kategorie)

- Entfernt Homebrew-Taps aus dem Brewfile (interaktiv)

- Entfernt das Repository ~/dotfiles

# Backup-Speicherort

- Backup-Verzeichnis:

`~/dotfiles/.backup/`

- Manifest mit allen Dateien:

`~/dotfiles/.backup/manifest.json`

- Gesicherte Originaldateien:

`~/dotfiles/.backup/home/`

# Wichtig

- Das erste Backup wird NIE überschrieben (Idempotenz)

- Backup bleibt nach Restore erhalten (wird mit --cleanup + Repo-Löschung entfernt)

- --dry-run nur zusammen mit --cleanup verwendbar

- Backup nach normalem Restore manuell löschen:

`rm -rf ~/dotfiles/.backup/`
