#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source_script="$script_dir/preflight.sh"

tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT

repo="$tmp_root/persalone-halo"
mkdir -p "$repo/tooling"
cp "$source_script" "$repo/tooling/preflight.sh"

(
  cd "$repo"
  git init -q
  git config user.email test@example.invalid
  git config user.name 'Preflight Test'

  printf '%s\n' 'clean' > safe.txt
  git add safe.txt
  git commit -qm 'seed'

  blocked_marker="AKIA$(printf '%016d' 1)"
  printf '%s\n' "$blocked_marker" > safe.txt
  git add safe.txt
  printf '%s\n' 'clean working tree' > safe.txt

  if bash tooling/preflight.sh >/tmp/preflight-pass.out 2>/tmp/preflight-pass.err; then
    printf '%s\n' 'Expected staged secret scan to fail.' >&2
    exit 1
  fi

  git restore safe.txt
  git restore --staged safe.txt

  printf '%s\n' 'clean staged value' > safe.txt
  git add safe.txt
  bash tooling/preflight.sh

  printf '%s\n' 'empty' > .env
  git add .env
  if bash tooling/preflight.sh >/tmp/preflight-env.out 2>/tmp/preflight-env.err; then
    printf '%s\n' 'Expected sensitive staged path scan to fail.' >&2
    exit 1
  fi
)

printf '%s\n' 'preflight tests passed.'
