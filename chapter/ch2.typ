= 超音速牛奶喷射的概率动力学

#import "../njust-thesis/style.typ": 字号, 字体
#import "../njust-thesis/lib.typ": th, table-note, compact-table, chapter-figure-numbering, official-example, subfigure-caption
#import "@preview/physica:0.9.8": curl, grad, tensor, pdv
#import "@preview/unify:0.8.1": num, qty, qtyrange
#import "@preview/lilaq:0.6.0" as lq
#import "@preview/subpar:0.2.2"

本章建立一个用于演示的超音速喷射参数模型。内容不对应真实实验结论，但刻意覆盖物理记号、行内公式、行间公式、参数表和单位排版，便于将本章替换为真实研究内容时直接复用结构。

== 超音速喷射模型

=== 喷射过程与基本假设

针对超音速牛奶喷射过程，示例模型将喷嘴出口速度、流体黏度和环境压力作为主要参数，并在稳态条件下讨论喷流的形成与传播。设喷嘴出口截面积为 $A_0$、特征长度为 $L$、流体密度为 $rho$，则质量流率可以作为连接实验观测与动力学模型的中间量。实际论文中应在这里给出装置、测量不确定度和边界条件，而不是只保留符号定义。

为了说明物理过程、几何关系和状态变量之间的差别，下面把四个常用的 CeTZ 示意图组织为一个子图组（图 2.1）：波动场、三角几何关系、场线与介质以及表达式树。示意图的作用是帮助读者理解变量之间的关系，并不替代实验装置图或数值结果。

// 四张 CeTZ 示意图组织为一个子图组：缩放比例按子图格宽度（约 74mm）反推，
// 保证图内文字不被压到小于正文可读字号。
#subpar.grid(
  figure(
    align(center, official-example(include "../third-party/cetz/gallery/waves.typ")),
    caption: [叠加波动场],
  ), <fig:ch2-cetz-waves>,
  figure(
    align(center, official-example(include "../third-party/cetz/gallery/karls-picture.typ")),
    caption: [几何关系与角度],
  ), <fig:ch2-cetz-angle>,
  figure(
    align(center, official-example(include "../third-party/cetz/gallery/plate-capacitor.typ")),
    caption: [场线与介质区域],
  ), <fig:ch2-cetz-field>,
  figure(
    align(center, official-example(include "../third-party/cetz/gallery/tree.typ")),
    caption: [表达式树结构],
  ), <fig:ch2-cetz-tree>,
  columns: (1fr, 1fr),
  gutter: 6pt,
  show-sub-caption: subfigure-caption,
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  supplement: [图],
  // 学校格式文档：图中若有分图时用 a)、b) 等置于分图之下。
  numbering-sub: "a)",
  caption: [CeTZ 建模视角示意图组：连续场、几何约束、介质区域与离散结构],
  label: <fig:ch2-cetz-group>,
)

这些图形分别对应连续场、几何约束、介质区域和离散结构四种建模视角。真实论文中应为每张图配套说明变量、边界条件和数据来源，而不是把绘图工具本身作为结果。

在连续介质近似下，速度场 $bold(v)$ 的旋度和梯度可以使用 Physica 提供的记号函数表达。它们适合在正文中保持统一的数学语义：

#math.equation(
  $ curl (grad phi) = 0, quad tensor(T, -mu, +nu) = T^mu^nu, quad pdv(p, x, y, [1, 2]) $,
) <eq:physica-notation>

@eq:physica-notation 只展示记号工具的接入方式；实际研究中应根据张量的坐标变换规则和物理量的量纲给出完整推导。

=== 概率分布与实验指标

在参数分析中，可以用概率分布描述喷射速度和喷射效率的离散性。设出口速度观测值为 $v_i$，样本均值和样本方差分别为 $bar(v)$ 与 $s_v^2$，则重复实验可以用置信区间报告，而不应只报告一个看似精确的平均值。真实论文应在此处给出实验装置、数据来源、计算方法及其误差分析。

当前示例使用模板本地字体和显式单位文本，避免把已知存在兼容性问题的 Metro 带入默认论文构建。待 Metro 上游修复后，可在本节将数字和单位替换为 `qty(340, metre)` 等统一接口。

