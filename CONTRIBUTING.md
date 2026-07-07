# Contributing

## Workflow

1. Branch off `main` (direct pushes to `main` are blocked by a ruleset).
2. Make your change; keep the quality gate green locally:
   ```bash
   npm ci
   npm run lint && npm run format:check && npm run typecheck && npm test
   ```
3. Open a Pull Request. CI must pass (quality gate on Node 22/24, CodeQL,
   dependency review, Trivy, PR-title lint) before it can be merged.
4. Merge with **squash**. The squash commit becomes the release entry.

## Commit / PR title convention

Titles must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add rate limiting to the API
fix: handle empty request body
docs: document the release flow
```

Allowed types: `feat`, `fix`, `docs`, `perf`, `refactor`, `test`, `build`,
`ci`, `chore`, `revert`.

Versioning and the changelog are automated by **release-please** from these
titles: `feat` -> minor bump, `fix` -> patch bump, `feat!`/`BREAKING CHANGE`
-> major bump.
