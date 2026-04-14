#!/usr/bin/env bash
set -euo pipefail

repo_path="${CARDANO_BBS_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
baseline_path="$repo_path/specs/001-bbs-credentials/budget-baseline.json"

raw_json="$(mktemp)"
current_json="$(mktemp)"
expected_titles="$(mktemp)"
actual_titles="$(mktemp)"

cleanup() {
  rm -f "$raw_json" "$current_json" "$expected_titles" "$actual_titles"
}
trap cleanup EXIT

(
  cd "$repo_path/onchain"
  aiken check >"$raw_json"
)

jq '
  [
    .modules[]
    | select(.name == "bbs/budget")
    | .tests[]
    | select(.title | startswith("verify_budget_case_total_"))
    | {
        title: .title,
        cpu: .execution_units.cpu,
        mem: .execution_units.mem
      }
  ]
' "$raw_json" >"$current_json"

jq -r '.[].title' "$baseline_path" | sort >"$expected_titles"
jq -r '.[].title' "$current_json" | sort >"$actual_titles"

if ! diff -u "$expected_titles" "$actual_titles"; then
  echo "budget matrix titles differ from baseline" >&2
  exit 1
fi

while IFS=$'\t' read -r title expected_cpu expected_mem; do
  actual_cpu="$(
    jq -r --arg title "$title" '.[] | select(.title == $title) | .cpu' \
      "$current_json"
  )"
  actual_mem="$(
    jq -r --arg title "$title" '.[] | select(.title == $title) | .mem' \
      "$current_json"
  )"

  if [ -z "$actual_cpu" ] || [ -z "$actual_mem" ]; then
    echo "missing budget result for $title" >&2
    exit 1
  fi

  if [ "$actual_cpu" -gt "$expected_cpu" ]; then
    echo "cpu regression for $title: $actual_cpu > $expected_cpu" >&2
    exit 1
  fi

  if [ "$actual_mem" -gt "$expected_mem" ]; then
    echo "memory regression for $title: $actual_mem > $expected_mem" >&2
    exit 1
  fi
done < <(
  jq -r '.[] | [.title, .cpu, .mem] | @tsv' "$baseline_path"
)

jq -r '
  [
    "title\tcpu\tmem",
    (
      .[]
      | [.title, (.cpu | tostring), (.mem | tostring)]
      | @tsv
    )
  ] | .[]
' "$current_json"
