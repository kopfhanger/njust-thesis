// ============================================================
// NJUST Thesis — 样式与字号定义
// ============================================================

#let 字号 = (
  初号: 42pt,
  小初: 36pt,
  一号: 26pt,
  小一: 24pt,
  二号: 22pt,
  小二: 18pt,
  三号: 16pt,
  小三: 15pt,
  四号: 14pt,
  小四: 12pt,
  // 正文公共基准；12.07pt 是按 LaTeX 基准字面高度校准的 Typst 值，
  // 不应在章节文件中重新定义正文大小。
  正文: 12.07pt,
  五号: 10.5pt,
  小五: 9pt,
)

#let page-paper = "a4"

// 封面、书脊等固定版式页的页边距，用学校标称值（上空 30mm、下空 24mm、左右 25mm）。
#let page-margin = (
  top: 30mm,
  bottom: 24mm,
  // 学校规范与王一珉论文实测均为左右各 25mm（版心宽度同为 160mm）。
  // njusttt.cls 用 1in 左边距 + 160mm 正文宽，右边界因此略小于 1in；
  // 这里按 25mm 对齐，只把正文块整体左移约 0.4mm，不改变版心宽度。
  left: 25mm,
  right: 25mm,
)

// 摘要、目录、正文、后文等文字页的版心。
//
// 学校规范的“上空 30mm、下空 24mm”是 Word 页边距设置值，而 Word 用固定行距排版时
// 首行墨迹落在纸顶 29.97–31.50mm（11 篇南理工 Word/WPS 学位论文实测），正文末行到
// 页码最紧仍留 1.27–4.83mm。Typst 的首行墨迹落在版心顶上方约 0.3–1.0mm、末行墨迹可
// 顶到版心底上方约 0.3mm，照抄 30/24mm 会让正文上下都比全部参考论文更贴近页眉线与
// 页码（实测首行 28.96mm、末行 272.03mm、到页码只剩 1.78mm）。按墨迹与 Word 版式重合
// 标定为 32/25.5mm 后，首行墨迹 31.24mm、末行墨迹最高 271.78mm、最紧空白 2.03mm。
// 逐篇数据见 docs/njust-phd-format-baseline.md §3.1，复现见 tools/reference-geometry.py。
#let text-margin = (
  top: 32mm,
  bottom: 25.5mm,
  left: page-margin.left,
  right: page-margin.right,
)

// 页眉文字与页码的垂直偏移：把二者钉回学校规范的距纸边位置（页眉 20mm、页脚 20mm）。
//
// Typst 把页眉页脚挂在版心边上：三点标定（版心 top = 30/32/34mm）显示页眉文字上沿
// 随之为 20.74/22.14/23.54mm，即版心每上下移动 2mm，页眉与页码同向移动约 1.4mm。
// 文字页版心由 30/24mm 改为 32/25.5mm 后页眉下移 1.4mm、页码上移 1.1mm，用 move 抵消：
// 页眉文字上沿回到距纸顶 20.73mm、页眉横线 24.38mm、页码下沿距纸底 20.01mm。
#let header-offset = 6pt
#let footer-offset = -14.3pt

#let 字体 = (
  // 混排文本先使用 Times New Roman，再回退到本地 SimSun；这样算法框、
  // 行内代码等显式指定 roman 的中文不会静默落到宿主机的 CJK 字体。
  宋体: ("Times New Roman", "SimSun"),
  黑体: ("Times New Roman", "SimHei"),
  楷体: ("Times New Roman", "KaiTi"),
  魏碑: ("Times New Roman", "FZWeiBei-S03S"),
  roman: ("Times New Roman", "SimSun"),
  // 原始 LaTeX 同时使用 \bfseries 与 AutoFakeBold=3；0.45pt 能在 Typst
  // 中复现其 CJK 粗体的视觉重量，同时不改变字面尺寸。
  粗体描边: 0.45pt,
)
