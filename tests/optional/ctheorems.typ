#import "../../njust-thesis/lib.typ": documentclass
#import "@preview/ctheorems:2.0.0": *
#import thm-themes.ams: *

#let thesis = documentclass(
  info: (
    title: "ctheorems 可选扩展示例",
    page-degree: "博士学位论文",
  ),
  twoside: false,
)

#show: thm-rules
#let definition = definition.with(supplement: "定义")
#let theorem = theorem.with(supplement: "定理")
#let proof = proof.with(supplement: "证明")

#(thesis.mainmatter)[
  = 定理环境

  ctheorems 可为数学论文提供带编号、可引用的定义、定理、命题和证明环境。它的 show 规则只存在于本测试文件。

  #definition[连续性][函数在点 $x_0$ 连续，当且仅当对任意正数 $epsilon$，存在正数 $delta$。]

  #theorem[示例定理][若 $a = b$ 且 $b = c$，则 $a = c$。]

  #proof[由等式的传递性立即得到结论。]
]
