#import "../njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  info: (
    title: "引用回归测试",
    author: "测试作者",
    advisor: "测试导师",
  ),
)

#(thesis.mainmatter)[
= 引用测试

正文引用 @smith2024 和 @doe2024；再次引用 @smith2024。
]

#(thesis.backmatter)[
  #(thesis.bibliography)("ref/ch1.bib")
]
