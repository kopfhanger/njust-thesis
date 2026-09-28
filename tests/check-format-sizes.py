#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""字号合规检查：把学校格式文档规定的关键字号，在渲染结果上逐项核对。

为什么需要这个检查：学校《博士、硕士学位论文撰写格式》对每类元素的字号都有明文规定
（摘要标题 3 号、正文小 4 号、图表内 5 号、页眉小 5 号……），而字号是"改了不报错、
只看渲染才发现"的属性——例如表内文字曾长期沿用 LaTeX resizebox 派生出的 9.5pt。
本闸门用 pdftohtml -xml 读取实际字号（其 size 为实际 pt 的 1.5 倍，脚本已换算），
按内容特征定位元素后断言字号落在容差内；找不到元素直接判失败，避免静默通过。

用法：
  tests/check-format-sizes.py                  # 检查仓库根目录的 main.pdf
  tests/check-format-sizes.py --pdf x.pdf --tol 0.6
"""

import argparse
import collections
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
# pdftohtml -xml 报告的 size 是 PDF 实际字号的 1.5 倍。
SIZE_SCALE = 1.5

# (标签, 行内文本正则, 期望字号 pt, 取最大还是最小字号, 规定出处)
#
# 取 max 的元素：同名文本还可能出现在目录（字号更小）或页眉里，正文实例最大；
# 取 min 的元素：同名文本还会出现在正文交叉引用里（字号更大），图题/表题/表内
# 文字的最小实例才是被检查的对象。
CHECKS = [
    ("摘要标题", r"^摘\s*要$", 16.0, max, "3 号宋体加粗居中"),
    ("英文摘要标题", r"^Abstract$", 16.0, max, "3 号加粗居中"),
    ("目录标题", r"^目\s*录$", 16.0, max, "3 号宋体加粗"),
    ("图目录标题", r"^图目录$", 16.0, max, "3 号宋体加粗"),
    ("表目录标题", r"^表目录$", 16.0, max, "3 号宋体加粗"),
    ("关键词标签", r"^关键词", 14.0, max, "关键词三字 4 号宋体加粗"),
    ("摘要正文", r"^本文研究超音速牛奶喷射", 12.0, max, "小 4 号宋体"),
    ("章标题", r"超音速牛奶喷射的概率动力学", 15.0, max, "小 3 号加粗宋体"),
    ("二级标题", r"超音速喷射模型", 14.0, max, "4 号加粗宋体"),
    ("三级标题", r"喷射过程与基本假设", 12.0, max, "小 4 号加粗宋体"),
    ("图题", r"^图\s*\d+\.\d+", 10.5, min, "5 号宋体（图下）"),
    ("表题", r"^表\s*\d+\.\d+", 10.5, min, "5 号宋体（表上）"),
    ("表内文字", r"过程与观测噪声协方差", 10.5, min, "图表内 5 号宋体"),
    ("页眉", r"博士学位论文", 9.0, min, "小 5 号宋体"),
]


def load(pdf: Path):
    out = subprocess.run(["pdftohtml", "-xml", "-i", "-stdout", str(pdf)],
                         capture_output=True, text=True).stdout
    fonts = {}
    for m in re.finditer(r'<fontspec id="(\d+)"[^>]*size="([\d.]+)"', out):
        fonts[m.group(1)] = float(m.group(2)) / SIZE_SCALE
    spans, page = [], 0
    for line in out.split("\n"):
        if "<page" in line:
            page += 1
        m = re.search(r'<text[^>]*top="(-?\d+)"[^>]*left="(-?\d+)"[^>]*font="(\d+)"[^>]*>(.*?)</text>', line)
        if not m:
            continue
        top, left, fid, text = m.groups()
        spans.append({"page": page, "top": int(top) / SIZE_SCALE, "left": int(left) / SIZE_SCALE,
                      "size": fonts.get(fid, 0.0),
                      "text": re.sub("<[^>]+>", "", text).strip()})
    # 合并同一行的片段：pdftohtml 会把一个视觉行拆成多个 <text>
    lines = collections.defaultdict(list)
    for s in spans:
        lines[(s["page"], round(s["top"] / 4))].append(s)
    merged = []
    for key, group in lines.items():
        group.sort(key=lambda s: s["left"])
        merged.append({"page": key[0], "top": min(s["top"] for s in group),
                       "size": max(s["size"] for s in group),
                       "sizes": [s["size"] for s in group],
                       "text": "".join(s["text"] for s in group).strip()})
    return merged


def main() -> int:
    parser = argparse.ArgumentParser(description="字号合规检查")
    parser.add_argument("--pdf", type=Path, default=REPO_ROOT / "main.pdf")
    parser.add_argument("--tol", type=float, default=0.6, help="字号容差（pt，默认 0.6）")
    parser.add_argument("--label", default=None)
    args = parser.parse_args()
    if not args.pdf.exists():
        print(f"[!] 跳过 {args.pdf}（不存在，先编译）")
        return 0
    label = args.label or args.pdf.name
    lines = load(args.pdf)

    problems = []
    for name, pattern, expect, pick, source in CHECKS:
        hits = [l for l in lines if re.search(pattern, l["text"])]
        if not hits:
            problems.append(f"{name}: 未在 PDF 中找到（应存在且为 {expect}pt，{source}）")
            continue
        actual = pick(h["size"] for h in hits)
        if abs(actual - expect) > args.tol:
            problems.append(f"{name}: 实测 {actual:.1f}pt，规定 {expect}pt（{source}）")

    # 关键词行：标签四号加粗、其余小四，两者必须在同一行内共存
    kw = [l for l in lines if l["text"].startswith("关键词")]
    if not kw:
        problems.append("关键词行未找到")
    else:
        sizes = {round(x, 1) for x in kw[0]["sizes"]}
        if not (any(abs(x - 14.0) <= args.tol for x in sizes) and any(abs(x - 12.0) <= args.tol for x in sizes)):
            problems.append(f"关键词行字号应为标签 14pt + 其余 12pt，实测 {sorted(sizes)}")

    # 分图题注编号形式：学校规定 a)、b)，不得出现 (a)
    sub_new = [l for l in lines if re.match(r"^[a-f]\)", l["text"])]
    sub_old = [l for l in lines if re.match(r"^\([a-f]\)", l["text"])]
    if sub_old:
        problems.append(f"分图题注出现 {len(sub_old)} 处 (a) 形式，学校规定用 a)、b)")
    if len(sub_new) < 4:
        problems.append(f"分图题注只找到 {len(sub_new)} 处 a) 形式，示例应至少含 4 个分图")

    if problems:
        print(f"  [-] {label}: {len(problems)} 项字号/编号不合规")
        for p in problems:
            print(f"        {p}")
        return 1
    print(f"  [+] {label}: {len(CHECKS)} 项字号与分图编号均符合学校规定")
    return 0


if __name__ == "__main__":
    sys.exit(main())
