// Adversarial pagination regression fixture. The first paragraph is one
// element spanning pages; the table is a single cross-page table.
#import "../njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  info: (
    title: "分页状态回归测试",
    author: "测试作者",
    advisor: "测试导师",
  ),
  twoside: true,
)

#let table-rows = range(72).map(i => (
  [第 #i 行参数说明],
  [这是跨页表格中的连续内容，用于验证续页仍保留页面 chrome。],
))

#(thesis.mainmatter)[
= 第一章 长段落与长表格

这是一个不包含段落断点的连续长段落，用于模拟真实论文中自然跨页的正文内容。#lorem(1450)

== 跨页三线表

表格前的正文用于说明表格来源和实验条件。下面的表格故意跨越多个页面，检查表格续页不会因为没有新的段落或图表起点而被判定为空白页。

#table(
  columns: (1.1fr, 3fr),
  align: (left, left),
  stroke: none,
  table.hline(stroke: 1pt),
  [参数], [说明],
  table.hline(stroke: .5pt),
  ..table-rows.flatten(),
  table.hline(stroke: 1pt),
)

表格之后的正文用于确认跨页对象结束后页面流仍然正常。
]
