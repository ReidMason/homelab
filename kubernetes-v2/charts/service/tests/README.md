# Rendering tests

`helm template` + snapshot comparison, no plugins required.

- `fixtures/<name>.yaml` — a values file exercising one opt-in combination.
- `snapshots/<name>.yaml` — the expected `helm template` output for that fixture, rendered with release name `test-release` in namespace `test-namespace`.
- `fixtures/<name>.release` (optional) — overrides the release name used for that one fixture, e.g. to byte-match an existing chart's hardcoded resource names.
- `render.sh` — renders every fixture and diffs it against its snapshot; `render.sh --update` regenerates snapshots after an intentional template change.

To add a fixture-based test: drop a new values file in `fixtures/`, run `tests/render.sh --update` once to generate its snapshot, then review the generated snapshot by hand before committing it.
