- dotfiles: Nutzt `qpdf (für pdfflatten)`

- dotfiles: Formularfelder auflisten (Feldnamen, Typen und Optionen):

`pdffields {{pdf}}`

- dotfiles: PDF-Formular befüllen (need_appearances für Umlaute):

`pdffill {{pdf, fdf, output}}`

- dotfiles: Formular einfrieren (via qpdf, Feldwerte bleiben durchsuchbar):

`pdfflatten {{pdf, output}}`

- dotfiles: Seiten rotieren (north/east/south/west/left/right/down):

`pdfrotate {{pdf, richtung, output}}`

- dotfiles: Stempel auflegen (erste Stempelseite auf alle Seiten):

`pdfstamp {{pdf, stempel-pdf, output}}`
