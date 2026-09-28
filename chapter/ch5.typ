= 超音速牛奶喷射与时间旅行的应用前景

#import "../njust-thesis/style.typ": 字号, 字体
#import "@preview/subpar:0.2.2"
#import "../njust-thesis/lib.typ": th, table-note, compact-table, chapter-figure-numbering, official-example, subfigure-caption
#import "@preview/cetz:0.5.2": canvas, draw
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/lovelace:0.3.1": pseudocode-list

本章讨论模型从实验分析走向应用时需要补充的工程环节。应用前景不能只写成愿景，还应明确输入、处理、决策、异常处理和输出之间的对应关系，并说明哪些结论仍然依赖实验条件。

== 应用场景

=== 食品加工

在食品加工场景中，喷射速度、温度和黏度共同决定输送稳定性。实际部署时，控制器需要根据在线传感器估计当前状态，再决定是否调整喷嘴压力或暂停生产。因此，论文应同时报告稳态性能和扰动恢复时间，而不是只报告理想工况下的峰值效率。

=== 时空导航

时空导航场景更关心状态预测和不确定性传播。模型输出不能只给出一个时间点，而应给出预测区间、置信水平和异常状态的处理策略。对于跨设备部署，还要明确时间同步误差、通信延迟和模型更新周期。

=== 数据处理算法

论文描述数值求解、实验处理或数据筛选过程时，可以把关键步骤整理为带缩进和行号的伪代码。下面的算法与前文的状态模型对应，强调的是执行顺序而不是某一种编程语言的语法。

#figure(
  kind: "algorithm",
  supplement: "算法",
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  // 占满版心并左对齐：figure 默认把正文块居中，算法框居中会留下过宽的两侧留白。
  align(left)[
    #set text(font: 字体.宋体, size: 字号.五号, weight: "regular")
    #set par(first-line-indent: 0em, leading: 7pt, spacing: 6pt)
    #block(
      width: 100%,
      stroke: (top: 0.8pt, bottom: 0.5pt),
      inset: (y: 5pt),
    )[
      输入：观测序列 $bold(y)_1, ..., bold(y)_n$，参数 $theta$，异常阈值 $epsilon$ \
      输出：估计状态 $hat(bold(x))_1, ..., hat(bold(x))_n$ 与异常标记
    ]
    #v(4pt)
    #pseudocode-list(numbered: true, line-numbering: "1:")[
      + 读取观测序列 $bold(y)_1, ..., bold(y)_n$ 与参数 $theta$
      + 初始化状态 $bold(x)_0$ 和协方差 $P_0$
      + *for* $k = 1, 2, ..., n$：
        + 预测状态并计算残差
        + 更新状态与置信区间
        + *if* 残差超过阈值：
          + 标记异常观测，并记录观测序号
      + 输出状态序列与异常记录
    ]
    #v(2pt)
    #line(length: 100%, stroke: 0.8pt)
  ],
  caption: [概率响应估计算法],
) <alg:response>

@alg:response 中的阈值、状态转移矩阵和协方差更新公式应在正文中分别定义。这样读者能够把伪代码中的每一步追溯到模型假设，而不会把算法框误认为不可复现的流程装饰。

=== 流程示意图

伪代码强调步骤顺序，流程图则适合说明分支和反馈关系。下面使用 CeTZ 画出数据读取、参数估计、异常重试和结果输出之间的关系。

#let process-diagram = canvas({
  import draw: *
  let link-color = rgb("#000000")

  rect((0, 2.4), (2.3, 3.4), name: "start", radius: .15, fill: rgb("#eaf2f8"), stroke: (paint: rgb("#2e86c1"), thickness: 1pt))
  rect((3.2, 2.4), (5.5, 3.4), name: "estimate", fill: rgb("#e8f8f5"), stroke: (paint: rgb("#17a589"), thickness: 1pt))
  rect((6.4, 2.4), (8.7, 3.4), name: "output", radius: .15, fill: rgb("#fef9e7"), stroke: (paint: rgb("#d4ac0d"), thickness: 1pt))
  rect((3.2, 0), (5.5, 1.0), name: "retry", radius: .08, fill: rgb("#fbeee6"), stroke: (paint: rgb("#ca6f1e"), thickness: 1pt))

  content((1.15, 2.9), [读取数据])
  content((4.35, 2.9), [估计参数])
  content((7.55, 2.9), [输出结果])
  content((4.35, .5), [调整步长])

  line("start", "estimate", stroke: (paint: link-color, thickness: .8pt), mark: (end: "stealth", fill: link-color, stroke: (paint: link-color, thickness: .8pt)))
  line("estimate", "output", stroke: (paint: link-color, thickness: .8pt), mark: (end: "stealth", fill: link-color, stroke: (paint: link-color, thickness: .8pt)))
  line("estimate", "retry", stroke: (paint: link-color, thickness: .8pt), mark: (end: "stealth", fill: link-color, stroke: (paint: link-color, thickness: .8pt)))
  line("retry", "start", stroke: (paint: link-color, thickness: .8pt), mark: (end: "stealth", fill: link-color, stroke: (paint: link-color, thickness: .8pt)))
})

