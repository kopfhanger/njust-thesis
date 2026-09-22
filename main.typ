// ============================================================
// 南京理工大学研究生学位论文 (Typst)
// NJUST Graduate Thesis — Main Entry
// ============================================================

#import "njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  info: (
    degree:        "博  士  学  位  论  文",
    page-degree:   "博士学位论文",
    title:         ("超音速牛奶喷射与时间旅行的", "概率动力学研究"),
    author:        "ChatGPT & 深度求索",
    advisor:       "克莱登",
    advisor-title: "教授",
    coadvisor:     "布莱登",
    coadvisor-title:"教授",
    degree-cat:    "工学博士",
    major:         "机械动力工程",
    interest:      "超空间微纳机械动力调制",
    school:        "南京理工大学",
    submit-date:   datetime(year: 2024, month: 1, day: 1),
    incover-date:  datetime(year: 2024, month: 1, day: 1),
    backbone-title:"超\\音\\速\\牛\\奶\\喷\\射\\与\\时\\间\\旅\\行\\的\\概\\率\\动\\力\\学\\研\\究",

    english-degree:    "Ph.D. Dissertation",
    english-title:     "Research on the Probabilistic Dynamics of Supersonic Milk Jetting and Time Travel",
    english-author:    "ChatGPT & DeepSeek",
    english-advisor:   "Klayden",
    english-coadvisor: "Blayden",
    english-coadvisor-title: "Prof.",
    english-institute: "Nanjing University of Science & Technology",
    english-date:      datetime(year: 2024, month: 1, day: 1),

    classification: "",
    confidential:   "",
    udc:            "",
    signature-date: datetime(year: 2024, month: 1, day: 19),
  ),

  abstract-body: [
    本文研究超音速牛奶喷射与时间旅行两类问题的概率动力学描述与数值实现方法。这两类问题在物理
    机制上并不相同，但都面临同一建模困难：状态演化带有随机性，观测只能提供含噪的间接信息，
    模型本身还存在结构性偏差。现有研究多报告均值或峰值结果，对参数不确定性、数值误差与模型
    误差的分离讨论不足，也缺少统一的符号体系与验证流程。

    针对上述问题，本文把两类问题写成同一形式的状态空间模型：用状态方程描述演化过程，用观测方程
    描述测量过程，用转移概率和参数分布描述随机性，并在此基础上给出贝叶斯参数更新与区间估计的
    完整推导。为便于复用，本文把矩阵与范数、级数积分与极限、微分算子、概率分布与信息论记号等
    数学工具集中约定，并给出公式版式与编号规则。

    在数值实现方面，本文采用有限差分格式离散空间导数，比较显式与隐式时间步进的稳定性与代价，
    用网格加密实验估计收敛阶并给出 Richardson 外推结果；参数估计部分给出最小二乘、岭回归与
    参数协方差的解析形式，并用蒙特卡洛与重要性采样处理无法解析求导的情形。对于区间估计，本文
    给出不依赖解析分布的重采样算法，并用相对半宽判断重采样次数是否足够。在结果表达方面，本文
    把总体偏差分解为格式误差、数据误差和模型误差三部分，并给出一组评价指标的定义与适用条件，
    避免用单一指标概括全部结论。

    算例结果表明：所给出的数值格式在网格加密时按预期阶数收敛，参数区间估计的覆盖率与名义水平
    接近，误差指标对异常值的敏感程度与理论预期一致。这些结果用于说明验证流程的完整性与可复现性，
    不作为工程设计依据。

    本文的主要工作是把两类问题整理到同一套建模、推断与验证规则之下，并固定公式、表格、图形与
    算法在文档中的书写方式。接入真实研究内容时，可以保留状态空间描述、区间估计流程与证据组织
    结构，替换具体数据与结论。
  ],
  keywords: "超音速牛奶喷射、时间旅行、概率动力学、时空导航、逻辑变量回归、差分异质曲率",

  abstract-en-body: [
    This dissertation studies probabilistic dynamics descriptions and their numerical implementation
    for two problems: supersonic milk jetting and time travel. Although the two problems differ in
    physical mechanism, they share the same modelling difficulty: state evolution is stochastic,
    observations provide only indirect and noisy information, and the model itself carries structural
    bias. Existing studies mostly report mean or peak values, rarely separate parametric uncertainty,
    numerical error, and model error, and seldom adopt a common notation or verification procedure.

    To address this, both problems are formulated as state-space models: a state equation describes the
    evolution, an observation equation describes the measurement, and transition probabilities together
    with parameter distributions describe the randomness. On this basis, a complete derivation of
    Bayesian parameter updating and interval estimation is given. Mathematical tools—matrices and norms,
    series, integrals and limits, differential operators, probability distributions, and information
    measures—are collected in one place, together with rules for formula layout and numbering.

    For the numerical implementation, spatial derivatives are discretised with finite differences, and
    explicit and implicit time stepping are compared in terms of stability and cost. Convergence orders
    are estimated by mesh refinement and refined by Richardson extrapolation. Parameter estimation is
    presented in least-squares, ridge-regression, and covariance forms, while Monte Carlo and importance
    sampling handle cases without analytic derivatives. For interval estimation, a resampling algorithm
    that does not assume an analytic distribution is given, and the relative half-width is used to decide
    whether the resampling count is sufficient. Regarding the presentation of results, the total deviation
    is decomposed into discretisation, data, and model contributions, and a set of evaluation metrics is
    defined together with the conditions under which each is appropriate.

    Numerical examples show that the discretisation converges at the expected order under mesh refinement,
    that the coverage of the estimated intervals is close to the nominal level, and that the sensitivity
    of the metrics to outliers agrees with theoretical expectation. These results demonstrate the
    completeness and reproducibility of the verification procedure rather than providing a basis for
    engineering design.

    The main contribution is to organise the two problems under one set of modelling, inference, and
    verification rules, and to fix how formulas, tables, figures, and algorithms are laid out in the
    document. When adapting the template to a real study, the state-space description, the interval
    estimation procedure, and the evidence organisation can be retained while the data and conclusions
    are replaced.
  ],
  keywords-en: "supersonic milk jetting, time travel, probabilistic dynamics, spatio-temporal nav­igation, logistic variable regression, differential heterogeneity curvature",
)