本模板推荐在真实论文中把实验量与单位绑定书写。例如，喷嘴出口速度可以写成 #qty("340", "m/s")，测量误差可以写成 #num("340+-5")，有效工作区间可以写成 #qtyrange("0.20", "0.80", "mm")。这样单位、数字和误差不会因为手工空格不同而在各章节中产生不一致的视觉结果。

为了避免只展示平均值，本章再给出一组小型数据诊断图。折线图带有误差线，散点图用颜色表达第三个量，柱状图适合汇总离散指标，箱线图则用于比较重复实验的分布。正式论文中应替换为真实观测值，并在正文中解释误差来源。

#let ch2-x = (0, 1, 2, 3, 4, 5)
#let ch2-y = (1.2, 1.8, 1.5, 2.2, 2.6, 2.9)
#subpar.grid(
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.plot(ch2-x, ch2-y, yerr: (.15, .12, .18, .15, .2, .16), label: [观测值])),
    caption: [误差线折线图],
  ), <fig:ch2-lq-errorbar>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.scatter(ch2-x, ch2-y, color: (1, 2, 3, 4, 5, 6), mark: "o")),
    caption: [彩色散点图],
  ), <fig:ch2-lq-scatter>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.bar((1, 2, 3, 4), (1.3, 2.1, 1.7, 2.6))),
    caption: [指标柱状图],
  ), <fig:ch2-lq-bar>,
  figure(
    lq.diagram(width: 100%, height: 3.1cm,
      lq.boxplot((1.0, 1.2, 1.4, 1.6, 2.0, 2.4, 2.8),
        (1.4, 1.7, 1.9, 2.1, 2.4, 2.7, 3.0),
        (1.1, 1.5, 1.8, 2.0, 2.2, 2.5, 2.9))),
    caption: [重复实验分布],
  ), <fig:ch2-lq-boxplot>,
  columns: (1fr, 1fr),
  gutter: 6pt,
  show-sub-caption: subfigure-caption,
  numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
  supplement: [图],
  // 学校格式文档：图中若有分图时用 a)、b) 等置于分图之下。
  numbering-sub: "a)",
  caption: [重复实验数据的 Lilaq 诊断图组],
  label: <fig:ch2-lilaq-gallery>,
)

=== 公式、参数与三线表示例

正文中的行内公式可以直接写在段落中，例如马赫数 $upright("Ma") = v / a$ 和雷诺数 $upright("Re") = rho v L / mu$。较长的推导建议使用带编号的行间公式，以便在后文通过交叉引用定位。

#math.equation(
  $ upright("Re") = (rho v L) / mu, quad upright("Ma") = v / a $,
) <eq:dimensionless-numbers>

需要对齐多行等式时，可使用数学模式中的 `&` 对齐点和换行符；换行后的各行仍共享同一个公式编号。偏导数的混合阶数也可以直接写进公式，从而让复杂模型的推导结构保持可读：

#math.equation(
  $ m &= rho V \
    q &= m c_p (T_2 - T_1) \
    eta &= q / q_"in" $,
) <eq:aligned-example>

#math.equation(
  $ (partial^2 p) / (partial x partial y) = pdv(p, x, y, [1, 1]) $,
) <eq:mixed-derivative>

下面的三线表展示了参数、符号和示例值的常见组织方式。模板已经将表题放在表格上方；正式论文中可把示例值替换为实验数据，并在表格外补充数据来源和单位说明。

#figure(
  compact-table([
    #table(
      columns: (1.5fr, 0.8fr, 1fr, 1fr),
      align: (center + horizon, center + horizon, center + horizon, center + horizon),
      stroke: none,
      table.hline(stroke: 1pt),
    table.header(
      th[参数], th[符号], th[示例取值], th[单位],
      table.hline(stroke: 0.5pt),
    ),
      [喷嘴出口速度], [$v_0$], [$340$], [m/s],
      [特征长度], [$L$], [$0.012$], [m],
      [动力黏度], [$mu$], [$1.8$], [mPa·s],
      [出口压力], [$p_0$], [$1.01 times 10^5$], [Pa],
      table.hline(stroke: 1pt),
    )
    #table-note[注：表中为示例取值，正式论文应给出数据来源、测量方法与不确定度。]
  ]),
  caption: [三线表示例：模型参数],
) <tab:parameters>