#figure(align(center, process-diagram), caption: [带异常重试的参数估计流程]) <fig:process>

=== 模块接口关系

当论文需要强调模块接口而不是几何位置时，Fletcher 可以用更紧凑的节点和箭头表达状态转移。示意图应控制在版心宽度以内，并通过正文解释节点含义，不能把图例文字全部塞进图内。

#figure(
  align(center,
    fletcher.diagram(
      node-stroke: 0.8pt,
      node-fill: luma(96%),
      spacing: 2.2em,
      fletcher.node((0, 0), [采集], corner-radius: 2pt),
      fletcher.edge("-|>"),
      fletcher.node((0, 1), [估计], corner-radius: 2pt),
      fletcher.edge("-|>"),
      fletcher.node((0, 2), [决策], corner-radius: 2pt),
    ),
  ),
  caption: [状态处理模块的接口关系],
) <fig:fletcher>

为了比较不同层次的工程图，下面把六张 Fletcher 图组织为一个子图组（图 5.3）：层级架构、输入输出流程、有向网络、节点分组、UML 接口和代数结构。同一绘图系统的结构图放在同一子图容器内，总题注说明共同主题，子图题注说明各自表达的关系；与本章论证关系不大的图仍可保留为独立普通图。

// 六张工程图共用一个总题注，子图题注用 (a)–(f) 标注；两列三行而非三列两行，
// 是为了让每格的图内文字保持在正文可读字号（三列时流程图会缩到 40% 左右）。
#subpar.grid(
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/03-ml-architecture.typ")),
    caption: [层级架构],
  ), <fig:ch5-fletcher-architecture>,
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/04-io-flowchart.typ")),
    caption: [输入输出流程],
  ), <fig:ch5-fletcher-io>,
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/05-digraph.typ")),
    caption: [有向网络],
  ), <fig:ch5-fletcher-digraph>,
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/06-node-groups.typ")),
    caption: [节点分组],
  ), <fig:ch5-fletcher-groups>,
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/07-uml-diagram.typ")),
    caption: [UML 接口关系],
  ), <fig:ch5-fletcher-uml>,
  figure(
    align(center, official-example(include "../third-party/fletcher/gallery/02-algebra-cube.typ")),
    caption: [代数结构层级],
  ), <fig:ch5-fletcher-algebra>,
  columns: (1fr, 1fr),
  gutter: 6pt,
  show-sub-caption: subfigure-caption,
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  supplement: [图],
  // 学校格式文档：图中若有分图时用 a)、b) 等置于分图之下。
  numbering-sub: "a)",
  caption: [工程模块图组：层级架构、输入输出流程、有向网络、节点分组、UML 接口与代数结构],
  label: <fig:ch5-fletcher-group>,
)

== 数据处理与评估

=== 滤波与谱分析

实测信号总含有测量噪声，因此进入参数估计之前需要先做滤波。滑动平均是最简单的低通滤波，一阶惯性环节则给出可解析的传递函数，二者都应在正文中说明截止频率与相位滞后。

#math.equation(
  $ hat(y)_k = 1/(2m + 1) sum_(j=-m)^m y_(k+j), quad
    H(omega) = 1/(1 + upright(i) omega tau), quad
    abs(H(omega)) = 1/sqrt(1 + (omega tau)^2) $,
) <eq:filters>

功率谱密度把信号的方差按频率分解，用于判断周期性扰动来自哪一频段。估计谱时需要说明窗函数和平均段数，否则峰值会被泄漏和方差掩盖。

#math.equation(
  $ S(omega) = lim_(T -> oo) 1/T abs(integral_0^T y(t) e^(-upright(i) omega t) dif t)^2, quad
    integral_(-oo)^oo S(omega) dif omega = "Var"[y] $,
) <eq:psd>

