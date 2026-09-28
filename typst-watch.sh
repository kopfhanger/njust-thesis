#!/usr/bin/env bash
set -euo pipefail

if (( $# > 1 )); then
  echo "usage: $0 [input.typ]" >&2
  exit 2
fi

exec env TYPST_INPUT="${1:-main.typ}" just watch