公式标签示例：@eq:dimensionless-numbers。公式内容或章节顺序变化时，编号和引用会自动更新。

== 数学工具与表示

=== 张量、矩阵与范数

模型中的参数、观测和中间量分别用标量、向量和张量表示。写成矩阵形式后，状态转移、参数辨识和误差传播可以共用同一套记号，不必在正文里反复展开分量求和。下面的写法同时给出紧凑形式和按分量展开的形式，便于读者在两种表达之间切换。

#math.equation(
  $ bold(A) = mat(
      a_11, a_12, dots, a_(1 n);
      a_21, a_22, dots, a_(2 n);
      dots.v, dots.v, dots.down, dots.v;
      a_(m 1), a_(m 2), dots, a_(m n),
    ), quad bold(x) = vec(x_1, x_2, dots.v, x_n) $,
) <eq:matrix-vector>

矩阵与向量的乘积、二次型和行列式是后续推导中出现频率最高的三种运算。二次型用于表示能量和代价，行列式用于判断线性变换是否可逆，也出现在变量替换的雅可比因子中。

#math.equation(
  $ (bold(A) bold(x))_i = sum_(j=1)^n a_(i j) x_j, quad
    bold(x)^top bold(A) bold(x) = sum_(i=1)^n sum_(j=1)^n a_(i j) x_i x_j, quad
    det(bold(A)) = sum_(sigma in S_n) "sgn"(sigma) product_(i=1)^n a_(i sigma(i)) $,
) <eq:matrix-ops>

度量向量和矩阵的大小需要范数：二范数用来描述观测残差，Frobenius 范数用来描述参数矩阵的整体偏离，谱范数则给出最坏方向上的放大倍数。真实论文应说明各符号的维度、量纲和取值区间，而不是只给出矩阵形状。

#math.equation(
  $ norm(bold(x))_2 = sqrt(sum_(i=1)^n x_i^2), quad
    norm(bold(A))_F = sqrt("tr"(bold(A)^top bold(A))), quad
    norm(bold(A))_2 = max_(norm(bold(x))_2 = 1) norm(bold(A) bold(x))_2 $,
) <eq:norms>

=== 级数、积分与极限

把连续过程离散化时，时间步长和截断阶数决定了需要保留多少项。等比级数给出误差项的上界，连乘形式适合描述逐步累积的衰减，含参积分则用于把边界条件并入解的表达式中。

#math.equation(
  $ sum_(k=0)^oo q^k = 1/(1 - q), quad abs(q) < 1; quad
    sum_(k=1)^n k = (n(n+1))/2; quad
    product_(i=1)^n (1 - epsilon_i) approx 1 - sum_(i=1)^n epsilon_i $,
) <eq:series>

当被积函数含有指数衰减或振荡因子时，解析结果往往可以写成初等函数的组合。下式给出两类在响应分析中反复出现的积分，它们的量纲分别对应时间尺度和幅值密度。

#math.equation(
  $ integral_0^oo e^(-lambda t) dif t = 1/lambda, quad
    integral_(-oo)^oo e^(-a x^2 + b x) dif x = sqrt(display(pi/a)) e^(b^2/(4a)), quad a > 0 $,
) <eq:integrals>

极限记号用于说明离散格式的收敛性。若步长趋于零时截断误差以二阶速度下降，则加密网格带来的收益是可以预期的。

#math.equation(
  $ lim_(n -> oo) (1 + 1/n)^n = e, quad
    lim_(h -> 0) (f(x + h) - 2 f(x) + f(x - h))/h^2 = f''(x) $,
) <eq:limits>

=== 微分算子与场论

喷射流场既可以用分量形式写出，也可以用算符形式写出。算符形式的优点是物理含义清晰：梯度给出最快的增长方向，散度衡量源的强度，旋度描述局部旋转，而拉普拉斯算子把扩散与源项联系在同一方程中。

