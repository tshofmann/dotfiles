# poppler

> Praktische Aliase für PDF-Operationen.
> Mehr Informationen: <https://poppler.freedesktop.org/>

- dotfiles: Nutzt `-`

- dotfiles: PDF zu Text konvertieren (Layout beibehalten):

`pdf2txt`

- dotfiles: PDF zu Bildern konvertieren:

`pdf2img {{pdf, auflösung, format}}`

- dotfiles: PDF-Metadaten anzeigen:

`pdfmeta`

- dotfiles: PDF Seitenzahl anzeigen:

`pdfpages {{pdf}}`

- dotfiles: PDF-Seiten einzeln extrahieren (%d = Seitennummer):

`pdfsplit {{pdf, muster}}`

- dotfiles: PDFs zusammenfügen (Standard: merged.pdf, Überschreibschutz):

`pdfmerge {{pdf, pdf, ..., output}}`