离散频谱的可用范围由采样定理限定，混叠一旦发生就无法通过后处理恢复。工程上通常在采样前加模拟低通滤波，并在正文中给出抗混叠滤波器的参数。

#math.equation(
  $ omega_"Nyquist" = pi f_s, quad f_s = 1/(Delta t), quad f_s > 2 f_"max" $,
) <eq:nyquist>

=== 指标与不确定度

测量结果的不确定度由各输入量的不确定度按灵敏度系数合成。输入量之间相关时必须保留协方差项，只有相互独立时才能把平方和简化成对角线形式。

#math.equation(
  $ u_c^2(y) = sum_(i=1)^n ((partial f)/(partial x_i))^2 u^2(x_i) + 2 sum_(i<j) (partial f)/(partial x_i) (partial f)/(partial x_j) r_(i j) u(x_i) u(x_j) $,
) <eq:uncertainty-propagation>

#math.equation(
  $ u_c(y) = sqrt(sum_(i=1)^n display((partial f)/(partial x_i))^2 u^2(x_i)), quad
    U = k u_c, quad k = 2, quad P approx 95% $,
) <eq:expanded-uncertainty>

评估指标必须成组报告：单看平均误差会掩盖大偏差样本，单看最大误差又会被个别异常值主导。下面的三线表给出示例中使用的指标及其适用条件。

#figure(
  compact-table(table(
    columns: (0.8fr, 2fr, 1.6fr),
    align: (center + horizon, center + horizon, center + horizon),
    stroke: none,
    table.hline(stroke: 1pt),
    table.header(
      th[指标], th[定义], th[适用条件],
      table.hline(stroke: 0.5pt),
    ),
    [RMSE], [误差平方均值的平方根], [重视大偏差、误差近似对称],
    [MAE], [绝对误差的平均值], [存在异常值、需要稳健性],
    [$R^2$], [残差平方和与总平方和之比], [需要与基线模型比较],
    [覆盖率], [真值落入区间的比例], [报告区间估计的可靠性],
    table.hline(stroke: 1pt),
  )),
  caption: [评估指标的定义与适用条件],
) <tab:metrics>

偏差与精密度是两类不同的误差。前者反映系统性偏离，可以通过标定消除；后者反映随机分散，只能通过增加样本量或改进测量链降低。

#math.equation(
  $ "bias" = 1/n sum_(i=1)^n (hat(y)_i - y_i), quad
    s = sqrt(display(1/(n - 1)) sum_(i=1)^n (hat(y)_i - bar(hat(y)))^2) $,
) <eq:bias-precision>

=== 带单位表头与表注的表

单位写在表头里比写在每个数据后面更紧凑，也便于整列换算；表注放在表体下方、与表同属一个
浮动体，用于说明数据来源、符号含义和保留位数。按本模板的统一规则，表中所有列均居中对齐。

#figure(
  compact-table([
    #table(
      columns: (1.3fr, 1fr, 1fr, 1fr, 1fr),
      align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
      stroke: none,
      table.hline(stroke: 1pt),
    table.header(
      th[工况], th[$v_0$ / (m·s⁻¹)], th[$p_0$ / kPa], th[$T_0$ / K], th[样本量 $n$],
      table.hline(stroke: 0.5pt),
    ),
      [工况 A], [340.0], [101.3], [298.1], [12],
      [工况 B], [352.5], [104.7], [301.4], [12],
      [工况 C], [361.2], [98.6], [296.3], [15],
      [工况 D], [375.8], [107.2], [303.9], [15],
      table.hline(stroke: 1pt),
    )
    #table-note[注：表中为示例数据，$v_0$ 为喷嘴出口速度，$p_0$ 与 $T_0$ 为滞止参数；保留位数按仪器分辨力给出。]
  ]),
  caption: [带单位表头与表注的参数表],
) <tab:units>

=== 并排小表

两组独立的对照数据可以并排放在一个小表里各自编号。并排时每张表保留自己的表号、表题和
三线，合计宽度不超过版心；表格内容较多时不要并排，以免单个单元格过窄而频繁换行。

