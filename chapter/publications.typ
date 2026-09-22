#import "../njust-thesis/style.typ": 字体

#let pub-item(label, body) = pad(
  left: 6pt,
  grid(
    columns: (20pt, 1fr),
    column-gutter: 0pt,
    align: (left, left),
    [#label],
    body,
  ),
)

#h(26pt)#text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular")[攻读博士学位期间发表的论文和出版著作情况：]

#v(3pt)

#pub-item("[1]", [#text(font: 字体.roman, stroke: none, weight: "bold")[ChatGPT & 深度求索]#text(font: 字体.roman, stroke: none, weight: "regular")[ and Klayden.] Dynamics of Supersonic Milk Jet and Time Travel[J]. Journal of Advanced Physics, 2024, 34: 43-62.（SCI 检索：000000000000001）])

#pub-item("[2]", [#text(font: 字体.roman, stroke: none, weight: "bold")[ChatGPT & 深度求索]#text(font: 字体.roman, stroke: none, weight: "regular")[ and Klayden.] Quantum Effects in Supersonic Milk Jet and Time Travel: A Probabilistic Approach[J]. International Journal of Theoretical Physics, 2024, 12: 123-145.（SCI 检索：000000000000002）])

#v(1cm)

#h(26pt)#text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular")[攻读博士学位期间参加的科学研究情况：]

#v(3pt)

#pub-item("[1]", [国家自然科学基金项目：基于超音速牛奶喷射与时间旅行的概率动力学的干扰抑制方法研究，62493846])

#pub-item("[2]", [国家自然科学基金项目：超音速牛奶喷射和时间旅行中的量子效应的概率方法，62471764])