#math.equation(
  $ grad phi = (pdv(phi, x), pdv(phi, y), pdv(phi, z)), quad
    div bold(v) = pdv(v_x, x) + pdv(v_y, y) + pdv(v_z, z) $,
) <eq:field-operators>

旋度写成行列式形式更紧凑，也便于检查分量中偏导数的配对关系：

#math.equation(
  $ curl bold(v) = mat(
    bold(e)_x, bold(e)_y, bold(e)_z;
    display(partial/(partial x)), display(partial/(partial y)), display(partial/(partial z));
    v_x, v_y, v_z,
  ) = (pdv(v_z, y) - pdv(v_y, z), pdv(v_x, z) - pdv(v_z, x), pdv(v_y, x) - pdv(v_x, y)) $,
) <eq:curl>

把算符组合起来可以得到守恒律和输运方程。下面的对流扩散方程在示例模型里用于描述速度场与浓度场之间的耦合，方程中的每一项都应对应正文中说明过的物理机制。

#math.equation(
  $ pdv(c, t) + bold(v) dot grad c = D nabla^2 c + s(bold(x), t), quad
    pdv(bold(v), t) + (bold(v) dot grad) bold(v) = -1/rho grad p + nu nabla^2 bold(v) $,
) <eq:transport>

=== 概率分布与贝叶斯更新

观测的离散性用概率分布描述。正态密度适合连续量，指数分布适合等待时间，多项分布适合计数；三者的参数都应给出估计方法和置信区间，而不是只给一个点值。

#math.equation(
  $ p(x) = 1/(sigma sqrt(2 pi)) e^(-(x - mu)^2/(2 sigma^2)), quad
    p(t) = lambda e^(-lambda t), quad
    P(bold(n)) = (N!)/(product_i n_i!) product_i p_i^(n_i) $,
) <eq:distributions>

期望和方差是分布的两个基本数字特征。样本量较小时应以区间形式报告结果，因为均值的标准误随样本量按平方根下降，单次实验的波动往往大于均值本身。

#math.equation(
  $ E[X] = integral_(-oo)^oo x p(x) dif x, quad
    "Var"[X] = E[(X - E[X])^2] = E[X^2] - (E[X])^2, quad
    "se"(bar(X)) = sigma/sqrt(n) $,
) <eq:moments>

参数更新写成贝叶斯形式后，先验、似然和后验的关系一目了然。分母是与参数无关的归一化常数，因此工程上常写成正比形式，把计算量集中在似然函数的求值上。

#math.equation(
  $ p(theta | bold(y)) = (p(bold(y) | theta) p(theta)) / (integral p(bold(y) | theta') p(theta') dif theta'), quad
    p(theta | bold(y)) prop p(bold(y) | theta) p(theta) $,
) <eq:bayes>

两个独立随机变量之和的分布由卷积给出。卷积还可以用来描述测量系统的响应：观测序列等于真实信号与仪器冲激响应的卷积再加上噪声。

#math.equation(
  $ (f * g)(t) = integral_(-oo)^oo f(tau) g(t - tau) dif tau, quad
    y(t) = (h * u)(t) + epsilon(t) $,
) <eq:convolution>

把信号从时域变换到频域后，卷积变成乘积，滤波和谱分析可以在同一个框架下处理。变换对的存在性条件和采样定理应在正文中说明，避免把离散频谱直接当成连续谱使用。

#math.equation(
  $ F(omega) = integral_(-oo)^oo f(t) e^(- upright(i) omega t) dif t, quad
    f(t) = 1/(2 pi) integral_(-oo)^oo F(omega) e^(upright(i) omega t) dif omega, quad
    f_s > 2 f_max $,
) <eq:fourier>

=== 样例计算公式

下面的分段函数用于说明条件判断在公式中的写法：不同工况对应不同的衰减规律，开关量则由区间条件给出。

#math.equation(
  // cases/mat/sqrt 属于 text style：其中的堆叠分数会被缩小，用 display(...) 强制全尺寸。
  $ eta(v) = cases(
    display(1 - v/v_0) & quad v <= v_0,
    display((v_0/v)^2) & quad v_0 < v <= 2 v_0,
    0 & quad v > 2 v_0,
  ) $,
) <eq:piecewise>

