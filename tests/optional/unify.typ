#import "../../njust-thesis/lib.typ": documentclass
#import "@preview/unify:0.8.1": num, qty, qtyrange

#let thesis = documentclass(
  info: (
    title: "unify 可选扩展示例",
    page-degree: "博士学位论文",
  ),
  twoside: false,
)

#(thesis.mainmatter)[
  = unify 科学数字与单位

  `unify` 用于统一科学数字、误差、单位和范围的排版。示例中的速度为 #qty("340", "m/s")，测量值为 #num("1.20+-0.03")，参数范围为 #qtyrange("2.0", "3.5", "mm")。
]
