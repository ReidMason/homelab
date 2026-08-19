#!/usr/bin/env bash
# Renders each fixture in tests/fixtures/ against this chart and diffs the
# output against the matching snapshot in tests/snapshots/.
#
# Usage:
#   tests/render.sh          # check rendered output against snapshots
#   tests/render.sh --update # regenerate snapshots from current templates
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chart_dir="$(dirname "$script_dir")"
fixtures_dir="$script_dir/fixtures"
snapshots_dir="$script_dir/snapshots"
release_name="test-release"
namespace="test-namespace"

update=false
if [[ "${1:-}" == "--update" ]]; then
  update=true
fi

mkdir -p "$snapshots_dir"

status=0
for fixture in "$fixtures_dir"/*.yaml; do
  name="$(basename "$fixture" .yaml)"
  snapshot="$snapshots_dir/$name.yaml"
  fixture_release_name="$release_name"
  if [[ -f "$fixtures_dir/$name.release" ]]; then
    fixture_release_name="$(<"$fixtures_dir/$name.release")"
  fi
  rendered="$(helm template "$fixture_release_name" "$chart_dir" --namespace "$namespace" -f "$fixture")"

  if $update; then
    printf '%s\n' "$rendered" > "$snapshot"
    echo "updated snapshot: $name"
    continue
  fi

  if [[ ! -f "$snapshot" ]]; then
    echo "missing snapshot for fixture '$name' (run with --update to create it)"
    status=1
    continue
  fi

  if ! diff -u "$snapshot" <(printf '%s\n' "$rendered"); then
    echo "snapshot mismatch for fixture '$name'"
    status=1
  fi
done

if [[ $status -eq 0 ]]; then
  echo "all snapshots match"
fi

exit $status
