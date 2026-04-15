---
name: 'GitHub Workflow'
description: 'PR/Issue-Handling, Review-Workflow, Merge-Regeln, Templates und Labels'
applyTo: '.github/**'
---

# GitHub Workflow

## PRs und Issues

**PRs niemals eigenständig mergen** – immer den User fragen!

**PRs niemals eigenständig erstellen** – immer den User fragen!

### Merge-Workflow

**VOR jedem Merge:**

```zsh
# 1. CI-Status prüfen
gh pr checks <nr>

# 2. Auf Copilot-Review WARTEN (erscheint nach ~30-60 Sek)
gh pr view <nr> --json reviews | jq '.reviews[] | select(.author.login | contains("copilot"))'

# 3. Review-Kommentare LESEN und BEHEBEN
gh api repos/{owner}/{repo}/pulls/<nr>/reviews

# 4. Erst wenn alle Kommentare adressiert sind: Mergen
```

**Niemals blind mergen** nur weil CI grün ist!

### Review-Thread-Handling

| Regel | Begründung |
| ----- | ---------- |
| Threads einzeln beantworten | Erklärung im Thread dokumentiert |
| Dann erst resolven | Thread-Historie bleibt nachvollziehbar |
| Alle Kommentare prüfen | `get_review_comments` nicht nur `get_reviews` |
| Outdated ≠ Resolved | Auch veraltete Threads explizit auflösen |

```zsh
# Review-Threads auflösen via gh CLI:
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "PRRT_..."}) { thread { isResolved } } }'
```

### Templates

- **Issues:** Templates aus `.github/ISSUE_TEMPLATE/` verwenden (`bug_report.md`, `feature_request.md`)
- **PRs:** Template aus `.github/PULL_REQUEST_TEMPLATE.md` verwenden
  - Checkliste durchgehen (generate-docs, health-check)
  - Art der Änderung markieren
  - Issues verlinken mit `Closes #XX` (nur englische Keywords!)
  - **Label setzen** (siehe `CONTRIBUTING.md#6-labels-setzen`)
