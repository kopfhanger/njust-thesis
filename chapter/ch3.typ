= 时间旅行的概率动力学研究

#import "../njust-thesis/lib.typ": chapter-figure-numbering, official-example, subfigure-caption
#import "@preview/ctheorems:2.0.0": *
#import "@preview/subpar:0.2.2"
#import thm-themes.ams: *
#import "../njust-thesis/style.typ": 字体

#show: thm-rules

// 王一珉论文中的定义/定理采用正文式排版：无边框、无底色，标题加粗后换行，
// 正文使用宋体常规字重；定理编号只随章重置，不把 3.1.2 的小节层级带入编号。
#let thesis-thm-fmt(
  thm,
  block-args: (:),
  name-fmt: x => [（#x）],
  title-fmt: x => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", x),
  body-fmt: x => text(font: 字体.宋体, stroke: none, weight: "regular", x),
  separator: [。],
) = {
  let name = if thm.name == none { [] } else { name-fmt(thm.name) }
  let title = thm.supplement
  if thm.number != none {
    title += [ #thm.number]
  }
  title = title-fmt(title)
  block(
    width: 100%,
    ..block-args,
    [
      #title#name#separator
      #linebreak()
      #body-fmt(thm.body)
    ],
  )
}

#let definition = definition.with(
  supplement: "定义",
  base-level: 1,
  fmt: thesis-thm-fmt,
)
#let theorem = theorem.with(
  supplement: "定理",
  base-level: 1,
  fmt: thesis-thm-fmt,
)
#let proof = proof.with(
  supplement: "证明",
  fmt: thesis-thm-fmt,
)

本章内容是模板的示例占位，用于验证第三级标题能够像第一章一样进入目录。真实论文中可在此替换为理论基础、模型建立和验证结果。

== 理论基础

=== 相对论框架

示例内容从参考系、时间参数和状态转移三个方面说明模型的基本假设，并保留正文标题和段落格式供排版检查。

=== 量子效应

若研究涉及离散状态或不确定性，可在本节说明状态空间、转移概率以及观测量的定义。为了展示中文论文中的定理环境，本章使用 ctheorems 提供编号、证明和交叉引用。

#definition[可逆状态转移][
  若状态转移算子 $A$ 满足存在 $A^(-1)$，则称该离散模型在给定状态空间上可逆。
] <def:reversible>

#theorem[状态转移的可逆性][
  若 $A$ 可逆且 $bold(x)_(k+1) = A bold(x)_k$，则由终态 $bold(x)_(k+1)$ 可以唯一恢复 $bold(x)_k$。
] <thm:reversible>

#proof[
  左乘 $A^(-1)$ 得 $bold(x)_k = A^(-1) bold(x)_(k+1)$，因此恢复结果唯一。
]

上述定义和定理的编号会随章节自动重置；真实论文可继续增加引理、推论和定理证明，而不需要手工维护编号。

为了把抽象的状态转移关系具体化，下面分别给出 Fletcher 的几类关系图。交换图适合表达两个映射的兼容性，范畴图适合表达对象和态射，状态机适合表达离散演化过程，树图则适合表达层级化的状态分解。它们都服务于本章的理论叙述，因此合并为一个子图组（图 3.1）：总题注说明共同主题，子图题注分别说明各自表达的关系。

#subpar.grid(
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/01-commutative.typ")),
    caption: [交换关系],
  ), <fig:ch3-fletcher-commutative>,
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/10-category-theory.typ")),
    caption: [范畴关系],
  ), <fig:ch3-fletcher-category>,
  figure(
    align(center, official-example(include "../third-party/fletcher/readme-examples/3-state-machine.typ")),
    caption: [离散状态机],
  ), <fig:ch3-fletcher-state>,
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/08-tree.typ")),
    caption: [层级状态树],
  ), <fig:ch3-fletcher-tree>,
  columns: (1fr, 1fr),
  gutter: 6pt,
  show-sub-caption: subfigure-caption,
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  supplement: [图],
  // 学校格式文档：图中若有分图时用 a)、b) 等置于分图之下。
  numbering-sub: "a)",
  caption: [状态关系图组：交换图、范畴图、状态机与层级树],
  label: <fig:ch3-fletcher-group>,
)

