#import "../../njust-thesis/lib.typ": documentclass
#import "@preview/lilaq:0.6.0" as lq

#let thesis = documentclass(
  info: (
    title: "Lilaq 可选扩展示例",
    page-degree: "博士学位论文",
  ),
  twoside: false,
)

#let xs = (0, 1, 2, 3, 4)

#(thesis.mainmatter)[
  = Lilaq 数据绘图

  `Lilaq` 用于在正文中绘制带坐标轴、图例和数据标记的科学曲线。

  #figure(
    lq.diagram(
      width: 8cm,
      height: 5cm,
      xlabel: [$t$],
      ylabel: [$P(t)$],
      lq.plot(xs, (3, 5, 4, 2, 3), mark: "o", label: [观测]),
      lq.plot(xs, xs.map(x => 2 * calc.cos(x) + 3), label: [模型]),
    ),
    caption: [一个最小 Lilaq 数据图],
  )
]
