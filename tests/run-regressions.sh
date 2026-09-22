#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
compiler=${TYPST_BIN:-$(command -v typst 2>/dev/null || command -v tinymist 2>/dev/null)}
test -n "$compiler" || { echo "no Typst compiler found" >&2; exit 1; }

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/njust-regressions.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

"$compiler" compile --font-path "$repo_root/font" \
  "$repo_root/tests/regression-long-chapter.typ" "$tmp_dir/long.pdf"
"$compiler" compile --font-path "$repo_root/font" \
  "$repo_root/tests/citation.typ" "$tmp_dir/citation.pdf"
"$compiler" compile --font-path "$repo_root/font" \
  "$repo_root/tests/regression-pagination.typ" "$tmp_dir/pagination.pdf"
"$compiler" compile --font-path "$repo_root/font" \
  "$repo_root/tests/cover-chinese-author.typ" "$tmp_dir/chinese-author.pdf"

pages=$(pdfinfo "$tmp_dir/long.pdf" | awk '/^Pages:/ {print $2}')
test "$pages" = 5 || { echo "long chapter regression expected 5 pages, got $pages" >&2; exit 1; }

blank=$(pdftotext -f 4 -l 4 "$tmp_dir/long.pdf" - | tr -d '[:space:]')
test -z "$blank" || { echo "inserted blank page contains text" >&2; exit 1; }

# 首行缩进 ≈ 2em：用“缩进段落 xMin − 版心左边界 xMin”判定，不写死绝对坐标，
# 避免页边距调整后失效（2em = 2 × 12.07pt = 24.14pt）。
pdftotext -f 1 -l 1 -bbox-layout "$tmp_dir/long.pdf" "$tmp_dir/long-page-1.html"
margin_x=$(grep -o 'xMin="[0-9.]*"' "$tmp_dir/long-page-1.html" | head -1 | grep -o '[0-9.]*')
indent_x=$(grep -o 'xMin="[0-9.]*"[^>]*>这是用于验证' "$tmp_dir/long-page-1.html" | head -1 | grep -o '[0-9.]*')
awk -v i="$indent_x" -v m="$margin_x" 'BEGIN {
  d = i - m
  if (d < 23.5 || d > 24.8) {
    printf "first paragraph indent is %.2fpt, expected 2em (24.14pt)\n", d > "/dev/stderr"
    exit 1
  }
}'

pdftotext "$tmp_dir/citation.pdf" "$tmp_dir/citation.txt"
grep -Eq '\[1\].*时间旅行中的概率分布模型' "$tmp_dir/citation.txt"
grep -Eq '\[2\].*时间旅行的时间线分支' "$tmp_dir/citation.txt"
! grep -Eq 'JOHNSON|BROWN' "$tmp_dir/citation.txt"

pagination_pages=$(pdfinfo "$tmp_dir/pagination.pdf" | awk '/^Pages:/ {print $2}')
test "$pagination_pages" = 7 || {
  echo "pagination regression expected 7 pages, got $pagination_pages" >&2
  exit 1
}

# 中文作者名必须使用与“作者”标签一致的楷体粗体，而不是无条件回退到宋体。
# 文字 grep 只能证明姓名还在；字体分流由 check-cover-fonts.py 做字形级断言
# （外封面第 1 页 + 内封面第 2 页都必须是 KaiTi）。
pdftotext -f 2 -l 2 -layout "$tmp_dir/chinese-author.pdf" "$tmp_dir/chinese-author.txt"
grep -q '王一珉' "$tmp_dir/chinese-author.txt" || {
  echo "Chinese-author cover regression lost the author name" >&2
  exit 1
}
grep -q '指导教师： 杨国来 教授' "$tmp_dir/chinese-author.txt" || {
  echo "Chinese-author cover regression lost the advisor line" >&2
  exit 1
}
python3 "$repo_root/tests/check-cover-fonts.py" "$tmp_dir/chinese-author.pdf" \
  --name "王一珉" --family KaiTi --pages 1,2

