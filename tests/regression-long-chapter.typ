// Structural regression fixture: the first chapter spans several pages and
// intentionally contains no manual #h(2em) paragraph indentation.
#import "../njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  info: (
    title: "跨页章节回归测试",
    author: "测试作者",
    advisor: "测试导师",
  ),
  twoside: true,
)

#(thesis.mainmatter)[
= 第一章 跨页章节

#for i in range(34) {
  [这是用于验证真实论文接入行为的跨页段落。模板应自动提供正文首行缩进，并在章节之间插入不带页眉页码的偶数空白页。当前段落编号为 #i。]
  parbreak()
}

= 第二章 新章节

这是第二章的第一段，用于确认新章节从奇数页开始，并且章节后的正文仍然拥有统一的首行缩进和页眉页脚。
]
