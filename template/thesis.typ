// ============================================================
// 南京理工大学研究生学位论文 —— 空白起步文件
// ============================================================
//
// 用法：把本文件当作论文入口。
//   tinymist compile --font-path font template/thesis.typ     # 单独编译预览
//   或复制到你的工程后，改下面两处路径：
//     * #import 指向 njust-thesis/lib.typ 的相对路径
//     * #include / bibliography 指向你的章节与 .bib
//
// 依赖工程内的 font/（中文与数学字体）与 fig/logo/njust.svg（矢量校徽）；
// 缺东西时先运行 `just doctor`。真实论文的排版规则全部集中在 njust-thesis/，
// 章节文件只写内容，不要再加 #set / #v 调整间距。

#import "../njust-thesis/lib.typ": documentclass

#let thesis = documentclass(
  // 匿名送审版：按学校格式文档第 7 节，隐去封面、封二与致谢中的导师/作者信息。
  anonymous: false,
  // 双面排版会插入空白页并生成书脊页；打印送审用 true，电子版可用 false。
  twoside: true,

  info: (
    degree:        "博  士  学  位  论  文",
    page-degree:   "博士学位论文",
    // 题目：数组逐行给出（推荐）；也兼容 "第一行\\第二行" 的旧写法。
    title:         ("（论文题目第一行）", "（论文题目第二行）"),
    author:        "（作者姓名）",
    advisor:       "（导师姓名）",
    advisor-title: "（导师专业技术职务）",
    // coadvisor:       "（协同导师姓名）",
    // coadvisor-title: "（协同导师专业技术职务）",
    degree-cat:    "（工学博士）",
    major:         "（学科名称）",
    interest:      "（研究方向）",
    school:        "南京理工大学",
    // 留空则书脊使用 title；若题目过长可单独给书脊标题。
    backbone-title: "",

    // 分类号 / 密级 / UDC 按学校要求填写，没有就留空。
    classification: "",
    confidential:   "",
    udc:            "",

    // 日期两种写法都支持：datetime 会按学校写法自动格式化
    // （月精度请写 day: 1），也可以直接写 "2025年3月"。
    submit-date:    datetime(year: 2025, month: 3, day: 1),
    incover-date:   datetime(year: 2025, month: 3, day: 1),
    signature-date: datetime(year: 2025, month: 3, day: 1),

    // 英文封二
    english-degree:    "Ph.D. Dissertation",
    english-title:     "English Title of the Thesis",
    english-author:    "Author Name",
    english-advisor:   "Supervisor Name",
    // english-coadvisor:       "Co-supervisor Name",
    // english-coadvisor-title: "Prof.",
    english-institute: "Nanjing University of Science & Technology",
    english-date:      datetime(year: 2025, month: 3, day: 1),
  ),

  // 中英文摘要与关键词
  abstract-body: [
    （中文摘要正文。段落之间留空行即可，首行缩进由模板统一处理。）
  ],
  keywords: "（关键词一）、（关键词二）、（关键词三）",
  abstract-en-body: [
    (Abstract text. Leave a blank line between paragraphs.)
  ],
  keywords-en: "keyword one, keyword two",
)

// ============================================================
// 封面（外封面 / 书脊 / 中文封二 / 英文封二 / 声明页）
// ============================================================
#(thesis.cover)()

// ============================================================
// 前文：摘要 → 目录 → 图目录 → 表目录 →（可选）缩写表 / 符号表 / 字体自检
// ============================================================
#(thesis.preface)[
  #(thesis.abstract)()

  #(thesis.outline)("目  录", depth: 3)

  // 图目录与表目录是两个独立入口，按学校样例各占一页；不需要时删掉对应一行。
  #(thesis.list-of-figures)()
  #(thesis.list-of-tables)()

  // 需要时取消注释：
  // #(thesis.abbreviations)[
  //   // 缩写与中英文对照表内容（可用三列表格）
  // ]
  // #(thesis.symbols)[
  //   // 通用符号表内容
  // ]
  // #(thesis.fonts-page)()   // 字体自检页：换机器时确认字形是否齐全
]

// ============================================================
// 正文：章节文件放在任意子目录，在这里 include
// ============================================================
#(thesis.mainmatter)[
  = 绪论

  （正文从这里开始。把章节写进单独文件后改成
  `#include "chapters/ch1.typ"`，章节内的标题层级从 `=` 开始。）
]

// ============================================================
// 后文：致谢 → 参考文献 → 成果列表
// ============================================================
#(thesis.backmatter)[
  #(thesis.thanks)[
    （致谢正文。匿名送审模式下这一页不会渲染。）
  ]

  // 换成你自己的 .bib；正文里用 @key 引用，默认只列出实际引用过的条目。
  #(thesis.bibliography)("ref/ch1.bib")

  #(thesis.publications)[
    （攻读博士学位期间发表的论文与参加的科研情况。）
  ]
]
