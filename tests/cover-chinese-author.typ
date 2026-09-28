#import "../njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  info: (
    title: "基于中文作者名的封面回归测试",
    author: "王一珉",
    advisor: "杨国来",
    advisor-title: "教授",
    degree-cat: "工学博士",
    major: "机械工程",
    interest: "动力学与控制",
    submit-date: "2024年11月",
    incover-date: "2024年11月",
  ),
  twoside: false,
)

#(thesis.cover)()
