#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""版心越界检查：渲染每一页，确认没有墨迹落在 25mm 版心之外。

为什么需要这个检查：行间公式比版心宽时 Typst 会居中排布，两侧同时越界且不报错；
表格列宽之和超出、子图内容宽于子图格时也会静默溢出。排版规则里"任何内容不得超出
左右各 25mm 的版心"是可机检的不变量，因此单独设一道闸门。

判据：100 dpi 灰度渲染后，逐页统计灰度 < 200 的像素的行方向范围，与版心
[25mm, 185mm] 比较；允许 --tol-pt 的容差（默认 2pt ≈ 0.7mm，用于吸收居中排布的
亚像素误差与英文两端对齐的字距溢出，不掩盖真实溢出）。

用法：
  tests/check-overflow.py                      # 检查仓库根目录的 main.pdf
  tests/check-overflow.py --pdf x.pdf --tol-pt 2
  tests/check-overflow.py --pdf main.pdf --pages 30-45 -v
"""

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PT2MM = 25.4 / 72.0
DPI = 100
GRAY_THRESHOLD = 200
# 版心左右边界（pt）：A4 宽 595.28pt，左右各 25mm。
MARGIN_PT = 25 / PT2MM
PAGE_WIDTH_PT = 210 / PT2MM


def num_pages(pdf: Path) -> int:
    out = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True).stdout
    m = re.search(r"^Pages:\s+(\d+)", out, re.M)
    if not m:
        raise SystemExit(f"无法读取页数：{pdf}")
    return int(m.group(1))


def render_gray(pdf: Path, page: int, tmp: Path):
    """把某一页渲染成灰度位图，返回 (宽, 高, 每行墨迹像素数)。"""
    prefix = tmp / f"p{page}"
    subprocess.run(
        ["pdftoppm", "-gray", "-r", str(DPI), "-f", str(page), "-l", str(page),
         "-singlefile", str(pdf), str(prefix)],
        check=True, capture_output=True,
    )
    pgm = prefix.with_suffix(".pgm")
    data = pgm.read_bytes()
    if not data.startswith(b"P5"):
        return None
    rest = data[data.index(b"\n") + 1:]
    while rest.startswith(b"#"):
        rest = rest[rest.index(b"\n") + 1:]
    m = re.match(rb"(\d+)\s+(\d+)\s*\n(\d+)\s*\n", rest)
    if not m:
        return None
    width, height = int(m.group(1)), int(m.group(2))
    pixels = rest[m.end():]
    return width, height, pixels


def page_extent(pdf: Path, page: int, tmp: Path):
    """返回该页墨迹的 x 范围（pt）；整页无墨迹时返回 None。"""
    got = render_gray(pdf, page, tmp)
    if not got:
        return None
    width, height, pixels = got
    xmin, xmax = width, -1
    for y in range(height):
        row = pixels[y * width:(y + 1) * width]
        idx = [x for x, v in enumerate(row) if v < GRAY_THRESHOLD]
        if not idx:
            continue
        if idx[0] < xmin:
            xmin = idx[0]
        if idx[-1] > xmax:
            xmax = idx[-1]
    if xmax < 0:
        return None
    scale = DPI / 72.0
    return xmin / scale, xmax / scale


def parse_pages(spec, total):
    if not spec:
        return list(range(1, total + 1))
    pages = []
    for part in spec.split(","):
        if "-" in part:
            lo, hi = part.split("-")
            pages += list(range(int(lo), int(hi) + 1))
        else:
            pages.append(int(part))
    return [p for p in pages if 1 <= p <= total]


def main() -> int:
    parser = argparse.ArgumentParser(description="版心越界检查")
    parser.add_argument("--pdf", type=Path, default=REPO_ROOT / "main.pdf")
    parser.add_argument("--tol-pt", type=float, default=2.0,
                        help="允许的越界容差（pt，默认 2pt）")
    parser.add_argument("--pages", default=None, help="只检查指定页，如 30-45,50")
    parser.add_argument("--label", default=None, help="报告用名称")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    pdf = args.pdf
    if not pdf.exists():
        print(f"[!] 跳过 {pdf}（不存在，先运行 just compile）")
        return 0

    label = args.label or pdf.name
    total = num_pages(pdf)
    left = MARGIN_PT - args.tol_pt
    right = PAGE_WIDTH_PT - MARGIN_PT + args.tol_pt
    problems = []
    with tempfile.TemporaryDirectory(prefix="njust-overflow.") as tmpdir:
        tmp = Path(tmpdir)
        for page in parse_pages(args.pages, total):
            extent = page_extent(pdf, page, tmp)
            if extent is None:
                continue
            xmin, xmax = extent
            left_over = max(0.0, MARGIN_PT - xmin)
            right_over = max(0.0, xmax - (PAGE_WIDTH_PT - MARGIN_PT))
            if args.verbose:
                print(f"      p{page}: x=[{xmin:.1f}, {xmax:.1f}] pt "
                      f"左余 {MARGIN_PT - xmin:+.1f} 右余 {(PAGE_WIDTH_PT - MARGIN_PT) - xmax:+.1f}")
            if xmin < left or xmax > right:
                over = max(left_over, right_over)
                problems.append(
                    f"p{page}: 墨迹 x=[{xmin * PT2MM:.1f}, {xmax * PT2MM:.1f}] mm，"
                    f"越出版心 {over * PT2MM:.1f} mm"
                )

    if problems:
        print(f"  [-] {label}: {len(problems)} 页越出版心")
        for item in problems[:20]:
            print(f"        {item}")
        if len(problems) > 20:
            print(f"        …… 另有 {len(problems) - 20} 页")
        return 1
    print(f"  [+] {label}: 全部 {total} 页内容均在 25mm 版心内")
    return 0


if __name__ == "__main__":
    sys.exit(main())