// ============================================================
// 封面
// ============================================================

#(thesis.cover)()

// ============================================================
// 前文
// ============================================================

#(thesis.preface)[
  #(thesis.abstract)()

  #(thesis.outline)("目  录", depth: 3)

  #(thesis.list-of-figures)()

  #(thesis.list-of-tables)()

  // 按王一珉论文的正文前置结构，默认不插入缩写与中英文对照表、通用符号。
  // 需要时可取消注释，并把对应文件替换为真实论文内容。
  // #(thesis.abbreviations)[
  //   #include "chapter/abbreviations.typ"
  // ]
  //
  // #(thesis.symbols)[
  //   #include "chapter/symbols.typ"
  // ]
]

// ============================================================
// 正文
// ============================================================

#(thesis.mainmatter)[
  #include "chapter/ch1.typ"
  #include "chapter/ch2.typ"
  #include "chapter/ch3.typ"
  #include "chapter/ch4.typ"
  #include "chapter/ch5.typ"
  #include "chapter/ch6.typ"
]

// ============================================================
// 后文
// ============================================================

#(thesis.backmatter)[
  #(thesis.thanks)[
    #include "chapter/thanks.typ"
  ]

  // 示例正文目前保留了与 LaTeX 基准一致的手工上标，因此显式列出全部条目。
  // 真实论文应使用 @key 引用，并省略 full 参数，让未引用文献不进入正文参考文献表。
  #(thesis.bibliography)("ref/ch1.bib", full: true)

  #(thesis.publications)[
    #include "chapter/publications.typ"
  ]
]
