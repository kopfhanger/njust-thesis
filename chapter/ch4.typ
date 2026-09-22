= 超音速牛奶喷射与时间旅行的异构关系

#import "../njust-thesis/style.typ": 字号, 字体
#import "../njust-thesis/lib.typ": th, compact-table, chapter-figure-numbering, subfigure-caption
#import "@preview/cetz:0.5.2": canvas, draw
#import "@preview/lilaq:0.6.0" as lq
#import "@preview/subpar:0.2.2"

本章在前两章模型的基础上讨论两个子系统之间的耦合关系。这里的数字和图形只用于演示论文写作结构，不代表真实实验结论；正式论文应把示例数据替换为可复现的实验记录，并在图题或正文中说明数据来源。

== 综合分析框架

=== 喷射过程与时间参数的耦合

喷射状态可以用速度、密度和喷嘴几何参数描述，时间状态则用离散的观测时刻与转移概率描述。为了避免把两个模型简单相加，本研究将它们放入同一状态空间，并以耦合系数控制信息从喷射子系统向时间子系统的传递。这样的建模方式有两个优点：一是能够明确区分直接观测量与隐变量，二是方便在后续敏感性分析中逐一关闭耦合项。

=== 模型假设与评价指标

综合模型假设观测误差在相邻时间窗内近似独立，且喷射效率可以由无量纲速度、压力比和状态转移概率共同解释。评价时同时报告均方误差、置信区间和状态转移成功率，避免仅凭一条拟合曲线判断模型优劣。对于实际研究，还需要补充采样频率、异常值处理和训练/验证集划分。

=== 结构关系图

下面的示意图说明数据、模型和预测结果之间的依赖关系。图中的箭头使用线条本身的黑色，节点颜色只承担分组功能；这种做法适合在论文黑白打印时保持方向关系清楚。

#let structure-diagram = canvas({
  import draw: *
  let link-color = rgb("#000000")

  rect((0, 0), (2.4, 1.1), name: "observation", radius: .08, fill: rgb("#eaf2f8"), stroke: (paint: rgb("#2e86c1"), thickness: 1pt))
  rect((3.1, 0), (5.5, 1.1), name: "model", radius: .08, fill: rgb("#e8f8f5"), stroke: (paint: rgb("#17a589"), thickness: 1pt))
  rect((6.2, 0), (8.6, 1.1), name: "prediction", radius: .08, fill: rgb("#fef9e7"), stroke: (paint: rgb("#d4ac0d"), thickness: 1pt))

  content((1.2, .55), [观测数据])
  content((4.3, .55), [概率模型])
  content((7.4, .55), [预测结果])

  line("observation", "model", stroke: (paint: link-color, thickness: .8pt), mark: (end: "stealth", fill: link-color, stroke: (paint: link-color, thickness: .8pt)))
  line("model", "prediction", stroke: (paint: link-color, thickness: .8pt), mark: (end: "stealth", fill: link-color, stroke: (paint: link-color, thickness: .8pt)))
})

#figure(align(center, structure-diagram), caption: [综合模型的结构关系图]) <fig:cetz-structure>

@fig:cetz-structure 不是结果图，而是帮助读者理解变量之间的依赖方向。正文在引用示意图时应解释图中关系与后续公式的对应位置，避免只在段末写“如图所示”。

== 模拟结果

=== 参数响应曲线

为说明数据绘图的正文写法，下面用一组小型模拟数据比较观测值和模型响应。Lilaq 只负责坐标轴、数据线和图例，图题、编号、上下间距和页眉页脚仍由本模板统一处理。

#let xs = (0, 1, 2, 3, 4, 5, 6)
#let observed = (0.48, 0.62, 0.74, 0.69, 0.58, 0.46, 0.38)
#let predicted = xs.map(x => .5 + .4 * calc.exp(-.3 * x) * calc.sin(1.4 * x))
#let ys = predicted
#let lower = ys.map(y => y - .12)

#figure(
  lq.diagram(
    width: 9cm,
    height: 5.6cm,
    xlabel: [$t$],
    ylabel: [$P(t)$],
    legend: (position: bottom),
    lq.plot(xs, observed, mark: "o", label: [观测值]),
    lq.plot(xs, predicted, label: [模型响应]),
  ),
  caption: [观测值与模型响应的比较],
) <fig:lilaq-response>