统计指标把一组观测压缩成一个数，报出时必须同时给出样本量和区间。下式给出常用的误差与拟合优度定义，用于第 4 章的模拟结果比较。

#math.equation(
  $ "RMSE" = sqrt(display(1/n) sum_(i=1)^n (y_i - hat(y)_i)^2), quad
    "MAE" = 1/n sum_(i=1)^n abs(y_i - hat(y)_i), quad
    R^2 = 1 - (sum_i (y_i - hat(y)_i)^2)/(sum_i (y_i - bar(y))^2) $,
) <eq:error-metrics>

== 公式版式与编号

本节把模板支持的公式版式集中列出，便于按内容选择：行内与行间、多行对齐、逐行编号、分段函数、
矩阵与方程组、大算符、连分数、上下标注、集合与映射、指标式、概率记号、变换对、泛函、数值与单位。
每种版式都给出适用条件，正式论文按同样的规则书写即可保持编号与间距一致。

=== 行内公式与行间公式

行内公式跟随文字基线，适合短表达式：能量换算 $E = m c^2$、无量纲数 $upright("Ma") = v \/ a$、
集合关系 $x in cal(X)$。较长的式子独立成行并自动编号，正文用标签引用：

#math.equation(
  $ integral_0^L rho A(x) dot(x)^2 dif x = 2 E_k $,
) <eq:kinetic-energy-integral>

=== 多行对齐与逐行编号

