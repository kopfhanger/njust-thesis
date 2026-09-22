#import "../../njust-thesis/lib.typ": documentclass
#import "@preview/lovelace:0.3.1": pseudocode-list

#let thesis = documentclass(
  info: (
    title: "Lovelace 可选扩展示例",
    page-degree: "博士学位论文",
  ),
  twoside: false,
)

#(thesis.mainmatter)[
  = Lovelace 算法伪代码

  `Lovelace` 将嵌套列表转换为带缩进的伪代码，并可在论文中保留算法步骤的结构。

  #figure(
    pseudocode-list(numbered: true)[
      + 初始化状态 $bold(x)_0$
      + *for* $k = 1, 2, ..., n$
        + 预测并更新状态
      + *end*
      + 返回状态序列
    ],
    caption: [一个最小 Lovelace 算法示例],
  )
]
