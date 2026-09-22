#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""题注与图形墨迹校验（证明"图真的画出来了"，而不只是正文提到了包名）。

只查文本会把"图变空"放过去：包 API 变更后图可能渲染成空白，而题注、正文、
包名全都还在。这里对每个期望题注做两件事：

1. 在 PDF 文本层找到该题注（按去掉空格后的前缀匹配，排除图目录的点线行；
   同一题注若有多行匹配，取"上方墨迹最多"的那一行——正文里引用"图4.1..."的
   句子也会命中，但它上方没有图形墨迹）；
2. 统计题注**上方图形带**内的"非文字墨迹"：把该带内每一行像素与页面文字行
   bbox 求差，只数不属于任何文字行的墨迹像素。正文段落完全落在文字行内，
   因此该指标对散文不敏感，只有真正画出的矢量/位图图形才会计数。

标定（Typst 0.15.1 / 100 dpi / band 260pt，2026-09-21 实测）：
  * 正常 Fletcher 图 = 1474；把同一 figure 内容换成空盒后 = 0；
  * 单图 fixture：fletcher 1474、lilaq 1187、subpar 964；
  * 默认样例 23 个真实题注最小 24（小型示意图，笔画行与标签行重合），
    因此样例用低阈值做"非空"检查，单图 fixture 用高阈值。

边界：若某图上方紧邻三线表，表格线会被计入"非文字墨迹"；这只会在
"图本该为空却恰好紧贴表格"时放宽判定，不会误报。

用法：
  tests/check-figures.py main.pdf --captions 图2.1,图2.2,图3.1 --ink-floor 10
  tests/check-figures.py tests/optional/fletcher.pdf --captions 图1.1 --ink-floor 300
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

BODY_TOP_PT = 75.0
BODY_BOTTOM_PT = 770.0
FIGURE_BAND_PT = 260.0
RENDER_DPI = 100
INK_GRAY_THRESHOLD = 250

_INK_TABLE = bytes(1 if value < INK_GRAY_THRESHOLD else 0 for value in range(256))

LINE_RE = re.compile(
    r'<line xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</line>',
    re.S,
)
WORD_RE = re.compile(r"<word[^>]*>([^<]*)</word>")


def page_lines(pdf: Path, page: int):
    """返回 [(yMin, yMax, 去空格的文本)]。"""
    out = subprocess.run(
        ["pdftotext", "-bbox-layout", "-f", str(page), "-l", str(page), str(pdf), "-"],
        capture_output=True, text=True, check=True,
    ).stdout
    rows = []
    for match in LINE_RE.finditer(out):
        text = "".join(WORD_RE.findall(match.group(5)))
        if text.strip():
            rows.append((float(match.group(2)), float(match.group(4)), text.replace(" ", "")))
    return rows


def non_text_ink(pdf: Path, page: int, top: float, bottom: float, text_rows):
    """统计 [top, bottom) 区间内不属于任何文字行的墨迹像素数。"""
    with tempfile.TemporaryDirectory(prefix="njust-figink.") as tmp:
        prefix = os.path.join(tmp, "page")
        subprocess.run(
            ["pdftoppm", "-gray", "-r", str(RENDER_DPI), "-f", str(page), "-l", str(page),
             "-singlefile", str(pdf), prefix],
            check=True, capture_output=True,
        )
        data = Path(prefix + ".pgm").read_bytes()
    match = re.match(rb"P5\s+(\d+)\s+(\d+)\s+(\d+)\s", data)
    if not match:
        sys.exit(f"check-figures: 无法解析渲染结果（第 {page} 页）")
    width, height = int(match.group(1)), int(match.group(2))
    pixels = data[match.end():]
    scale = RENDER_DPI / 72.0
    skip = set()
    for y0, y1 in text_rows:
        skip.update(range(max(int(y0 * scale) - 2, 0), min(int(y1 * scale) + 3, height)))
    start, end = max(int(top * scale), 0), min(int(bottom * scale), height)
    return sum(
        pixels[y * width:(y + 1) * width].translate(_INK_TABLE).count(b"\x01")
        for y in range(start, end) if y not in skip
    )


def find_caption(pdf: Path, token: str):
    """返回题注所在的 (页号, 非文字墨迹)；找不到返回 none。"""
    total = int(re.search(
        r"^Pages:\s+(\d+)",
        subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True, check=True).stdout,
        re.M,
    ).group(1))
    wanted = token.replace(" ", "")
    best = None
    for page in range(1, total + 1):
        rows = page_lines(pdf, page)
        text_rows = [(y0, y1) for y0, y1, _ in rows]
        for y_min, _y_max, text in rows:
            if not text.startswith(wanted) or ".." in text:
                continue
            ink = non_text_ink(pdf, page, max(y_min - FIGURE_BAND_PT, BODY_TOP_PT), y_min, text_rows)
            if best is None or ink > best[1]:
                best = (page, ink)
    return best


def main() -> int:
    parser = argparse.ArgumentParser(description="题注与图形墨迹校验")
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--captions", required=True, help="期望题注前缀，逗号分隔，如 图2.1,图5.3")
    parser.add_argument("--ink-floor", type=int, default=10,
                        help="每个题注上方非文字墨迹的下限（单图 fixture 建议 300）")
    parser.add_argument("--label", default=None, help="报告名称")
    args = parser.parse_args()

    if not args.pdf.exists():
        sys.exit(f"check-figures: 找不到 {args.pdf}")
    label = args.label or args.pdf.name

    problems = []
    for token in [t.strip() for t in args.captions.split(",") if t.strip()]:
        found = find_caption(args.pdf, token)
        if found is None:
            problems.append(f"{token}: 文本层找不到题注（图或章节内容被删除？）")
            continue
        page, ink = found
        if ink < args.ink_floor:
            problems.append(
                f"{token}: 题注在第 {page} 页，但上方图形带只有 {ink} 个非文字墨迹像素"
                f"（下限 {args.ink_floor}）——图可能渲染成空白")
        else:
            print(f"  [+] {token}: 第 {page} 页，题注上方非文字墨迹 {ink}px")

    if problems:
        print(f"  [-] {label}: {len(problems)} 处图形校验失败")
        for item in problems:
            print(f"        {item}")
        return 1
    print(f"  [+] {label}: 题注与图形墨迹全部通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
