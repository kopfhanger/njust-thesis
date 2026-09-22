#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""遍历式分页不变量校验（NJUST Typst 学位论文模板）。

对给定 PDF 的 **每一页** 检查页眉/页码不变量，而不是抽查固定页码——
抽查窗口正是上一轮 P0 回归漏网的原因。校验规则：

1. 封面类页面（外封面/书脊/封二/英文封二/声明及其插入页）：不得有页眉或页码；
2. 空白插入页（本页正文带内没有任何墨迹）：不得有页眉或页码；
3. 有正文的页面：必须有页码；
4. 前置页面（摘要…表目录）：页码为罗马数字，序号 = 当前页 - 封面页数；
   奇数页必须有页眉，偶数页不得有页眉（对应 LaTeX \\fancyhead[LO,RO]）；
5. 正文及其后（mainmatter/backmatter）：必须有页眉，
   页码 = 当前页 - 封面页数 - 前置页数；
6. 总页数可选用 --expect-pages 固定，防止"修分页反而多出一页"。

"有没有正文"由 **渲染墨迹** 判定（pdftoppm 灰度渲染 + 正文带像素统计），
因此文字、位图、纯矢量图形一视同仁；页眉页脚的文字与页码仍由 pdftotext 读取。

脚本同时构建对抗性 fixture（名称即覆盖范围，不再维护类别数量）：
  case-a-chapter-ends-on-even-page  章节结束在偶数页：不需要插空白页，前一页仍是正文页；
  case-b-chapter-ends-on-odd-page   章节结束在奇数页：只有插入页没有页眉页码；
  case-c-chapter-fills-page         章节内容正好填满整页：起点标记可能被推到插入页；
  case-d-image-only-page            整页只有位图：不得因为没有文字而被判成空白页；
  case-e-vector-only-page           整页只有纯矢量图形：墨迹判定必须覆盖矢量内容；
  case-f-single-sided               twoside: false：单面模式不得插入空白页。

用法：
  tests/check-pagination.py                       # 默认：构建 fixture + 校验 main.pdf
  tests/check-pagination.py -v                    # 额外输出每页墨迹像素数
  tests/check-pagination.py --pdf x.pdf --cover 8 --front 12 --expect-pages 73
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FONT_PATH = REPO_ROOT / "font"

# 文本行分区（单位 pt）。页眉在 y≈59，正文首行在 y≈89，页脚页码在 y≈777。
HEADER_MAX_Y = 75.0
BODY_MIN_Y = 75.0
BODY_MAX_Y = 770.0
FOOTER_MIN_Y = 770.0

# ---- 正文墨迹判定 ----------------------------------------------------------
# 正文带 [75pt, 770pt] 是模板几何耦合值，关联 njust-thesis/style.typ 的
# `text-margin`（top 32mm / bottom 25.5mm）与页眉的 `header-offset`：
#   * 页眉文字实测在 y≈59–68pt，页眉横线在 y≈69pt；
#   * 页脚页码在 y≈777–786pt（距纸底 20mm，与 11 篇 Word 参考论文的 17.55–23.68mm 一致）；
#   * 版心首行墨迹从 y≈88.6pt 起，最靠下的正文行 yMin ≈ 758pt。
# 因此 75pt 以下、770pt 以上只剩版心内容：即使某张空白页被错误地加上页眉
# 横线，也不会被算成"有正文"，从而避免把"空白页带 chrome"静默判成正常正文页。
# 改动 style.typ 的页边距或页眉偏移后，这里必须同步复核。
BODY_BAND_TOP_PT = 75.0
BODY_BAND_BOTTOM_PT = 770.0
RENDER_DPI = 100
INK_GRAY_THRESHOLD = 250
MIN_INK_PIXELS = 20

_INK_TABLE = bytes(1 if value < INK_GRAY_THRESHOLD else 0 for value in range(256))