从 @fig:lilaq-response 可以看到，模型在前两个时间窗内低估了观测值，在后半段则逐渐回到观测曲线附近。正式分析时还应给出误差棒、参数置信区间和残差图；此处只展示一张紧凑的主图，避免把每个绘图 API 都拆成独立页面。

同一组数据还可以从空间分布、方向场和区间估计三个角度观察。@fig:lilaq-diagnostics 将 Lilaq 的等高线、色彩图、矢量场和区间带组合为一个诊断图组：前两者强调状态空间的分布，矢量场强调局部变化方向，区间带则明确表达不确定性范围。真实研究中，这组图可以直接替换为实验网格或仿真输出。

#let ch4-grid = ((.2, .5, .8, 1.0), (.4, .7, 1.1, 1.3), (.6, 1.0, 1.4, 1.8), (.8, 1.3, 1.8, 2.2))
#let ch4-axis = (0, 1, 2, 3)
#subpar.grid(
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.contour(ch4-axis, ch4-axis, ch4-grid, levels: 5, fill: false)),
    caption: [状态等高线],
  ), <fig:ch4-lq-contour>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.colormesh(ch4-axis, ch4-axis, ch4-grid)),
    caption: [状态色彩图],
  ), <fig:ch4-lq-colormesh>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.quiver(ch4-axis, ch4-axis, (x, y) => (1 - y / 4, x / 4))),
    caption: [局部方向场],
  ), <fig:ch4-lq-quiver>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.fill-between(xs, ys, y2: lower, fill: blue.transparentize(75%), stroke: none),
      lq.plot(xs, ys, label: [均值])),
    caption: [预测区间带],
  ), <fig:ch4-lq-band>,
  columns: (1fr, 1fr),
  gutter: 8pt,
  show-sub-caption: subfigure-caption,
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  supplement: [图],
  caption: [状态空间与不确定性传播的 Lilaq 诊断图组],
  label: <fig:lilaq-diagnostics>,
)

=== Lilaq 多子图排版示例

当同一组实验需要同时展示响应曲线、散点关系、离散指标和预测区间时，可以将同一数据对象组织在一个总图中。这里专门使用 Lilaq 的数据绘图结果作为子图；几何结构和模块关系在各自章节中组织为 CeTZ / Fletcher 子图组（图 2.1、图 3.1、图 5.3）。同一绘图系统的对象放在同一子图容器内，不把 Lilaq 数据图与 CeTZ 结构图混在一组里。

#subpar.grid(
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.plot(xs, observed, mark: "o", label: [观测值]),
      lq.plot(xs, predicted, label: [模型响应])),
    caption: [观测与模型],
  ), <fig:ch4-lq-observed>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.scatter(xs, predicted, color: (1, 2, 3, 4, 5, 6, 7), mark: "o")),
    caption: [彩色散点关系],
  ), <fig:ch4-lq-scatter>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.bar((1, 2, 3, 4), (1.3, 2.1, 1.7, 2.6))),
    caption: [离散指标],
  ), <fig:ch4-lq-bar>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.fill-between(xs, predicted, y2: lower, fill: blue.transparentize(75%), stroke: none),
      lq.plot(xs, predicted, label: [均值])),
    caption: [预测区间带],
  ), <fig:ch4-lq-band-panel>,
  columns: (1fr, 1fr),
  gutter: 8pt,
  show-sub-caption: subfigure-caption,
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  supplement: [图],
  caption: [同一模型的 Lilaq 数据视图],
  label: <fig:lilaq-multi-panel>,
)

== 数值离散与误差分析

=== 空间与时间离散

把连续的输运方程交给计算机求解，第一步是把导数换成差分。中心差分在相同网格下比单侧差分高一阶，代价是需要相邻两个网格点的值，因此在边界附近必须降阶处理。

#math.equation(
  $ (partial u)/(partial x)_i approx (u_(i+1) - u_i)/h + O(h), quad
    (partial u)/(partial x)_i approx (u_(i+1) - u_(i-1))/(2h) + O(h^2) $,
) <eq:fd-stencils>

#math.equation(
  $ (partial^2 u)/(partial x^2)_i approx (u_(i+1) - 2 u_i + u_(i-1))/h^2 + O(h^2) $,
) <eq:fd-stencil-second>

时间方向可以显式推进，也可以隐式求解。显式格式每步只做一次函数求值，但受步长限制；隐式格式每步要解一个线性方程组，换来了更大的稳定域。