# 匿名送审（学校格式文档第 7 节）：同一 fixture 以匿名/实名各编译一次，
# 实名版是正向对照——若实名版也读不到姓名，说明下面的"未泄露"断言是恒真的。
"$compiler" compile --font-path "$repo_root/font" --input anonymous=true \
  "$repo_root/tests/anonymous.typ" "$tmp_dir/anonymous.pdf"
"$compiler" compile --font-path "$repo_root/font" --input anonymous=false \
  "$repo_root/tests/anonymous.typ" "$tmp_dir/real-name.pdf"
pdftotext "$tmp_dir/anonymous.pdf" "$tmp_dir/anonymous.txt"
for leaked in 王一珉 杨国来 "Wang Yimin" "Yang Guolai" 致谢正文标记; do
  ! grep -qF "$leaked" "$tmp_dir/anonymous.txt" || {
    echo "anonymous PDF leaks personal information: $leaked" >&2
    exit 1
  }
done
grep -qF '×××' "$tmp_dir/anonymous.txt" || {
  echo "anonymous PDF should mask personal fields instead of dropping them" >&2
  exit 1
}
pdftotext "$tmp_dir/real-name.pdf" "$tmp_dir/real-name.txt"
for expected in 王一珉 杨国来 致谢正文标记; do
  grep -qF "$expected" "$tmp_dir/real-name.txt" || {
    echo "non-anonymous control PDF is missing $expected; the anonymity check would be vacuous" >&2
    exit 1
  }
done

# 字体自检页：必须在换了机器时能逐角色看出字形是否齐全。
"$compiler" compile --font-path "$repo_root/font" \
  "$repo_root/tests/fonts-page.typ" "$tmp_dir/fonts-page.pdf"
pdftotext "$tmp_dir/fonts-page.pdf" "$tmp_dir/fonts-page.txt"
for role in 宋体 黑体 楷体 魏碑 拉丁与数字 数学公式; do
  grep -qF "$role" "$tmp_dir/fonts-page.txt" || {
    echo "fonts-page is missing role: $role" >&2
    exit 1
  }
done

# 空白起步文件：必须能独立编译，且不携带示例论文的假数据。
"$compiler" compile --font-path "$repo_root/font" \
  "$repo_root/template/thesis.typ" "$tmp_dir/starter.pdf"
starter_pages=$(pdfinfo "$tmp_dir/starter.pdf" | awk '/^Pages:/ {print $2}')
test "${starter_pages:-0}" -ge 10 || {
  echo "starter template expected at least 10 pages, got $starter_pages" >&2
  exit 1
}
! pdftotext "$tmp_dir/starter.pdf" - | grep -qF '超音速牛奶'

# Every continuation page of the long paragraph and long table must retain
# both the running header and a bottom page number.
check_page_chrome() {
  page=$1
  pdftotext -f "$page" -l "$page" -layout "$tmp_dir/pagination.pdf" "$tmp_dir/page-$page.txt"
  grep -q '博士学位论文' "$tmp_dir/page-$page.txt" || {
    echo "page $page lost its running header" >&2
    exit 1
  }
  pdftotext -f "$page" -l "$page" -bbox "$tmp_dir/pagination.pdf" "$tmp_dir/page-$page.html"
  # 页脚页码实测在 yMin≈777（页脚上移后与南理工 20mm 对齐），区间取 77x–84x
  grep -Eq 'yMin="(7[7-9][0-9]|8[0-4][0-9])[^\"]*"[^>]*>[0-9]+</word>' "$tmp_dir/page-$page.html" || {
    echo "page $page lost its footer page number" >&2
    exit 1
  }
}

for page in 2 3 4 5 6; do
  check_page_chrome "$page"
done
grep -q '第 16 行参数说明' "$tmp_dir/page-5.txt"
grep -q '第 46 行参数说明' "$tmp_dir/page-6.txt"

(cd "$repo_root" && just compile >/dev/null)
qpdf --check "$repo_root/main.pdf" >/dev/null
if pdffonts "$repo_root/main.pdf" | grep -Eq 'DejaVuSansMono|NotoSerifCJKjp'; then
  echo "unexpected system CJK/monospace fallback in main.pdf" >&2
  exit 1
