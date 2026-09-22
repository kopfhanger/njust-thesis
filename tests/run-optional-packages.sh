#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
compiler=${TYPST_BIN:-$(command -v typst 2>/dev/null || command -v tinymist 2>/dev/null)}
test -n "$compiler" || { echo "no Typst compiler found" >&2; exit 1; }

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/njust-optional.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

fixtures=(
  unify
  lilaq
  lovelace
  fletcher
  physica
  ctheorems
  subpar
)

for fixture in "${fixtures[@]}"; do
  source="$repo_root/tests/optional/$fixture.typ"
  output="$tmp_dir/$fixture.pdf"
  echo "[optional] $fixture"
  "$compiler" compile --font-path "$repo_root/font" "$source" "$output"
  qpdf --check "$output" >/dev/null
  pages=$(pdfinfo "$output" | awk '/^Pages:/ {print $2}')
  test "${pages:-0}" -ge 1 || {
    echo "optional fixture $fixture produced no pages" >&2
    exit 1
  }
  # 标记必须是"只有该包渲染出来才会出现"的字符串；用包名或散文里的词
  # 等于恒真断言（图空白、包失效时依然命中）。
  marker=$fixture
  case "$fixture" in
    ctheorems) marker="定理 1.2" ;;          # 包产出的定理编号
    unify) marker="±" ;;                     # #num("1.20+-0.03") 渲染出的正负号
    lilaq) marker="图 1.1" ;;                # 模板图注 + 包产出的图
    lovelace) marker="图 1.1" ;;
    fletcher) marker="图 1.1" ;;
    physica) marker="×" ;;                   # curl/grad 渲染出的叉乘号
    subpar) marker="subpar 多子图示例" ;;      # 父图题注
  esac
  pdftotext "$output" - | grep -qF "$marker" || {
    echo "optional fixture $fixture is missing its feature marker: $marker" >&2
    exit 1
  }
  # 绘图类 fixture 进一步验证图形带真的有墨迹（阈值 300：实测 964–1474，空图为 0）。
  case "$fixture" in
    fletcher|lilaq|subpar)
      python3 "$repo_root/tests/check-figures.py" "$output" \
        --captions "图1.1" --ink-floor 300 --label "$fixture"
      ;;
  esac
done

echo "NJUST optional package tests passed"