多行推导用 `&` 指定对齐点、`\` 换行，整块共享一个编号；需要逐行编号时把每行写成独立的
`math.equation`，编号会连续给出：

#math.equation(
  $ m &= rho V \
    q &= m c_p (T_2 - T_1) \
    eta &= q \/ q_"in" $,
) <eq:aligned-derivation>

#math.equation($ P_1 V_1 = n R T_1 $,) <eq:state-1>
#math.equation($ P_2 V_2 = n R T_2 $,) <eq:state-2>

=== 分段函数与条件

分段定义用 `cases`：左花括号由环境给出，条件列用 `& quad` 对齐。`cases`、`mat` 与 `sqrt`
属于 text style，其中的堆叠分数会被自动缩小，用 `display(...)` 包住表达式即可恢复全尺寸：

#math.equation(
  $ C_D(bold(v)) = cases(
    C_0 & quad norm(bold(v)) <= v_c,
    display(C_0 (v_c/norm(bold(v)))^2) & quad norm(bold(v)) > v_c,
  ) $,
) <eq:piecewise-drag>

=== 矩阵、向量与方程组

矩阵用 `mat`，括号由 `delim` 指定；分块矩阵按行分号、列逗号书写；带竖线的矩阵用于表示行列式或范数。
需要在正文中保持维数关系时，应把矩阵的阶数写在正文而不是塞进公式：

#math.equation(
  $ bold(A) = mat(delim: "(", 1, 2, 0; 0, 1, -1; 2, 0, 1), quad
    det(bold(A)) = mat(delim: "|", 1, 2, 0; 0, 1, -1; 2, 0, 1), quad
    bold(M) = mat(delim: "[", bold(A), bold(B); bold(C), bold(0)) $,
) <eq:matrix-family>

方程组用 `cases` 与对齐点表示；带条件的约束放在第二列，条件相同的一组方程共用一个编号：

#math.equation(
  $ cases(
    dot(bold(x)) = bold(A) bold(x) + bold(B) bold(u) & quad t > 0,
    bold(y) = bold(C) bold(x) & quad t >= 0,
  ) $,
) <eq:system>

=== 大算符、极限与最值

求和、连乘、积分、极限与最值都支持上下限；显示模式下上下限排在算符的上方和下方，
行内模式下自动改为右侧上下标：

#math.equation(
  $ sum_(i=1)^n w_i x_i, quad product_(k=1)^m (1 + r_k), quad integral_Omega f(bold(x)) dif bold(x) $,
) <eq:big-operators>

#math.equation(
  $ lim_(n -> oo) a_n, quad max_(bold(x) in cal(X)) f(bold(x)), quad op("arg min")_bold(theta) L(bold(theta)) $,
) <eq:limits-extrema>

=== 连分数与嵌套结构

连分数与嵌套根式写成斜杠形式：这里的层级本身已经很多，再逐层恢复全尺寸会撑高公式；
层数较多时应改用递推式表示，
并在正文说明截断项数：

#math.equation(
  $ sqrt(2) = 1 + 1 \/ (2 + 1 \/ (2 + 1 \/ (2 + dots))), quad
    phi = 1 + 1 \/ (1 + 1 \/ (1 + 1 \/ (1 + dots))) $,
) <eq:continued-fraction>

=== 上下标注

把推导中的每一项直接标注出来，比在图注里解释更直观。标注文字用引号包裹，字号自动降一级：

#math.equation(
  $ underbrace(norm(hat(bold(y)) - bold(y)), "残差") = underbrace(C_1 h^p, "格式误差") + underbrace(C_2 delta, "数据误差") $,
) <eq:annotated-sum>

=== 集合、映射与逻辑

集合与映射的记号用于定义变量的取值范围；量词与箭头用于描述连续性和收敛性，
写极限定义时应同时给出邻域半径与误差限：

#math.equation(
  $ f: cal(X) -> cal(Y), quad x |-> f(x), quad cal(A) subset.eq cal(X), quad cal(A) union cal(B), quad cal(A) inter cal(B), quad x in.not cal(A) $,
) <eq:set-mapping>

#math.equation(
  $ forall epsilon > 0, exists delta > 0: norm(bold(x) - bold(x)_0) < delta arrow.r norm(f(bold(x)) - f(bold(x)_0)) < epsilon $,
) <eq:continuity>

=== 张量与指标式

张量用上下标表示指标，重复指标按求和约定处理；矩阵乘法写成指标式后，维数是否匹配可以直接看出：

#math.equation(
  $ T^(mu nu) = eta^(mu alpha) eta^(nu beta) T_(alpha beta), quad
    (bold(A) bold(B))_(i j) = sum_(k=1)^n a_(i k) b_(k j), quad
    partial_alpha F^(alpha beta) = mu_0 J^beta $,
) <eq:tensor-index>

=== 概率与期望记号

概率与期望的记号集中在这里定义，避免同一含义在不同章节写法不一致。指示函数用带下标的 1，
它的取值只有 0 和 1 两种：

#math.equation(
  $ E[X] = integral_(-oo)^oo x p_X(x) dif x, quad
    "Cov"[X, Y] = E[(X - mu_X)(Y - mu_Y)], quad
    1_A(omega) = cases(1 & quad omega in A, 0 & quad omega in.not A) $,
) <eq:probability-notation>

=== 变换对与泛函

变换对用两行对齐写出正变换与逆变换，等号对齐后读者容易核对系数；泛函的极值条件由
Euler--Lagrange 方程给出，导数的阶数决定边界条件的个数：

#math.equation(
  $ F(omega) &= integral_(-oo)^oo f(t) e^(-upright(i) omega t) dif t \
    f(t) &= 1 \/ (2 pi) integral_(-oo)^oo F(omega) e^(upright(i) omega t) dif omega $,
) <eq:transform-pair>

#math.equation(
  $ (partial L)/(partial y) - dif \/ dif x ((partial L)/(partial y')) = 0 $,
) <eq:euler-lagrange>

=== 数值与单位

带单位和误差的数值用 `unify` 的接口书写，单位、数字和误差各自占据固定位置，不会因为手工空格
不同而在各章产生不一致的视觉结果：喷嘴出口速度 #qty("340", "m/s")，测量误差 #num("340+-5")，
有效工作区间 #qtyrange("0.20", "0.80", "mm")。

=== 公式编号与引用

公式编号按章编排（如 @eq:aligned-derivation、@eq:tensor-index），标签不变时插入新公式
只会影响后续编号，引用处自动更新。正文引用应写“由 @eq:taylor 可得”，不要写“由上式可得”，
否则插入新公式后指代会整体错位。

== 本章小结

本章示例建立了从物理假设到指标分析的基本结构，为后续章节的模型验证提供接口。
