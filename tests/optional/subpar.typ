#import "../../njust-thesis/lib.typ": documentclass, chapter-figure-numbering
#import "@preview/subpar:0.2.2"
#import "@preview/lilaq:0.6.0" as lq

#let thesis = documentclass(
  info: (
    title: "subpar 可选扩展示例",
    page-degree: "博士学位论文",
  ),
  twoside: false,
)

#let xs = (0, 1, 2, 3)

#(thesis.mainmatter)[
  = subpar 子图

  `subpar` 为同一数据对象提供父图和子图题注。

  #subpar.grid(
    figure(lq.diagram(width: 7cm, height: 3cm, lq.plot(xs, (1, 2, 1.5, 2.5))), caption: [折线图]), <subpar-a>,
    figure(lq.diagram(width: 7cm, height: 3cm, lq.scatter(xs, (1, 2, 1.5, 2.5))), caption: [散点图]), <subpar-b>,
    columns: (1fr, 1fr),
    numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
    supplement: [图],
    caption: [subpar 多子图示例],
    label: <subpar-parent>,
  )
]
