#import "../../njust-thesis/lib.typ": documentclass
#import "@preview/physica:0.9.8": curl, grad, tensor, pdv

#let thesis = documentclass(
  info: (
    title: "Physica 可选扩展示例",
    page-degree: "博士学位论文",
  ),
  twoside: false,
)

#(thesis.mainmatter)[
  = Physica 物理记号

  Physica 提供向量、梯度、张量、偏导数和 Dirac 记号等常见物理数学表达式：

  #align(center)[$ curl (grad f), quad tensor(T, -mu, +nu), quad pdv(f, x, y, [1, 2]) $]
]
