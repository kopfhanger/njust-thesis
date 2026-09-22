#import "../njust-thesis/style.typ": 字体

#table(
  columns: (4fr, 7fr, 5fr),
  align: (left, left, right),
  // 对应 LaTeX nomenclatureitem：三列从正文左边界起排版，末列贴齐右边界。
  inset: (x: 0pt, y: 3pt),
  stroke: none,
  // LaTeX 的 \vspace{6pt} 和正常行距共同形成表头与首行之间的空隙。
  row-gutter: 4.4pt,
  [#text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "英文缩写")],
  [#text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "英文全称")],
  [#text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "中文全称")],
  [#v(6pt)SMJ], [#v(6pt)supersonic milk jetting], [#v(6pt)超音速牛奶喷射],
  [TT], [time travel], [时间旅行],
  [PBD], [probabilistic dynamics], [概率动力学],
  [STN], [spatio-temporal navigation], [时空导航],
  [LVR], [logistic variable regression], [逻辑变量回归],
  [DHC], [differential heterogeneity curvature], [差分异质曲率],
)
