# 01 — Ignore generated Helm dependency artifacts

**What to build:** A `.gitignore` rule covering `Chart.lock` and `charts/*.tgz` wherever they appear under `kubernetes-v2/charts/*/`, so that `helm dependency build`'s local output (generated when testing a chart that depends on `common`, e.g. `seerr`) can never be accidentally staged or committed. ADR-0007 explicitly decided nothing vendored should be committed; today nothing enforces that except manual cleanup after every local test.

Scope the pattern so it applies to any chart directory under `kubernetes-v2/charts/`, not just `seerr` or `common`'s current consumers — it needs to keep working as more charts adopt `common` (or any other local dependency) without further edits.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `kubernetes-v2/charts/seerr/Chart.lock` and `kubernetes-v2/charts/seerr/charts/*.tgz` are ignored by git (verify with `git status` after running `helm dependency build` in `kubernetes-v2/charts/seerr`)
- [ ] The pattern is scoped generically under `kubernetes-v2/charts/*/` (or repo-root equivalent), not hardcoded to `seerr`, so a new chart adopting `common` in the future is covered without a `.gitignore` edit
- [ ] Existing tracked files are unaffected (the rule only ignores untracked matches; confirm no currently-committed file matches the new pattern)