ROMAN_TABLE = (
    (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
    (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
    (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
)


def roman(number: int) -> str:
    out = ""
    for value, glyph in ROMAN_TABLE:
        while number >= value:
            out += glyph
            number -= value
    return out


def find_compiler() -> str:
    compiler = os.environ.get("TYPST_BIN") or shutil.which("typst") or shutil.which("tinymist")
    if not compiler:
        sys.exit("check-pagination: 找不到 Typst/Tinymist 编译器（可用 TYPST_BIN 指定）")
    return compiler


def pdf_page_count(pdf: Path) -> int:
    out = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True, check=True).stdout
    match = re.search(r"^Pages:\s+(\d+)", out, re.M)
    if not match:
        sys.exit(f"check-pagination: 无法读取 {pdf} 的页数")
    return int(match.group(1))


LINE_RE = re.compile(
    r'<line xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</line>',
    re.S,
)
WORD_RE = re.compile(r"<word[^>]*>([^<]*)</word>")


def page_zones(pdf: Path, page: int):
    """返回 (页眉文本列表, 正文文本列表, 页脚文本列表)。"""
    out = subprocess.run(
        ["pdftotext", "-bbox-layout", "-f", str(page), "-l", str(page), str(pdf), "-"],
        capture_output=True, text=True, check=True,
    ).stdout
    header, body, footer = [], [], []
    for match in LINE_RE.finditer(out):
        y_min = float(match.group(2))
        text = "".join(WORD_RE.findall(match.group(5))).strip()
        if not text:
            continue
        if y_min < HEADER_MAX_Y:
            header.append(text)
        elif y_min > FOOTER_MIN_Y:
            footer.append(text)
        elif BODY_MIN_Y <= y_min <= BODY_MAX_Y:
            body.append(text)
    return header, body, footer


def count_ink(pgm: Path) -> int:
    """统计单页 PGM 在正文带内的墨迹像素数。"""
    data = pgm.read_bytes()
    match = re.match(rb"P5\s+(\d+)\s+(\d+)\s+(\d+)\s", data)
    if not match:
        sys.exit(f"check-pagination: 无法解析渲染结果 {pgm}")
    width, height = int(match.group(1)), int(match.group(2))
    pixels = data[match.end():]
    scale = RENDER_DPI / 72.0
    top = max(0, int(BODY_BAND_TOP_PT * scale))
    bottom = min(int(BODY_BAND_BOTTOM_PT * scale), height)
    band = pixels[top * width:bottom * width]
    return band.translate(_INK_TABLE).count(b"\x01")


def ink_pages(pdf: Path) -> dict:
    """整本渲染一次，返回 {页号: 正文带墨迹像素数}。

    用渲染墨迹代替“文字或位图对象”判定：文字、位图、纯矢量图形都会留下墨迹，
    语义就是“这一页是否真的印了东西”。
    """
    pdftoppm = shutil.which("pdftoppm")
    if not pdftoppm:
        sys.exit("check-pagination: 找不到 pdftoppm（Poppler 工具）")
    with tempfile.TemporaryDirectory(prefix="njust-ink.") as tmp:
        prefix = os.path.join(tmp, "page")
        subprocess.run(
            [pdftoppm, "-gray", "-r", str(RENDER_DPI), str(pdf), prefix],
            capture_output=True, text=True, check=True,
        )
        counts = {}
        for pgm in sorted(Path(tmp).glob("page-*.pgm")):
            counts[int(pgm.stem.split("-")[-1])] = count_ink(pgm)
        return counts


def check_pdf(pdf: Path, cover_pages: int, front_pages: int, label: str,
              expect_pages=None, verbose=False):
    """按页校验不变量，返回问题列表。"""
    total = pdf_page_count(pdf)
    main_start = cover_pages + front_pages + 1
    problems = []
    ink_by_page = ink_pages(pdf)

    if expect_pages is not None and total != expect_pages:
        problems.append(f"总页数为 {total}，期望 {expect_pages}")

    for page in range(1, total + 1):
        header, body, footer = page_zones(pdf, page)
        body_ink = ink_by_page.get(page, 0)
        has_body = body_ink >= MIN_INK_PIXELS
        has_header, has_footer = bool(header), bool(footer)
        footer_text = "".join(footer).strip()
        where = f"p{page}"

        if verbose:
            kind = "封面" if page <= cover_pages else ("空白" if not has_body else "正文")
            print(f"    {where}: 墨迹 {body_ink:>7}px  页面类型={kind}  "
                  f"页眉={'有' if has_header else '无'} 页码={footer_text or '-'}")

        if page <= cover_pages:
            if has_header or has_footer:
                problems.append(
                    f"{where}: 封面类页面不得有页眉页码，实际 header={header} footer={footer}")
            continue

        if not has_body:
            if has_header or has_footer:
                problems.append(
                    f"{where}: 空白插入页不得有页眉页码，实际 header={header} footer={footer}")
            continue

        if not has_footer:
            problems.append(f"{where}: 有正文却缺少页码")

        if page < main_start:
            expected = roman(page - cover_pages)
            if has_footer and footer_text != expected:
                problems.append(f"{where}: 前置页码应为 {expected}，实际 {footer_text!r}")
            if page % 2 == 1:
                if not has_header:
                    problems.append(f"{where}: 前置奇数页缺少页眉")
            elif has_header:
                problems.append(f"{where}: 前置偶数页不得有页眉，实际 header={header}")
        else:
            expected = str(page - cover_pages - front_pages)
            if has_footer and footer_text != expected:
                problems.append(f"{where}: 正文页码应为 {expected}，实际 {footer_text!r}")
            if not has_header:
                problems.append(f"{where}: 正文页缺少页眉")

    return problems


FIXTURE_MAIN = """#import "njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  info: (
    title: "分页不变量校验",
    author: "校验脚本",
    advisor: "校验脚本",
  ),
  twoside: {twoside},
)

#(thesis.mainmatter)[
{includes}
]
"""

# A. 第一章结束在偶数页：pagebreak(to: "odd") 的目的地与前一页相邻，
#    模板不得把"前一页"当成插入的空白页。
FIXTURE_EVEN_END = {
    "slug": "case-a-chapter-ends-on-even-page",
    "name": "章节结束在偶数页（不需要插空白页）",
    "expect_pages": 3,
    "twoside": True,
    "chapters": {
        "ch1": "= 第一章\nCH1-PAGE1 第一章第一页正文。\n#pagebreak()\n"
               "CH1-LASTPAGE 第一章最后一页，结束在偶数页，后面紧跟第二章。\n",
        "ch2": "= 第二章\nCH2-PAGE1 第二章正文。\n",
    },
}

# B. 第一章结束在奇数页：必须插入一张空白页，且只有插入页没有页眉页码。
FIXTURE_ODD_END = {
    "slug": "case-b-chapter-ends-on-odd-page",
    "name": "章节结束在奇数页（需要插空白页）",
    "expect_pages": 5,
    "twoside": True,
    "chapters": {
        "ch1": "= 第一章\nCH1-PAGE1。\n#pagebreak()\nCH1-PAGE2。\n#pagebreak()\n"
               "CH1-LASTPAGE 第一章最后一页，结束在奇数页。\n",
        "ch2": "= 第二章\nCH2-PAGE1 第二章正文。\n",
    },
}

# C. 上一章内容正好填满奇数页：分页起点标记可能被推到下一页，
#    此时该页是插入的空白页，必须没有页眉页码。
FIXTURE_FULL_PAGE = {
    "slug": "case-c-chapter-fills-page",
    "name": "章节内容正好填满整页",
    "expect_pages": 3,
    "twoside": True,
    "chapters": {
        "ch1": "= 第一章\n第一章正文，用于填满整页。\n#v(1fr)\n",
        "ch2": "= 第二章\nCH2-PAGE1 第二章正文。\n",
    },
}

# D. 正文页只有位图时，不能被"没有正文文字"误判成空白插入页。
FIXTURE_IMAGE_ONLY = {
    "slug": "case-d-image-only-page",
    "name": "整页位图正文",
    "expect_pages": 2,
    "twoside": True,
    "chapters": {
        "ch1": '#image("../fig/logo/njust.svg", width: 8cm)\n'
               "#pagebreak()\n",
        "ch2": "位图页之后的正文，用于确认分页后的页眉页码仍然正常。\n",
    },
}

# E. 整页只有纯矢量图形：裸 CeTZ 画布，既没有题注文字也没有位图对象，
#    旧版"文字或位图对象"判定会把它误判成空白插入页。刻意保留一条 0.5pt
#    细线，用于锁定渲染 DPI 与墨迹阈值。
FIXTURE_VECTOR_ONLY = {
    "slug": "case-e-vector-only-page",
    "name": "整页纯矢量图形",
    "expect_pages": 2,
    "twoside": True,
    "chapters": {
        "ch1": '#import "@preview/cetz:0.5.2": canvas, draw\n'
               "#canvas({ import draw: *; rect((0, 0), (6, 4), stroke: 1pt); "
               "line((0, 0), (6, 4), stroke: .5pt) })\n"
               "#pagebreak()\n",
        "ch2": "矢量图页之后的正文，用于确认该页仍保留页眉页码。\n",
    },
}

# F. 单面模式不执行奇数页对齐，不应为章节边界制造空白页。
FIXTURE_SINGLE_SIDED = {
    "slug": "case-f-single-sided",
    "name": "单面模式章节边界",
    "expect_pages": 2,
    "twoside": False,
    "chapters": {
        "ch1": "= 第一章\n单面模式第一章正文。\n#pagebreak()\n",
        "ch2": "= 第二章\n单面模式第二章正文。\n",
    },
}

FIXTURES = (
    FIXTURE_EVEN_END,
    FIXTURE_ODD_END,
    FIXTURE_FULL_PAGE,
    FIXTURE_IMAGE_ONLY,
    FIXTURE_VECTOR_ONLY,
    FIXTURE_SINGLE_SIDED,
)


def run_compile(compiler: str, source: Path, out: Path, cwd: Path = None) -> None:
    """编译并在失败时把编译器诊断原样抛出，便于定位 fixture 问题。

    cwd 决定 Tinymist 认定的项目根：入口必须在根内，否则会以
    "entry path must be a valid virtual path: Escapes" 中止；而仓库内
    的 fixture 使用 `../njust-thesis/...` 导入，又必须以仓库根为根。
    """
    if cwd is None:
        source_abs = source.resolve()
        cwd = REPO_ROOT if REPO_ROOT in source_abs.parents else source.parent
    proc = subprocess.run(
        [compiler, "compile", "--font-path", str(FONT_PATH), str(source), str(out)],
        capture_output=True, text=True, cwd=str(cwd),
    )
    if proc.returncode != 0:
        sys.exit(
            f"check-pagination: 编译失败 ({source})\n"
            f"--- stdout ---\n{proc.stdout}\n--- stderr ---\n{proc.stderr}"
        )


def build_fixture(tmp: Path, compiler: str, fixture: dict) -> Path:
    """把 fixture 写到临时目录并编译（模板目录用软链，避免复制字体）。"""
    root = tmp / fixture["slug"]
    (root / "chapter").mkdir(parents=True, exist_ok=True)
    (root / "njust-thesis").symlink_to(REPO_ROOT / "njust-thesis", target_is_directory=True)
    (root / "fig").symlink_to(REPO_ROOT / "fig", target_is_directory=True)
    includes = []
    for name, body in fixture["chapters"].items():
        (root / "chapter" / f"{name}.typ").write_text(body, encoding="utf-8")
        includes.append(f'#include "chapter/{name}.typ"')
    (root / "main.typ").write_text(
        FIXTURE_MAIN.format(
            includes="\n".join(includes),
            twoside=str(fixture.get("twoside", True)).lower(),
        ),
        encoding="utf-8",
    )
    out = root / "main.pdf"
    run_compile(compiler, root / "main.typ", out)
    return out


def compile_existing(tmp: Path, compiler: str, source: Path) -> Path:
    out = tmp / (source.stem + ".pdf")
    run_compile(compiler, source, out)
    return out


def report(label: str, problems) -> int:
    if problems:
        print(f"  [-] {label}: {len(problems)} 处违反不变量")
        for item in problems:
            print(f"        {item}")
        return len(problems)
    print(f"  [+] {label}: 全部页面满足不变量")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="遍历式分页不变量校验")
    parser.add_argument("--pdf", type=Path, help="只校验指定 PDF")
    parser.add_argument("--cover", type=int, default=0, help="封面类页面数")
    parser.add_argument("--front", type=int, default=0, help="前置（罗马页码）页面数")
    parser.add_argument("--expect-pages", type=int, default=None, help="期望总页数")
    parser.add_argument("--label", default=None, help="报告用的名称")
    parser.add_argument("-v", "--verbose", action="store_true", help="逐页输出墨迹像素数")
    args = parser.parse_args()

    if args.pdf:
        problems = check_pdf(args.pdf, args.cover, args.front,
                             args.label or str(args.pdf), args.expect_pages, args.verbose)
        return 1 if report(args.label or str(args.pdf), problems) else 0

    compiler = find_compiler()
    failures = 0
    tmp = Path(tempfile.mkdtemp(prefix="njust-pagination."))
    try:
        print("分页不变量校验（逐页遍历，正文由渲染墨迹判定）")
        for fixture in FIXTURES:
            pdf = build_fixture(tmp, compiler, fixture)
            failures += report(fixture["name"], check_pdf(
                pdf, cover_pages=0, front_pages=0, label=fixture["name"],
                expect_pages=fixture["expect_pages"], verbose=args.verbose))

        pagination_src = REPO_ROOT / "tests" / "regression-pagination.typ"
        pdf = compile_existing(tmp, compiler, pagination_src)
        failures += report("长段落 / 跨页表格续页", check_pdf(
            pdf, cover_pages=0, front_pages=0, label="长段落 / 跨页表格续页",
            # 表格内文字由 9.5pt 改为学校规定的五号（10.5pt）后该 fixture 多出一页。
            expect_pages=7, verbose=args.verbose))

        main_pdf = REPO_ROOT / "main.pdf"
        if main_pdf.exists():
            failures += report("默认样例 main.pdf", check_pdf(
                main_pdf, cover_pages=8, front_pages=12, label="默认样例 main.pdf",
                expect_pages=73, verbose=args.verbose))
        else:
            print("  [!] 跳过 main.pdf（不存在，先运行 just compile）")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    if failures:
        print(f"\n分页不变量校验失败：共 {failures} 处")
        return 1
    print("\n分页不变量校验通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