#grid(
  columns: (1fr, 1fr),
  column-gutter: 12pt,
  align: top,
  [
  #figure(
    table(
      columns: (1.2fr, 1fr, 1fr),
      align: (center + horizon, center + horizon, center + horizon),
      stroke: none,
      table.hline(stroke: 1pt),
      table.header(th[指标], th[工况 A], th[工况 B], table.hline(stroke: 0.5pt)),
      [RMSE], [0.0241], [0.0198],
      [MAE], [0.0187], [0.0152],
      [$R^2$], [0.961], [0.973],
      table.hline(stroke: 1pt),
    ),
    caption: [两组工况的误差指标],
  ) <tab:metrics-ab>
  ],
  [
  #figure(
    table(
      columns: (1.2fr, 1fr, 1fr),
      align: (center + horizon, center + horizon, center + horizon),
      stroke: none,
      table.hline(stroke: 1pt),
      table.header(th[指标], th[工况 C], th[工况 D], table.hline(stroke: 0.5pt)),
      [RMSE], [0.0212], [0.0175],
      [MAE], [0.0163], [0.0138],
      [$R^2$], [0.968], [0.979],
      table.hline(stroke: 1pt),
    ),
    caption: [另外两组工况的误差指标],
  ) <tab:metrics-cd>
  ],
)

=== 计算复杂度与资源

把模型部署到在线设备上时，需要同时说明时间复杂度和存储需求。下式给出按网格数估计的计算量与吞吐率关系，正文中应给出实测值与估计值的差异，而不是只给阶数。

#math.equation(
  $ T(n) = C n^3, quad M(n) = 4 n^2 "字节", quad
    t_"step" = T(n)/"throughput", quad E = P t_"step" $,
) <eq:complexity>

迭代求解的终止条件也需要量化。常用的判据是相对残差或参数增量小于给定阈值，阈值应与测量不确定度相当，过严的阈值只会增加迭代次数而不改善结果。

#math.equation(
  $ norm(bold(r)^((k)))/norm(bold(b)) < epsilon_"rel", quad
    norm(bold(theta)^((k+1)) - bold(theta)^((k)))/norm(bold(theta)^((k))) < epsilon_"step" $,
) <eq:stopping>

=== 置信区间估计算法

下面给出重采样置信区间的处理流程。它不假设统计量的解析分布，因此在指标分布未知时比正态近似更稳健；代价是需要重复求解，重采样次数应按目标精度选择。

#figure(
  kind: "algorithm",
  supplement: "算法",
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  align(left)[
    #set text(font: 字体.宋体, size: 字号.五号, weight: "regular")
    #set par(first-line-indent: 0em, leading: 7pt, spacing: 6pt)
    #block(
      width: 100%,
      stroke: (top: 0.8pt, bottom: 0.5pt),
      inset: (y: 5pt),
    )[
      输入：样本 $bold(y)_1, ..., bold(y)_n$，置信水平 $1 - alpha$，重采样次数 $B$ \\
      输出：区间估计 $[hat(theta)_"low", hat(theta)_"high"]$ 与相对半宽
    ]
    #v(4pt)
    #pseudocode-list(numbered: true, line-numbering: "1:")[
      + 计算样本统计量 $hat(theta)$ 与残差标准差 $hat(sigma)$
      + *for* $b = 1, 2, ..., B$：
        + 有放回抽取 $n$ 个样本，得到重采样样本 $bold(y)^((b))$
        + 在重采样样本上重新求解模型，得到 $hat(theta)_b$
        + *if* $hat(theta)_b$ 超出当前区间：
          + 更新区间端点，并累计越界次数
      + 取重采样统计量的 $alpha/2$ 与 $1 - alpha/2$ 分位数
      + *if* 相对半宽大于 $epsilon$：
        + 增大 $B$ 后重新执行上面的循环
      + 输出区间、相对半宽与越界次数
    ]
    #v(2pt)
    #line(length: 100%, stroke: 0.8pt)
  ],
  caption: [重采样置信区间估计],
) <alg:bootstrap>

@alg:bootstrap 的输出包含相对半宽，便于判断重采样次数是否足够；若半宽仍大于容差，应在正文中说明是样本量不足还是模型本身对扰动敏感。

== 风险与展望

=== 工程限制

应用研究需要同时说明设备、材料、环境和伦理等方面的约束，避免把理论推演直接表述为工程结论。模型上线前还应完成独立数据验证、异常场景测试和版本归档。

=== 可复现性

建议在附录或项目仓库中保存原始数据摘要、参数文件、算法版本和编译环境。图表应由固定输入重新生成，正文中只保留经过解释的结果；这样模板替换成真实论文内容后，章节结构仍然稳定。

== 本章小结

本章使用 Lovelace 表达算法步骤，使用 CeTZ 表达带反馈的流程，使用 Fletcher 表达模块接口。三种对象都作为正文论证的一部分出现，图题和分页继续由模板统一控制。