#math.equation(
  $ bold(u)^(n+1) = bold(u)^n + Delta t bold(F)(bold(u)^n), quad
    (bold(I) - Delta t bold(J)) bold(u)^(n+1) = bold(u)^n + Delta t bold(g), quad
    bold(J) = (partial bold(F))/(partial bold(u)) $,
) <eq:time-stepping>

把显式和隐式加权组合可以得到二阶精度的 Crank--Nicolson 格式。权重取 $1/2$ 时截断误差的主项相互抵消，但每步的计算量与隐式格式相同。

#math.equation(
  $ (bold(u)^(n+1) - bold(u)^n)/(Delta t) = 1/2 (bold(F)(bold(u)^(n+1)) + bold(F)(bold(u)^n)) $,
) <eq:crank-nicolson>

=== 截断误差与收敛阶

误差随步长下降的速度决定了加密网格的收益。若误差按 $h^p$ 下降，则步长减半时期望误差降为原来的 $2^(-p)$；实测阶数可以用两次不同步长的结果反算，并用于检查实现是否正确。

#math.equation(
  $ e_h = norm(bold(u)_h - bold(u)) = C h^p + O(h^(p+1)), quad
    p = log_2 (e_h/e_(h \/ 2)) $,
) <eq:convergence-order>

已知误差的主项形状后，可以用两个不同步长的解消去主项，得到更高精度的外推结果。这一技巧在网格序列收敛性验证中比单纯加密网格更经济。

#math.equation(
  $ tilde(u)_h = (2^p u_(h \/ 2) - u_h)/(2^p - 1) $,
) <eq:richardson>

#math.equation(
  $ "误差来源" = underbrace(e_"截断", "格式") + underbrace(e_"舍入", "字长") + underbrace(e_"模型", "假设") $,
) <eq:error-sources>

=== 稳定性与步长约束

显式格式的步长受网格尺度和物理系数共同限制。扩散项的时间步长与空间步长的平方成正比，对流项则与空间步长成正比，因此细网格下扩散往往成为限制因素。

#math.equation(
  $ Delta t <= (h^2)/(2 D), quad
    Delta t <= h/(abs(v)_max), quad
    "CFL" = (abs(v) Delta t)/h <= 1 $,
) <eq:cfl>

稳定性的频域判据把放大因子写成波数和步长的函数。要求放大因子的模不超过 1，就得到与上面一致的步长约束。

#math.equation(
  $ abs(g(theta)) <= 1, quad theta in [0, pi], quad
    g(theta) = 1 - 4 nu sin^2(theta/2), quad nu = (D Delta t)/h^2 $,
) <eq:von-neumann>

下面的三线表对比常用离散格式的精度与代价，便于按问题的时间尺度选择格式。表中代价按每步的函数求值次数和线性求解次数给出，不含数据读写。

#figure(
  table(
    columns: (1.2fr, 0.85fr, 1.15fr, 1.15fr, 1.15fr),
    align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: none,
    table.hline(stroke: 1pt),
    table.header(
      th[格式], th[时间精度], th[稳定性], th[每步代价], th[适用场景],
      table.hline(stroke: 0.5pt),
    ),
    [显式欧拉], [一阶], [需满足步长限制], [一次函数求值], [短时、刚性弱],
    [隐式欧拉], [一阶], [无条件稳定], [一次线性求解], [刚性、长时],
    [Crank--Nicolson], [二阶], [无条件稳定], [一次线性求解], [扩散主导],
    [四阶 Runge--Kutta], [四阶], [步长限制较宽], [四次函数求值], [光滑非刚性],
    table.hline(stroke: 1pt),
  ),
  caption: [常用离散格式的精度、稳定性与代价对照],
) <tab:schemes>

=== 参数扫描与转页长表

参数扫描会得到行数较多的结果表。学校格式文档要求续表重复表的编排，因此在需要转页的
表里用 `table.header(...)` 包住表头：表头会在每一页重复，读者不必回到上一页找列名。
下面的表是这一版式的示例，行数刻意留多，用来观察转页后的表头重复情况。

