#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""封面作者名字体回归（中文作者必须落楷体，而不是回退到宋体）。

文字 grep 查不出字体：`tests/cover-chinese-author.typ` 里“王一珉”即使被渲染成
宋体，文本层依旧存在。这里用 Poppler 的 `pdftohtml -xml` 取每个 text 节点的
`font=` id，再回到 `fontspec` 表解析真实 family，从而做**字形级**断言。

依赖：pdftohtml（Poppler，与 pdftotext/pdftoppm 同包）。无第三方 Python 库。

用法：
  tests/check-cover-fonts.py <cover.pdf> [--name 王一珉] [--family KaiTi] [--pages 1,2]
"""

import argparse
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


def page_fonts(pdf: Path, page: int) -> dict:
    """返回 {字体 id: family}，family 去掉子集前缀。"""
    with tempfile.TemporaryDirectory(prefix="njust-coverfont.") as tmp:
        xml_path = Path(tmp) / f"p{page}.xml"
        proc = subprocess.run(
            ["pdftohtml", "-xml", "-f", str(page), "-l", str(page), "-i", str(pdf), str(xml_path)],
            capture_output=True, text=True,
        )
        if proc.returncode != 0 or not xml_path.exists():
            sys.exit(f"check-cover-fonts: pdftohtml 失败（第 {page} 页）\n{proc.stderr}")
        root = ET.parse(xml_path).getroot()
    fonts = {}
    for spec in root.iter("fontspec"):
        family = spec.get("family", "")
        fonts[spec.get("id")] = family.split("+")[-1] if "+" in family else family
    return fonts


def texts_on_page(pdf: Path, page: int):
    """返回 [(文本, 字体 id)]。"""
    with tempfile.TemporaryDirectory(prefix="njust-coverfont.") as tmp:
        xml_path = Path(tmp) / f"p{page}.xml"
        subprocess.run(
            ["pdftohtml", "-xml", "-f", str(page), "-l", str(page), "-i", str(pdf), str(xml_path)],
            capture_output=True, text=True, check=True,
        )
        root = ET.parse(xml_path).getroot()
    return [(node.text or "", node.get("font")) for node in root.iter("text")]


def main() -> int:
    parser = argparse.ArgumentParser(description="封面作者名字体回归")
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--name", default="王一珉", help="要检查的作者名")
    parser.add_argument("--family", default="KaiTi", help="作者名期望的字体族")
    parser.add_argument("--pages", default="1,2", help="检查的页码（逗号分隔）")
    args = parser.parse_args()

    if not args.pdf.exists():
        sys.exit(f"check-cover-fonts: 找不到 {args.pdf}")

    problems = []
    for page in [int(p) for p in args.pages.split(",") if p.strip()]:
        fonts = page_fonts(args.pdf, page)
        hits = [(text, fonts.get(fid, f"<id {fid}>"))
                for text, fid in texts_on_page(args.pdf, page)
                if args.name in text]
        if not hits:
            problems.append(f"第 {page} 页没有找到作者名 {args.name!r}")
            continue
        families = sorted({family for _, family in hits})
        if not all(args.family in family for family in families):
            problems.append(
                f"第 {page} 页作者名 {args.name!r} 的字体为 {families}，期望包含 {args.family!r}"
                "（中文作者名回退到宋体会与学校样例的楷体封面不符）")
        else:
            print(f"  [+] 第 {page} 页作者名 {args.name!r} → {families[0]}")

    if problems:
        for item in problems:
            print(f"  [-] {item}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
