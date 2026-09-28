#import "../njust-thesis/lib.typ": documentclass

// 协同导师（副导师）封面回归：外封面、中文封二与英文封二都要出现协导姓名与职称，
// 且导师行与协同导师行之间保持固定间距，不能重叠或压到后续字段。
#let thesis = documentclass(
  info: (
    title: "含协同导师的封面回归测试",
    author: "王一珉",
    advisor: "杨国来",
    advisor-title: "教授",
    coadvisor: "王晓锋",
    coadvisor-title: "研究员",
    degree-cat: "工学博士",
    major: "机械工程",
    interest: "动力学与控制",
    submit-date: "2024年11月",
    incover-date: "2024年11月",
    english-advisor: "Yang Guolai",
    english-coadvisor: "Wang Xiaofeng",
    english-institute: "School of Mechanical Engineering",
    english-major: "Mechanical Engineering",
    english-date: "November 2024",
  ),
  twoside: false,
)

#(thesis.cover)()