// 跨页长表：figure 是不可分割的原子块，把表体放进 figure 会被裁掉而不是转页。
// 因此这里用「空 body 的 figure 出表号与表题」+「紧跟其后、可跨页的 table」，
// 表头用 table.header(...) 在每页重复（学校文档要求续表重复表的编排）。
#figure(
  kind: table,
  caption: [参数扫描结果（跨页长表示例）],
  [],
) <tab:sweep>
#v(-6pt)
#table(
    columns: (0.7fr, 1fr, 1.2fr, 1fr, 1fr, 1fr),
    align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: none,
    table.hline(stroke: 1pt),
    table.header(
      th[序号], th[步长 $h$ / mm], th[网格数], th[实测收敛阶], th[RMSE], th[耗时 / s],
      table.hline(stroke: 0.5pt),
    ),
      [1], [0.02], [4], [1.50], [0.00433], [3.4],
      [2], [0.04], [8], [1.33], [0.00584], [3.8],
      [3], [0.06], [16], [1.25], [0.01287], [4.2],
      [4], [0.08], [32], [1.20], [0.01646], [4.6],
      [5], [0.10], [64], [2.00], [0.02090], [5.0],
      [6], [0.12], [128], [1.50], [0.03050], [5.5],
      [7], [0.14], [256], [1.33], [0.03643], [5.9],
      [8], [0.16], [512], [1.25], [0.04303], [6.3],
      [9], [0.18], [1,024], [1.20], [0.05467], [6.7],
      [10], [0.20], [2,048], [2.00], [0.06252], [7.1],
      [11], [0.22], [4,096], [1.50], [0.07095], [7.5],
      [12], [0.24], [8,192], [1.33], [0.08435], [7.9],
      [13], [0.26], [16,384], [1.25], [0.09389], [8.3],
      [14], [0.28], [32,768], [1.20], [0.10836], [8.7],
      [15], [0.30], [65,536], [2.00], [0.11894], [9.1],
      [16], [0.32], [131,072], [1.50], [0.13002], [9.6],
      [17], [0.34], [262,144], [1.33], [0.14598], [10.0],
      [18], [0.36], [524,288], [1.25], [0.15802], [10.4],
      [19], [0.38], [1,048,576], [1.20], [0.17052], [10.8],
      [20], [0.40], [2,097,152], [2.00], [0.18787], [11.2],
      [21], [0.42], [4,194,304], [1.50], [0.20126], [11.6],
      [22], [0.44], [8,388,608], [1.33], [0.21509], [12.0],
      [23], [0.46], [16,777,216], [1.25], [0.23374], [12.4],
      [24], [0.48], [33,554,432], [1.20], [0.24842], [12.8],
      [25], [0.50], [67,108,864], [2.00], [0.26790], [13.2],
      [26], [0.52], [134,217,728], [1.50], [0.28339], [13.7],
      [27], [0.54], [268,435,456], [1.33], [0.29928], [14.1],
      [28], [0.56], [536,870,912], [1.25], [0.31997], [14.5],
      [29], [0.58], [1,073,741,824], [1.20], [0.33664], [14.9],
      [30], [0.60], [2,147,483,648], [2.00], [0.35369], [15.3],
      [31], [0.62], [4,294,967,296], [1.50], [0.37552], [15.7],
      [32], [0.64], [8,589,934,592], [1.33], [0.39332], [16.1],
      [33], [0.66], [17,179,869,184], [1.25], [0.41149], [16.5],
      [34], [0.68], [34,359,738,368], [1.20], [0.43442], [16.9],
      [35], [0.70], [68,719,476,736], [2.00], [0.45331], [17.4],
      [36], [0.72], [137,438,953,472], [1.50], [0.47696], [17.8],
      [37], [0.74], [274,877,906,944], [1.33], [0.49655], [18.2],
      [38], [0.76], [549,755,813,888], [1.25], [0.51649], [18.6],
      [39], [0.78], [1,099,511,627,776], [1.20], [0.54118], [19.0],
      [40], [0.80], [2,199,023,255,552], [2.00], [0.56180], [19.4],
      [41], [0.82], [4,398,046,511,104], [1.50], [0.58276], [19.8],
      [42], [0.84], [8,796,093,022,208], [1.33], [0.60845], [20.2],
      [43], [0.86], [17,592,186,044,416], [1.25], [0.63007], [20.6],
      [44], [0.88], [35,184,372,088,832], [1.20], [0.65202], [21.0],
      [45], [0.90], [70,368,744,177,664], [2.00], [0.67869], [21.4],
    table.hline(stroke: 1pt),
)

=== 分组表头与合并单元格

