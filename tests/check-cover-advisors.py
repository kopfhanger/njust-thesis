#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""封面协同导师回归（姓名可见性、行距与槽位稳定性）。

封面的协同导师槽位是写死尺寸的几何（`box(width: 299pt, height: 28.8pt)` 加 `move`），
改动封面字号、行距或字段顺序时最容易在这里出问题：协导姓名可能与导师行重叠、可能被
压到后续字段上，或者"有没有协导"会连带改变下方字段的位置。这些都无法靠文本 grep 发现。

两条可机检的不变量：
1. 有协导时，外封面 / 中文封二 / 英文封二都出现协导姓名与职称，协导行在导师行下方且
   行距落在给定区间内；中文封面上的导师与协导姓名都必须是楷体。
2. 协导存在与否，封面下方字段（学校名、英文机构/月份等）的纵坐标必须一致——说明空槽位
   被保留，版面不随字段多少漂移。

用法：
  tests/check-cover-advisors.py --with x.pdf --without y.pdf
"""

import argparse
import re
import subprocess
import sys

PT2MM = 25.4 / 72.0


def words(pdf, page):
    out = subprocess.run(["pdftotext", "-f", str(page), "-l", str(page), "-bbox-layout", pdf, "-"],
                         capture_output=True, text=True).stdout
    res = []
    for m in re.finditer(
            r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>', out):
        res.append({"x": float(m.group(1)), "y": float(m.group(2)),
                    "x1": float(m.group(3)), "y1": float(m.group(4)), "text": m.group(5)})
    return res


def lines(pdf, page):
    merged = []
    for w in sorted(words(pdf, page), key=lambda w: (w["y"], w["x"])):
        for ln in merged:
            if abs(ln["y"] - w["y"]) <= 3:
                ln["y"] = min(ln["y"], w["y"])
                ln["y1"] = max(ln["y1"], w["y1"])
                ln["text"] += w["text"]
                break
        else:
            merged.append({"y": w["y"], "y1": w["y1"], "text": w["text"]})
    return sorted(merged, key=lambda l: l["y"])


def find_line(pdf, page, needles):
    for ln in lines(pdf, page):
        if all(n in ln["text"] for n in needles):
            return ln
    return None


def kaiti_names(pdf, names):
    """返回中文封面上未落在楷体的姓名列表。"""
    out = subprocess.run(["pdftohtml", "-xml", "-i", "-stdout", "-f", "1", "-l", "2", pdf],
                         capture_output=True, text=True).stdout
    fonts = {}
    for m in re.finditer(r'<fontspec id="(\d+)"[^>]*family="([^"]*)"', out):
        fonts[m.group(1)] = m.group(2)
    missing = []
    for name in names:
        found = False
        for m in re.finditer(r'<text[^>]*font="(\d+)"[^>]*>(.*?)</text>', out):
            text = re.sub("<[^>]+>", "", m.group(2))
            if name in text and "KaiTi" in fonts.get(m.group(1), ""):
                found = True
                break
        if not found:
            missing.append(name)
    return missing


def main() -> int:
    ap = argparse.ArgumentParser(description="封面协同导师回归")
    ap.add_argument("--with", dest="with_co", required=True)
    ap.add_argument("--without", dest="without_co", required=True)
    ap.add_argument("--label", default="封面协同导师")
    ap.add_argument("--min-gap", type=float, default=15.0, help="导师行到协导行的最小行距（pt）")
    ap.add_argument("--max-gap", type=float, default=30.0, help="导师行到协导行的最大行距（pt）")
    args = ap.parse_args()

    problems = []

    # ---- 1. 协导可见性与行距 ----
    # p1 外封面、p2 中文封二、p3 英文封二
    for page, advisor, coadvisor, what in (
            (1, "杨国来", "王晓锋", "外封面"),
            (2, "杨国来", "王晓锋", "中文封二"),
            (3, "Yang", "Wang", "英文封二")):
        a = find_line(args.with_co, page, [advisor])
        b = find_line(args.with_co, page, [coadvisor])
        if a is None or b is None:
            problems.append(f"{what}（p{page}）缺少导师或协同导师姓名：advisor={a is not None}, coadvisor={b is not None}")
            continue
        gap = b["y"] - a["y"]
        if not (args.min_gap <= gap <= args.max_gap):
            problems.append(f"{what}（p{page}）导师与协同导师行距 {gap:.1f}pt 超出 [{args.min_gap}, {args.max_gap}]pt")
        if b["y"] <= a["y"]:
            problems.append(f"{what}（p{page}）协同导师行未排在导师行下方")

    # 中文封面上的协导姓名必须是楷体
    missing = kaiti_names(args.with_co, ["杨国来", "王晓锋"])
    if missing:
        problems.append("中文封面上未落在楷体的姓名：" + "、".join(missing))

    # ---- 2. 封面固定版式的基线坐标 ----
    # 封面是偏移定位的固定版式（字段用 move 摆放，不随内容流动），因此"槽位高度"
    # 这类改动不会通过锚点位移暴露出来，必须把导师行与协导行的纵坐标作为基线冻结。
    # 基线值取自与学校封面样例对齐后的实测结果；确需调整封面版式时同步更新这里。
    GOLDEN = {
        1: {"杨国来": 547.7, "王晓锋": 569.1},
        2: {"杨国来": 392.2, "王晓锋": 415.7},
        3: {"Yang": 411.1, "Wang": 431.1},
    }
    for page, expect in GOLDEN.items():
        for needle, y in expect.items():
            ln = find_line(args.with_co, page, [needle])
            if ln is None:
                continue
            if abs(ln["y"] - y) > 2.0:
                problems.append(
                    f"{needle}（p{page}）纵坐标 {ln['y']:.1f}pt 偏离封面基线 {y:.1f}pt（容差 2pt）")

    # ---- 3. 槽位稳定性：有无协导时下方字段位置一致 ----
    anchors = ((1, "南京理工大学"), (2, "南京理工大学"), (3, "Mechanical"))
    for page, needle in anchors:
        a = find_line(args.with_co, page, [needle])
        b = find_line(args.without_co, page, [needle])
        if a is None or b is None:
            continue  # 某个 fixture 没有该字段时不做断言
        if abs(a["y"] - b["y"]) > 0.5:
            problems.append(
                f"{needle}（p{page}）在有无协导时纵坐标不一致：{a['y']:.1f}pt vs {b['y']:.1f}pt，"
                "说明协导槽位没有保留固定高度")

    if problems:
        print(f"  [-] {args.label}: {len(problems)} 处不符合封面不变量")
        for p in problems:
            print(f"        {p}")
        return 1
    print(f"  [+] {args.label}: 协导姓名、行距（{args.min_gap}–{args.max_gap}pt）、楷体字形与槽位稳定性均通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
