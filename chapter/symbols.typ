#import "../njust-thesis/style.typ": 字体

#table(
  // LaTeX 的 nomenclatureitem 第二列固定从正文左边界 + 0.25\textwidth 起笔。
  columns: (113.4pt, 1fr),
  align: (left, left),
  inset: (x: 0pt, y: 3pt),
  stroke: none,
  row-gutter: 3pt,
  [#text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "符号")],
  [#text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "含义")],
  [#v(0pt)], [],
  [$op("log")(dot)$], [对数变换],
  [$op("argmin")(dot)$], [取最小值的位置],
)
