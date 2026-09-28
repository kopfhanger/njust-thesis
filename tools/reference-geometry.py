#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""量参考学位论文与模板的页眉/正文/页脚几何与标题间距（零依赖，只用 poppler）。

用法:
  # 逐篇对比表（markdown），参考论文目录由 --dir 给出
  tools/reference-geometry.py table --dir "/path/to/学位论文"

  # 单篇/多篇的详细指标
  tools/reference-geometry.py lines  <pdf>...   # 逐篇：页眉横线、正文上下墨迹、页码、标题间距
  tools/reference-geometry.py ink    <pdf>...   # 逐页墨迹剖面（--rows 打印每页）
  tools/reference-geometry.py headings <pdf>... # 二/三级标题上下间距

  # 指定采样页（默认取文档 30%–85% 区间均匀采样）
  tools/reference-geometry.py lines --pages=21-53 main.pdf

分类规则（不使用固定 y 阈值判定正文）:
  * 页眉横线：渲染墨迹扫描页顶 150pt 内最长的水平墨迹带；
  * 页眉：横线之上的文字行；页码：页面最底部且文字为纯阿拉伯数字的一行；
  * 正文：其余文字行。

依赖: pdftotext / pdftoppm / pdfinfo（poppler-utils）。
"""
import argparse
import importlib.util
import os
import re
import statistics
import subprocess
import sys

PT2MM = 25.4 / 72.0
DPI = 100


def page_text(pdf, p):
    out = subprocess.run(["pdftotext", "-f", str(p), "-l", str(p), "-bbox-layout", pdf, "-"],
                         capture_output=True, text=True).stdout
    if "<page" not in out:
        return None
    words = []
    for m in re.finditer(
            r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>', out):
        words.append((float(m.group(1)), float(m.group(2)),
                      float(m.group(3)), float(m.group(4)), m.group(5)))
    return words


def to_lines(words, tol=4.0):
    lines = []
    for x0, y0, x1, y1, t in sorted(words, key=lambda w: (w[1], w[0])):
        for ln in lines:
            if abs(ln["y0"] - y0) <= tol:
                ln["words"].append((x0, y0, x1, y1, t))
                ln["y0"] = min(ln["y0"], y0)
                ln["y1"] = max(ln["y1"], y1)
                ln["x0"] = min(ln["x0"], x0)
                ln["x1"] = max(ln["x1"], x1)
                break
        else:
            lines.append({"y0": y0, "y1": y1, "x0": x0, "x1": x1,
                          "words": [(x0, y0, x1, y1, t)]})
    for ln in lines:
        ln["words"].sort(key=lambda w: w[0])
        ln["text"] = " ".join(w[4] for w in ln["words"])
    lines.sort(key=lambda l: l["y0"])
    return lines


def gray_rows(pdf, p):
    out = subprocess.run(["pdftoppm", "-gray", "-r", str(DPI), "-f", str(p), "-l", str(p),
                          "-singlefile", pdf], capture_output=True).stdout
    if not out.startswith(b"P5"):
        return None
    rest = out[out.index(b"\n") + 1:]
    while rest.startswith(b"#"):
        rest = rest[rest.index(b"\n") + 1:]
    m = re.match(rb"(\d+)\s+(\d+)\s*\n(\d+)\s*\n", rest)
    if not m:
        return None
    w, h = int(m.group(1)), int(m.group(2))
    data = rest[m.end():]
    return w, h, [sum(1 for v in data[y * w:(y + 1) * w] if v < 200) for y in range(h)]


def rule_row(rows, w, h):
    lim = min(int(150 / 72.0 * DPI), h)
    if lim <= 0:
        return None
    best = max(range(lim), key=lambda y: rows[y])
    return best if rows[best] >= 0.45 * w else None


def footer_block(rows, h):
    dark = [y for y in range(max(0, h - 160), h) if rows[y] > 0]
    if not dark:
        return None
    low = dark[-1]
    top = low
    while top - 1 >= max(0, h - 160) and rows[top - 1] > 0:
        top -= 1
    return (top, low) if sum(rows[top:low + 1]) >= 20 else None


def num_pages(pdf):
    out = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
    m = re.search(r"^Pages:\s+(\d+)", out, re.M)
    return int(m.group(1)) if m else 0


def producer(pdf):
    out = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
    m = re.search(r"^Producer:[ \t]*(.+)$", out, re.M)
    return (m.group(1).strip() if m else "?")[:26]


def sample_pages(pdf, pages=None, lo=0.30, hi=0.85, n=24):
    total = num_pages(pdf)
    if pages:
        return pages
    rng = list(range(max(2, int(total * lo)), min(total, int(total * hi)) + 1))
    step = max(1, len(rng) // n)
    return rng[::step]


def page_geometry(pdf, p, footer_hint=None):
    """单页几何: 横线、正文上下墨迹、页码、边距、行距。

    footer_hint: 全篇页码块上沿（像素行）。用于页码被隐藏的页，避免正文扫描串进页脚。
    """
    words = page_text(pdf, p)
    g = gray_rows(pdf, p)
    if not words or not g:
        return None
    w, h, rows = g
    lines = to_lines(words)
    rule = rule_row(rows, w, h)
    fblk = footer_block(rows, h)
    res = {"page": p, "rule": rule / DPI * 72.0 if rule is not None else None,
           "fblk": (fblk[0] / DPI * 72.0, fblk[1] / DPI * 72.0) if fblk else None,
           "lines": lines, "h": h}
    lo = (rule + 4) if rule is not None else int(80 / 72.0 * DPI)
    cut_top = fblk[0] if fblk else (footer_hint if footer_hint else h)
    hi = int(cut_top) - 4
    body = [y for y in range(lo, max(lo, hi)) if rows[y] > 0]
    res["ink_top"] = body[0] / DPI * 72.0 if body else None
    res["ink_bottom"] = body[-1] / DPI * 72.0 if body else None
    nums = [(y0, y1) for x0, y0, x1, y1, t in words
            if y0 > 750 and re.fullmatch(r"\d{1,4}", t.strip())]
    res["fnum"] = min(nums) if nums else None
    if lines:
        res["head_top"] = min(l["y0"] for l in lines)
    res["head_text_top"] = min(y0 for x0, y0, x1, y1, t in words)
    wide = [l for l in lines if len(re.findall(r"[\u4e00-\u9fff]", l["text"])) >= 12]
    res["left"] = min((l["x0"] for l in wide), default=None)
    return res


def heading_gaps(pdf, pages):
    out = {2: {"a": [], "b": []}, 3: {"a": [], "b": []}}
    for p in pages:
        geo = page_geometry(pdf, p)
        if not geo:
            continue
        rule = geo["rule"]
        cut = rule if rule is not None else 80.0
        lines = geo["lines"]
        fnum = lines[-1]
        if not re.fullmatch(r"\d{1,4}", fnum["text"].strip()):
            continue
        body = [l for l in lines if l is not fnum and l["y0"] >= cut and l["y1"] < fnum["y0"]]
        if len(body) < 10:
            continue
        for i, l in enumerate(body):
            t = l["text"].strip()
            lvl = None
            if re.match(r"^\d+\.\d+\.\d+\s+\S", t) and re.search(r"[\u4e00-\u9fff]", t) and len(t) < 40:
                lvl = 3
            elif re.match(r"^\d+\.\d+\s+\S", t) and re.search(r"[\u4e00-\u9fff]", t) and len(t) < 40:
                lvl = 2
            if not lvl or i == 0 or i + 1 >= len(body):
                continue
            prev, nxt = body[i - 1], body[i + 1]
            if re.match(r"^\d+(\.\d+)*\s+\S", prev["text"].strip()):
                continue
            a, b = l["y0"] - prev["y1"], nxt["y0"] - l["y1"]
            if 0 <= a <= 40:
                out[lvl]["a"].append(a)
            if 0 <= b <= 40:
                out[lvl]["b"].append(b)
    return out


def med(xs):
    return statistics.median(xs) if xs else None


def mm(x, dash="-"):
    return dash if x is None else "%.2f" % (x * PT2MM)


def geometry_for_pages(pdf, pages):
    """两遍扫描：先用页码块位置求出全篇提示值，再逐页定几何。"""
    first = [g for g in (page_geometry(pdf, p) for p in pages) if g]
    tops = [g["fblk"][0] for g in first if g["fblk"]]
    hint = (statistics.median(tops) / 72.0 * DPI) if tops else None
    return [g for g in (page_geometry(pdf, p, footer_hint=hint) for p in pages) if g]


def stable_rule(geos, tol_mm=3.0):
    """只保留页眉横线位置接近全篇中位的页，剔除把表格线误判成页眉线的页。"""
    rs = [g["rule"] for g in geos if g["rule"] is not None]
    if not rs:
        return geos
    ref = statistics.median(rs) * PT2MM
    return [g for g in geos if g["rule"] is not None and abs(g["rule"] * PT2MM - ref) <= tol_mm]


def cmd_lines(args):
    for pdf in args.pdfs:
        pages = sample_pages(pdf, args.pages)
        geos = geometry_for_pages(pdf, pages)
        geos = stable_rule([g for g in geos if g["rule"] is not None and g["ink_top"]
                            and len(g["lines"]) >= 10])
        if not geos:
            print("%s: 无可用正文页" % pdf)
            continue
        gaps = [g["fblk"][0] - g["ink_bottom"] for g in geos if g["fblk"]]
        hg = heading_gaps(pdf, pages)
        print("--- %s  [%s]  采样 %d 页" % (os.path.basename(pdf)[:44], producer(pdf), len(geos)))
        print("    页眉文字上沿=%s | 页眉横线=%s | 横线→正文首行=%s (最紧) / %s (中位)"
              % (mm(med([g["head_text_top"] for g in geos])), mm(med([g["rule"] for g in geos])),
                 mm(min(g["ink_top"] - g["rule"] for g in geos)),
                 mm(med([g["ink_top"] - g["rule"] for g in geos]))))
        print("    正文首行墨迹=%s (最上) | 正文末行→页码=%s (最紧) / %s (中位) | 页码下沿距纸底=%s"
              % (mm(min(g["ink_top"] for g in geos)), mm(min(gaps)), mm(med(gaps)),
                 "%.2f" % (297 - med([g["fnum"][1] * PT2MM for g in geos if g["fnum"]]))
                 if any(g["fnum"] for g in geos) else "-"))
        print("    左边距=%s | 行内空白中位=%s | 三级标题 n=%d 上=%s 下=%s | 二级标题 n=%d 上=%s 下=%s"
              % (mm(med([g["left"] for g in geos if g["left"]]), "-"),
                 mm(med([b["y0"] - a["y1"] for g in geos for a, b in zip(g["lines"], g["lines"][1:])
                         if 0 <= b["y0"] - a["y1"] <= 12])),
                 len(hg[3]["a"]), mm(med(hg[3]["a"])), mm(med(hg[3]["b"])),
                 len(hg[2]["a"]), mm(med(hg[2]["a"])), mm(med(hg[2]["b"]))))


def cmd_ink(args):
    for pdf in args.pdfs:
        pages = sample_pages(pdf, args.pages, n=12)
        tops, bots, gaps, rules = [], [], [], []
        geos = stable_rule([g for g in geometry_for_pages(pdf, pages)
                            if g["rule"] is not None and g["ink_top"] is not None])
        for g in geos:
            p = g["page"]
            tops.append(g["ink_top"])
            bots.append(g["ink_bottom"])
            rules.append(g["rule"])
            if g["fblk"]:
                gaps.append(g["fblk"][0] - g["ink_bottom"])
            if args.rows:
                print("      [p%d] 横线=%.2f 正文上=%.2f 正文下=%.2f 距页码=%s"
                      % (p, g["rule"] * PT2MM, g["ink_top"] * PT2MM, g["ink_bottom"] * PT2MM,
                         mm(g["fblk"][0] - g["ink_bottom"]) if g["fblk"] else "-"))
        if not rules:
            print("%s: 无可用页" % pdf)
            continue
        print("--- %s  采样 %d 页" % (os.path.basename(pdf)[:44], len(rules)))
        print("    页眉横线=%s | 正文最上=%s | 正文最下=%s"
              % (mm(med(rules)), mm(min(tops)), mm(max(bots))))
        print("    横线→正文=%s (最紧) / %s (中位) | 正文→页码=%s (最紧) / %s (中位)"
              % (mm(min(t - r for t, r in zip(tops, rules))),
                 mm(med([t - r for t, r in zip(tops, rules)])),
                 mm(min(gaps)), mm(med(gaps))))


def cmd_headings(args):
    for pdf in args.pdfs:
        hg = heading_gaps(pdf, sample_pages(pdf, args.pages, n=30))
        print("%-46s L2: n=%2d 上=%s 下=%s | L3: n=%2d 上=%s 下=%s mm"
              % (os.path.basename(pdf)[:46], len(hg[2]["a"]), mm(med(hg[2]["a"])), mm(med(hg[2]["b"])),
                 len(hg[3]["a"]), mm(med(hg[3]["a"])), mm(med(hg[3]["b"]))))


def cmd_table(args):
    docs = []
    for name in sorted(os.listdir(args.dir)):
        if name.lower().endswith(".pdf"):
            docs.append(os.path.join(args.dir, name))
    if args.extra:
        docs += args.extra
    print("| 论文 | 引擎 | 页眉文字上沿 | 页眉横线 | 正文首行墨迹 | 正文末行→页码 中位/最紧 | 页码下沿距纸底 | 左边距 | L2 上/下 | L3 上/下 |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    for pdf in docs:
        pages = sample_pages(pdf)
        geos = stable_rule([g for g in geometry_for_pages(pdf, pages)
                            if g["rule"] is not None and g["ink_top"]])
        if not geos:
            continue
        gaps = [g["fblk"][0] - g["ink_bottom"] for g in geos if g["fblk"]]
        hg = heading_gaps(pdf, pages)
        prod = producer(pdf)
        eng = ("Word" if "Word" in prod or "Acrobat" in prod else
               "LaTeX" if "MiKTeX" in prod or "TeX" in prod else prod)
        print("| %s | %s | %s | %s | %s | %s / %s | %s | %s | %s / %s | %s / %s |" % (
            os.path.basename(pdf).replace(".pdf", "")[:18], eng,
            mm(med([g["head_text_top"] for g in geos])), mm(med([g["rule"] for g in geos])),
            mm(min(g["ink_top"] for g in geos)), mm(med(gaps)), mm(min(gaps)) if gaps else "-",
            "%.2f" % (297 - med([g["fnum"][1] * PT2MM for g in geos if g["fnum"]]))
            if any(g["fnum"] for g in geos) else "-",
            mm(med([g["left"] for g in geos if g["left"]])),
            mm(med(hg[2]["a"])), mm(med(hg[2]["b"])), mm(med(hg[3]["a"])), mm(med(hg[3]["b"]))))


def parse_pages(spec):
    pages = []
    for part in spec.split(","):
        if "-" in part:
            lo, hi = part.split("-")
            pages += list(range(int(lo), int(hi) + 1))
        else:
            pages.append(int(part))
    return pages


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("lines", "ink", "headings"):
        s = sub.add_parser(name)
        s.add_argument("pdfs", nargs="+")
        s.add_argument("--pages", type=parse_pages, default=None)
        s.add_argument("--rows", action="store_true")
    t = sub.add_parser("table")
    t.add_argument("--dir", required=True, help="参考学位论文目录")
    t.add_argument("--extra", nargs="*", default=None, help="额外加入对比的 PDF（如 main.pdf）")
    args = ap.parse_args()
    {"lines": cmd_lines, "ink": cmd_ink, "headings": cmd_headings, "table": cmd_table}[args.cmd](args)


if __name__ == "__main__":
    main()