fi

# 示例第 2—6 章实际启用了选定的扩展；检查特征文字，避免包导入或图表
# 因章节整理而被静默删除时仍只凭“主文档能编译”通过。
pdftotext "$repo_root/main.pdf" "$tmp_dir/main.txt"
for marker in ChatGPT 深度求索 克莱登 布莱登; do
  grep -qF "$marker" "$tmp_dir/main.txt" || {
    echo "main.pdf is missing example identity marker: $marker" >&2
    exit 1
  }
done
if grep -Eq '图[[:space:]]+图|表[[:space:]]+表|式[[:space:]]+式|公式[[:space:]]+公式|算法[[:space:]]+算法' "$tmp_dir/main.txt"; then
  echo "main.pdf contains a duplicated reference supplement" >&2
  exit 1
fi
for marker in Physica Lilaq Lovelace Fletcher 单位绑定; do
  grep -q "$marker" "$tmp_dir/main.txt" || {
    echo "main.pdf is missing optional-extension marker: $marker" >&2
    exit 1
  }
done
grep -q '定义 3\.' "$tmp_dir/main.txt" || {
  echo "main.pdf is missing the Chinese ctheorems example" >&2
  exit 1
}
! grep -q 'Gribouille\|plotsy-3d\|CeTZ-Plot' "$tmp_dir/main.txt"

# 上面的特征串只能证明"包被用到了"；下面进一步证明"图真的画出来了"：
# 对按包集成的题注逐一检查题注上方图形带的非文字墨迹（空图实测为 0）。
python3 "$repo_root/tests/check-figures.py" "$repo_root/main.pdf" \
  --captions "图1.2,图2.1,图2.2,图3.1,图4.1,图4.2,图4.3,图5.1,图5.2,图5.3" \
  --ink-floor 10 --label "默认样例图注"

# 算法块：题注在框上方，图形墨迹检查不适用，改为检查结构与输入输出标记都在。
for marker in "算法 5.1" "概率响应估计算法" "输入：" "输出："; do
  grep -qF "$marker" "$tmp_dir/main.txt" || {
    echo "main.pdf is missing algorithm marker: $marker" >&2
    exit 1
  }
done

# Front-matter pages inserted to reach an odd page are physically empty and
# must not expose Roman page numbers.
# 空白插入页的位置随前置内容长度变化：摘要与目录变长后，p12、p16 不再是空白页。
for page in 10 18 20; do
  blank=$(pdftotext -f "$page" -l "$page" "$repo_root/main.pdf" - | tr -d '[:space:]')
  test -z "$blank" || {
    echo "front-matter inserted page $page is not empty" >&2
    exit 1
  }
done

# 跨页长表：学校格式文档要求续表重复表的编排，长表的表头必须在续页重复出现。
long_pages=0
for page in $(seq 1 "$(pdfinfo "$repo_root/main.pdf" | awk '/^Pages/{print $2}')"); do
  if pdftotext -f "$page" -l "$page" "$repo_root/main.pdf" - 2>/dev/null | grep -q '实测收敛阶'; then
    long_pages=$((long_pages + 1))
  fi
done
test "$long_pages" -ge 2 || {
  echo "long table header does not repeat on continuation pages (found on $long_pages page)" >&2
  exit 1
}

# 版心越界：行间公式、表格列宽或子图内容超出 25mm 版心时 Typst 不报错，
# 因此逐页用渲染墨迹核对左右边界（容差 2pt，用于吸收居中排版的亚像素误差）。
python3 "$repo_root/tests/check-overflow.py" --pdf "$repo_root/main.pdf" \
  --label "默认样例版心" --tol-pt 2

# 逐页遍历分页不变量（页眉/页码），取代抽查固定页码：覆盖"章节结束在偶数页
# 因而不需要插空白页"和"章节结束在奇数页因而需要插空白页"两种走向。
python3 "$repo_root/tests/check-pagination.py"

echo "NJUST template regressions passed"
