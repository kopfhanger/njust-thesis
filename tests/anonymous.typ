// 匿名送审回归：同一份内容分别以 anonymous = true / false 编译，
// 用来验证“隐去导师与作者信息、且不渲染致谢”真的生效，而不是断言恒真。
//
//   tinymist compile --font-path font --input anonymous=true  tests/anonymous.typ /tmp/anon.pdf
//   tinymist compile --font-path font --input anonymous=false tests/anonymous.typ /tmp/real.pdf
//
// 学校《博士、硕士学位论文撰写格式》第 7 节：匿名送审版必须隐去封面、封二和
// 致谢中所有导师与作者信息；本模板在匿名模式下整页不渲染致谢。

#import "../njust-thesis/lib.typ": documentclass

#let anonymous = sys.inputs.at("anonymous", default: "false") == "true"

#let thesis = documentclass(
  anonymous: anonymous,
  twoside: false,
  info: (
    title: "匿名送审回归测试",
    page-degree: "博士学位论文",
    author: "王一珉",
    advisor: "杨国来",
    advisor-title: "教授",
    english-author: "Wang Yimin",
    english-advisor: "Yang Guolai",
  ),
  abstract-body: [摘要正文。],
  abstract-en-body: [(Abstract body.)],
)

#(thesis.cover)()

#(thesis.preface)[
  #(thesis.abstract)()
  #(thesis.outline)("目  录", depth: 2)
]

#(thesis.mainmatter)[
  = 绪论
  正文。
]

#(thesis.backmatter)[
  #(thesis.thanks)[
    致谢正文标记：感谢杨国来教授与王一珉同学。
  ]
]