同一类参数需要合并表头时，用 `table.cell(colspan: ...)` 让一个单元格横跨多列，
用 `table.cell(rowspan: ...)` 让类别名纵跨多行。合并只用在表头上，数据行保持一列一项，
便于机器读取和后续核对。

#figure(
  table(
    columns: (1.1fr, 1fr, 1fr, 1fr, 1fr),
    align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: none,
    table.hline(stroke: 1pt),
    table.header(
      table.cell(rowspan: 2)[#th[工况]], table.cell(colspan: 2)[几何参数], table.cell(colspan: 2)[物理参数],
      table.hline(start: 1, end: 5, stroke: 0.5pt),
      th[长度 $L$ / m], th[直径 $d$ / m], th[黏度 $mu$ / (mPa·s)], th[密度 $rho$ / (kg·m⁻³)],
      table.hline(stroke: 0.5pt),
    ),
    [工况 A], [0.012], [0.004], [1.8], [1030],
    [工况 B], [0.018], [0.006], [2.4], [1050],
    [工况 C], [0.024], [0.008], [3.1], [1080],
    table.hline(stroke: 1pt),
  ),
  caption: [分组表头与合并单元格示例],
) <tab:grouped>

=== 参数估计与蒙特卡洛

参数辨识写成最小二乘问题后，正规方程给出解析的驻点条件。当设计矩阵接近奇异时，正规方程的条件数被平方放大，因此实际实现多采用正交分解或直接求解带正则项的形式。

#math.equation(
  $ hat(bold(theta)) = op("arg min")_bold(theta) sum_(i=1)^n (y_i - f(bold(x)_i, bold(theta)))^2, quad
    (bold(J)^top bold(J)) hat(bold(theta)) = bold(J)^top bold(y) $,
) <eq:least-squares>

#math.equation(
  $ hat(bold(theta))_"ridge" = op("arg min")_bold(theta) (norm(bold(y) - bold(J) bold(theta))_2^2 + alpha norm(bold(theta))_2^2), quad
    hat(bold(theta))_"ridge" = (bold(J)^top bold(J) + alpha bold(I))^(-1) bold(J)^top bold(y) $,
) <eq:ridge>

参数估计的不确定度由残差方差和设计矩阵共同决定。下式给出协方差矩阵的经典估计，用于构造参数的置信区间：

#math.equation(
  $ "Cov"[hat(bold(theta))] = sigma^2 (bold(J)^top bold(J))^(-1), quad
    hat(sigma)^2 = 1/(n - p) sum_(i=1)^n (y_i - hat(y)_i)^2 $,
) <eq:covariance-estimate>

当模型无法解析求导或维数很高时，用随机采样估计积分和期望。蒙特卡洛估计的误差按样本量的平方根下降，与维数无关，这是它相对于网格法的核心优势。

#math.equation(
  $ hat(mu) = 1/N sum_(k=1)^N g(bold(z)_k), quad
    "Var"[hat(mu)] = (sigma_g^2)/N, quad
    "RMSE" = sigma_g/sqrt(N) $,
) <eq:monte-carlo>

重要性采样通过改变采样分布降低方差。权重比把有偏采样还原为无偏估计，权重退化时应改用自适应或分层采样：

#math.equation(
  $ hat(mu)_"IS" = 1/N sum_(k=1)^N (p(bold(z)_k))/(q(bold(z)_k)) g(bold(z)_k), quad
    bold(z)_k tilde q $,
) <eq:importance-sampling>

== 讨论

=== 模型适用范围

综合模型适用于说明两个子系统之间的变量传递和不确定性传播，但不能替代对真实装置的标定。尤其当喷射过程出现非稳态破碎、温度变化或材料参数显著漂移时，应重新检查状态变量的定义和观测模型。图表应服务于这些判断，而不是为了展示包的全部功能。

=== 误差来源

误差来源可以分为测量误差、模型误差和离散化误差三类。报告结果时应说明每一类误差如何估计，以及它们是否被纳入最终置信区间。对于具有时间相关性的观测，不能直接套用独立同分布假设，否则会低估预测区间的宽度。

== 本章小结

本章用 CeTZ 绘制结构示意图，用 Lilaq 绘制普通数据曲线和统一的多子图数据视图。不同图形工具均被放进连续论述中，没有改变模板的全局图表间距，也没有引入示例内部的分页控制。