上述图中的箭头表示关系的方向，节点表示状态、对象或中间变量。对于真实论文，应在图前定义节点集合和映射，在图后说明哪些箭头对应 @eq:state-update，避免用图形替代数学定义。

== 概率模型

=== 模型参数与边界条件

本节用于放置参数表、初始条件和边界条件。真实论文接入后，公式、图表和引用可以继续沿用同一章节层级。

=== 行内、行间与分段公式

短表达式适合放在正文中，例如状态转移的离散形式可写为 $bold(x)_(k+1) = A bold(x)_k + bold(w)_k$。当公式需要独立展示时，可以使用下面的行间公式：

#math.equation(
  $ bold(x)_(k+1) = A bold(x)_k + B bold(u)_k + bold(w)_k $,
) <eq:state-update>

分段定义可用 `cases` 表示。与普通文本一样，分段公式会自动继承模板的数学字号和章节编号规则。

#math.equation(
  $ P(X = x_i) = cases(
    p_i & quad x_i in S,
    0 & quad x_i in.not S,
  ) $,
) <eq:piecewise-probability>

对于同时给出观测方程和状态方程的场景，可用数学模式中的 `&` 对齐点和换行符，将多行内容排成一个公式块：

#math.equation(
  $ bold(x)_(k+1) &= A bold(x)_k + B bold(u)_k + bold(w)_k \
    bold(y)_k &= C bold(x)_k + bold(v)_k $,
) <eq:state-observation>

公式标签也可以跨章节引用，例如 @eq:state-update。真实论文中建议为关键定义、定理和推导保留稳定标签，避免手工维护编号。

=== 模型验证与讨论

为了验证状态转移模型，需要将预测状态与观测状态放在同一时间轴上比较。若观测误差协方差记为 $R$，则一个简单的标准化残差可以写成

#math.equation(
  $ z_k = (bold(y)_k - C bold(x)_k) / sqrt(R) $,
) <eq:standardized-residual>

当 $z_k$ 长时间偏离零时，应优先检查观测矩阵、边界条件和时间同步，而不是直接增加模型参数。这个例子也说明，行间公式、解释文字和图表之间应形成连续的推理链；公式不能脱离上下文单独占据页面。

对于多个状态变量，可以进一步报告状态转移矩阵的谱半径、预测误差和收敛步数。正式论文中应在本节给出实验设置、重复次数和统计检验方法，并说明哪些结果来自真实数据，哪些结果只是数值模拟。

== 数学分析基础

=== 极限、连续与导数

时间演化的局部性质由导数描述。把位移、速度和加速度写成对时间的各阶导数后，模型的状态量之间就建立了可微的依赖关系，后续的线性化和灵敏度分析都建立在这一步之上。

#math.equation(
  $ lim_(h -> 0) (f(x_0 + h) - f(x_0))/h = f'(x_0), quad
    f'(x) = (dif y)/(dif x), quad f''(x) = (dif^2 y)/(dif x^2), quad
    dot(x)(t) = (dif x)/(dif t) $,
) <eq:derivative>

中值定理和泰勒展开把局部导数与整体变化联系起来。工程上常取二阶展开近似代价函数在最优解附近的形状，据此判断迭代收敛是线性还是二次的。

#math.equation(
  $ f(x_0 + h) = f(x_0) + f'(x_0) h + 1/2 f''(x_0) h^2 + O(h^3) $,
) <eq:taylor>

#math.equation(
  $ f(b) - f(a) = f'(xi)(b - a), quad xi in (a, b) $,
) <eq:mean-value>

多尺度模型的渐近分析还要求处理不定式极限。下面的两式分别给出小量展开和远场衰减的常用结果，正文中应说明展开成立的量级范围。

#math.equation(
  $ lim_(x -> 0) (sin x)/x = 1, quad
    lim_(x -> oo) (ln x)/x^p = 0, quad p > 0, quad
    e^x = sum_(k=0)^oo x^k/(k!) $,
) <eq:asymptotic-limits>

=== 最优性条件

