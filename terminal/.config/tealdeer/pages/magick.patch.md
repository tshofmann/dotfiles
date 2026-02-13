- dotfiles: Config `~/.config/ImageMagick/policy.xml (Sicherheit)`

- dotfiles: Nutzt `-`

- dotfiles: Bild skalieren:

`imgresize {{bild, breite, output}}`

- dotfiles: Bild zu WebP konvertieren:

`towebp {{bild, qualität, output}}`

- dotfiles: Bild zu PNG konvertieren:

`topng {{bild, output}}`

- dotfiles: Bild zu JPEG konvertieren (Transparenz wird weiß):

`tojpg {{bild, qualität, output}}`

- dotfiles: Bildinfo anzeigen (Format, Größe, Farbtiefe):

`imgmeta`

- dotfiles: Kurze Bildinfo (nur Basics):

`imgsize`

- dotfiles: Bild zuschneiden:

`imgcrop {{bild, breite, höhe, x, y, output}}`

- dotfiles: Metadaten entfernen (in-place, EXIF/GPS/IPTC weg, ICC-Farbprofil bleibt):

`imgstrip {{bilder}}`
