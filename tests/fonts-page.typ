// 字体自检页回归：确认 thesis.fonts-page() 能渲染，并逐角色列出字体样本，
// 便于在别的机器上目视确认字形是否齐全（缺字会显示为豆腐块）。

#import "../njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  twoside: false,
  info: (
    title: "字体自检回归测试",
    page-degree: "博士学位论文",
  ),
)

#(thesis.preface)[
  #(thesis.fonts-page)()
]
