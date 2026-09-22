#import "../../njust-thesis/lib.typ": documentclass
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let thesis = documentclass(
  info: (
    title: "Fletcher 可选扩展示例",
    page-degree: "博士学位论文",
  ),
  twoside: false,
)

#(thesis.mainmatter)[
  = Fletcher 箭头图

  Fletcher 适合绘制带有方向关系的流程图、状态图和数学示意图。箭头与节点样式只在本示例中生效。

  #figure(
    fletcher.diagram(
      node-stroke: 0.8pt,
      node-fill: luma(96%),
      spacing: 2.2em,
      fletcher.node((0, 0), [输入], corner-radius: 2pt),
      fletcher.edge("-|>"),
      fletcher.node((0, 1), [处理], corner-radius: 2pt),
      fletcher.edge("-|>"),
      fletcher.node((0, 2), [输出], corner-radius: 2pt),
    ),
    caption: [一个最小 Fletcher 流程图],
  )
]