无约束问题的一阶必要条件给出驻点，二阶条件区分极小点与鞍点。把梯度写成向量、把二阶导数写成 Hessian 矩阵后，两个条件可以用同一套记号表达。

#math.equation(
  $ min_(bold(x) in RR^n) f(bold(x)), quad
    nabla f(bold(x)^*) = bold(0), quad
    bold(H)(bold(x)^*) = ((partial^2 f)/(partial x_i partial x_j))_(i j) > 0 $,
) <eq:optimality>

带约束的问题用拉格朗日函数处理：等式约束引入乘子，不等式约束引入非负乘子。KKT 条件把原始可行性与对偶可行性、互补松弛写在同一组方程里。

#math.equation(
  $ cal(L)(bold(x), bold(lambda), bold(mu)) = f(bold(x)) + sum_(i=1)^m lambda_i g_i(bold(x)) + sum_(j=1)^p mu_j h_j(bold(x)) $,
) <eq:lagrangian>

#math.equation(
  $ nabla f(bold(x)^*) + sum_(i=1)^m lambda_i nabla g_i(bold(x)^*) + sum_(j=1)^p mu_j nabla h_j(bold(x)^*) = bold(0), quad
    mu_j >= 0, quad mu_j h_j(bold(x)^*) = 0 $,
) <eq:kkt>

当目标函数是凸函数、可行域是凸集时，KKT 条件不仅是必要条件，也是充分条件。这一性质决定了内点法和序列二次规划能否给出全局最优解，正文应明确所求解问题的凸性。

#math.equation(
  $ f(theta bold(x) + (1 - theta) bold(y)) <= theta f(bold(x)) + (1 - theta) f(bold(y)), quad theta in [0, 1] $,
) <eq:convexity>

=== 矩阵分解与谱

对称正定矩阵的特征分解把二次型化为平方和，条件数衡量问题对扰动的敏感程度。谱半径同时决定迭代格式是否收敛，因此它既出现在数值分析里，也出现在稳定性讨论中。

#math.equation(
  $ bold(A) = bold(Q) bold(Lambda) bold(Q)^top, quad
    bold(A) bold(q)_i = lambda_i bold(q)_i, quad
    bold(x)^top bold(A) bold(x) = sum_(i=1)^n lambda_i (bold(q)_i^top bold(x))^2 $,
) <eq:eigen>

一般矩阵用奇异值分解。截断较小的奇异值就是在最小二乘意义下取得最优的低秩近似，这一点在模型降阶和参数矩阵压缩中直接使用。

#math.equation(
  $ bold(A) = bold(U) bold(Sigma) bold(V)^top = sum_(i=1)^r sigma_i bold(u)_i bold(v)_i^top, quad
    kappa(bold(A)) = sigma_max/sigma_min $,
) <eq:svd>

=== 不等式与误差估计

推导误差上界时常用的几个不等式如下。它们给出的是最坏情况估计，实际误差通常更小，因此正文应说明估计的保守程度，而不是把上界当作实际误差报告。

#math.equation(
  $ abs(bold(x)^top bold(y)) <= norm(bold(x))_2 norm(bold(y))_2, quad
    (sum_(i=1)^n a_i b_i)^2 <= (sum_(i=1)^n a_i^2)(sum_(i=1)^n b_i^2) $,
) <eq:cauchy-schwarz>

#math.equation(
  $ phi(E[X]) <= E[phi(X)], quad phi "为凸函数", quad
    norm(bold(x) + bold(y)) <= norm(bold(x)) + norm(bold(y)) $,
) <eq:jensen>

把上述工具组合起来，可以给出数值解与真解之差的先验估计。下式中右端的第一项来自截断误差，第二项来自数据误差，二者随网格加密的下降速度不同，因此需要分别报告。

#math.equation(
  $ norm(bold(u)_h - bold(u)) <= C_1 h^p + C_2 delta, quad
    delta = norm(bold(y) - bold(y)_"true")/norm(bold(y)_"true") $,
) <eq:error-bound>

== 本章小结

本章示例给出了理论基础、概率模型、参数设置以及中文定理环境的组织方式。定理环境的视觉样式属于内容层扩展，不会修改模板的页眉、正文间距或章节编号规则。
