// ============================================================
// NJUST Thesis — 封面页
// ============================================================

#import "style.typ": footer-offset, header-offset, page-margin, page-paper, text-margin, 字体, 字号
#import "page-state.typ": break-to-odd, inserted-blank-page-marker

#let make-underline(width, content, bottom: 6pt) = {
  // 魏碑/黑体的字面下沿比宋体更接近基线；保留足够底部内边距，避免下划线穿过字形。
  box(width: width, stroke: (bottom: 0.5pt), inset: (bottom: bottom), content)
}

#let shifted-underline(width, content, dy: 0pt, bottom: 6pt) = box(
  width: width,
  move(dy: dy, make-underline(width, content, bottom: bottom)),
)

// LaTeX 基准使用固定字间距，不是两个普通空格；分别用于外封面和中文内封面。
#let degree-content(value, gap) = {
  if value.contains("  ") {
    let chars = ()
    for ch in value.replace("  ", "") {
      chars.push(text(ch))
    }
    stack(dir: ltr, spacing: gap, ..chars)
  } else {
    value
  }
}

// LaTeX 的 \kaibf/\songbf 会让中文使用 CJK 粗体、数字使用 Times New Roman
// 粗体。Typst 的字体回退链不能把字符串中的数字继承为同样的粗体，故将中文日期
// 拆开，显式复刻日期中的数字字形。
#let chinese-date(value) = {
  if value.contains("年") and value.contains("月") {
    let year-part = value.split("年")
    let month-part = year-part.at(1).split("月")
    text(font: 字体.roman, stroke: none, weight: "bold", year-part.at(0))
    "年"
    text(font: 字体.roman, stroke: none, weight: "bold", month-part.at(0))
    "月"
  } else {
    value
  }
}

// 中文作者名使用楷体粗体，纯拉丁作者名使用 Times New Roman 粗体。
// 不能无条件使用字体.roman，否则中文会回退到宋体，与王一珉论文
// 内、外封面中的楷体姓名视觉不一致（参考 PDF 两处封面实测均为 KaiTi）。
// size 省略时继承所在上下文，外封面需显式传入字号.小二。
#let cover-author(value, size: none) = {
  if value.matches(regex("[一-龥]")).len() > 0 {
    text(font: 字体.楷体, stroke: 字体.粗体描边, weight: "regular", size: size, value)
  } else {
    text(font: 字体.roman, stroke: none, weight: "bold", size: size, value)
  }
}

// 页脚页码：学校文档规定“页脚 20mm”；机内 15 篇南理工学位论文实测
// 页码文字下沿中位 20.0mm、上沿中位 22.9mm，而 Typst 默认位置偏低约 6mm。
// 用 move 上移 17.3pt——只改视觉位置，不改变版心与分页。
#let footer-page-number(twoside: false) = context {
  let even = twoside and calc.rem(here().page(), 2) == 0
  set text(font: 字体.宋体, stroke: none, size: 字号.小五, weight: "regular")
  align(if even { left } else { right }, move(dy: footer-offset, counter(page).display()))
}

#let finish-cover-section(twoside: false) = {
  break-to-odd(twoside: twoside)
}

// -----------------------------------------------------------
// 匿名送审 / 标题 / 日期辅助
// -----------------------------------------------------------

// 学校《博士、硕士学位论文撰写格式》第 7 节要求：匿名送审版必须隐去封面、
// 封二和致谢中所有导师与作者信息。掩码用该文档封面样例里的“×”，
// 保证任何字体下都有字形，不会静默回退。
#let anonymous-mask = "×××"

#let mask-anonymous(value, anonymous: false) = {
  if anonymous { anonymous-mask } else { value }
}

// 标题支持两种写法：数组（推荐，逐行给出）与 "第一行\\第二行" 字符串（兼容旧写法）。
#let title-lines(value) = if type(value) == array { value } else { value.split("\\") }
#let title-text(value) = if type(value) == array { value.join("") } else { value.replace("\\", "") }

// 日期既接受 datetime（按学校写法自动格式化），也接受已写好的字符串。
#let date-cn-month(value) = if type(value) == datetime {
  str(value.year()) + "年" + str(value.month()) + "月"
} else {
  value
}
#let date-cn-full(value) = if type(value) == datetime {
  str(value.year()) + " 年 " + str(value.month()) + " 月 " + str(value.day()) + " 日"
} else {
  value
}
#let date-en-month(value) = if type(value) == datetime {
  (
    (
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ).at(value.month() - 1)
      + ", "
      + str(value.year())
  )
} else {
  value
}

#let make-signature(I) = {
  set text(font: 字体.宋体, stroke: none, size: 字号.四号, weight: "regular")
  set par(first-line-indent: 0em)
  grid(
    // 对应 LaTeX 中“签名线 + 3.5cm 间隔 + 日期”，日期不能贴到右边界。
    columns: (auto, 3.5cm, 1fr),
    align(left, [研究生签名：#make-underline(3cm, "")]), [], align(left, date-cn-full(I.signature-date)),
  )
}

/// 外封面
#let make-cover(I) = {
  // LaTeX 类的封面顶部比正文多约 3mm 留白；单独设置，避免改变正文版心。
  set page(
    paper: page-paper,
    margin: (top: 33mm, bottom: page-margin.bottom, left: page-margin.left, right: page-margin.right),
    header: none,
    footer: none,
    numbering: none,
  )

  set text(font: 字体.宋体, stroke: none, size: 字号.五号, weight: "regular")
  set par(first-line-indent: 0em)

  // 还原 cls 中从正文左端 27.6pt 起笔、右侧保留 27.6pt 的头部布局。
  move(dy: 0.87pt, pad(left: 30.1pt, right: 21.3pt, grid(
    columns: (1fr, 1fr),
    align(left, [分类号 #h(2.5pt) #shifted-underline(100pt, I.classification, dy: -4.5pt)]),
    align(right, box(width: 140pt, align(right, move(
      dx: -8.5pt,
      [密级   #h(2.5pt) #shifted-underline(100pt, I.confidential, dy: -4.5pt)],
    )))),
  )))
  v(3pt)
  move(dy: -1.67pt, pad(left: 30.1pt, right: 21.3pt, grid(
    columns: (1fr, 1fr),
    // LaTeX 使用 raisebox(.15cm)+scriptsize；Typst 的 super 会再次按默认比例
    // 缩小内容，导致“注1”比基准小一号，因此显式控制字号和上移量。
    align(
      left,
      [UDC#box(move(dy: -4.25pt, text(font: 字体.宋体, size: 7.5pt, "注1"))) #h(3.0pt) #shifted-underline(95.7pt, I.udc, dy: -4.5pt)],
    ),
    align(right, make-underline(0pt, "")),
  )))
  v(0pt)

  // 图像本身不参与后续排版流；仅将标志视觉上向下校回 LaTeX 基准。
  align(center, move(dy: 8.5pt, image(I.logo-path, width: 12.5cm)))
  v(1pt)

  // LaTeX 外封面的楷体标题使用了比正文粗体更重的 AutoFakeBold；
  // 单独加粗这一行，避免封面其他楷体字段随之变粗。
  let degree-stroke = 0.92pt
  set text(font: 字体.楷体, stroke: degree-stroke, size: 32pt, weight: "regular")
  set par(first-line-indent: 0em)
  align(center, move(dy: -0.5pt, text(stroke: degree-stroke, degree-content(I.degree, 19.8pt))))
  v(1.5cm)

  // 本地 SimHei 的字面框比 LaTeX 的同字号略宽；24pt 才能复现基准的题名宽度。
  set text(font: 字体.黑体, stroke: 字体.粗体描边, size: 字号.小一, weight: "regular")
  set par(first-line-indent: 0em, leading: 0pt)
  let lines = title-lines(I.title)
  let title-block = stack(
    dir: ttb,
    spacing: 15.665pt,
    ..lines.map(line => make-underline(
      400pt,
      align(center, text(font: 字体.黑体, stroke: 字体.粗体描边, size: 字号.小一, weight: "regular", line)),
    )),
  )
  set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
  align(center, stack(
    dir: ttb,
    spacing: 5pt,
    move(dy: -1.3pt, block(title-block)),
    move(dx: -3.4pt, dy: -1.80pt, block("（题名和副题名）")),
  ))
  // 小四号占位文字的字面框比原字号更紧凑；分别校回作者块与下方资料表的基线。
  v(1.4cm + 2.035pt)

  set text(font: 字体.楷体, stroke: 字体.粗体描边, size: 字号.小二, weight: "regular")
  set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
  align(center, stack(
    dir: ttb,
    spacing: 0pt,
    shifted-underline(
      180pt,
      align(center, move(dy: 8.2pt, move(dx: -2.25pt, dy: -2.3pt, cover-author(
        mask-anonymous(I.author, anonymous: I.anonymous),
        size: 字号.小二,
      )))),
      dy: -8.2pt,
      bottom: 8.5pt,
    ),
    move(dx: -3.4pt, block("（作者姓名）")),
  ))
  v(1.3cm + 1.46pt)

  set text(font: 字体.宋体, stroke: none, size: 字号.四号, weight: "regular")
  set par(first-line-indent: 0em)
  let table-rule(body, shift: -4pt, height: 23.4pt) = box(
    width: 299pt,
    height: height,
    shifted-underline(299pt, align(center, move(dy: -shift, body)), dy: shift),
  )
  let trows = ()
  trows.push((
    text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "指导教师姓名"),
    table-rule(
      [
        #move(dy: -1.43pt, block([
          #text(font: 字体.楷体, stroke: 字体.粗体描边, size: 字号.三号, weight: "regular", mask-anonymous(
            I.advisor,
            anonymous: I.anonymous,
          ))
          #h(6.5pt)
          #text(font: 字体.楷体, stroke: 字体.粗体描边, size: 字号.四号, weight: "regular", I.advisor-title)
        ]))
      ],
      height: 18pt,
    ),
  ))
  // LaTeX 类始终保留协同导师行；为空时保留空横线，填写真实协同导师后
  // 复用同一行的字号和字重，不让真实论文的字段被静默丢弃。
  let coadvisor-body = if I.coadvisor == "" and I.coadvisor-title == "" {
    []
  } else {
    [
      #text(font: 字体.楷体, stroke: 字体.粗体描边, size: 字号.三号, weight: "regular", mask-anonymous(
        I.coadvisor,
        anonymous: I.anonymous,
      ))
      #h(6.5pt)
      #text(font: 字体.楷体, stroke: 字体.粗体描边, size: 字号.四号, weight: "regular", I.coadvisor-title)
    ]
  }
  // 协同导师槽使用独立的固定高度盒。横线由槽位底部直接放置，
  // 不再让 `make-underline` 根据内容高度计算位置。
  let coadvisor-slot = box(width: 299pt, height: 28.8pt, {
    // -12pt 将线校回原单导师版本的预留横线位置。
    place(bottom + left, dy: -12pt, line(length: 299pt, stroke: 0.5pt))
    align(center, move(dy: 2pt, coadvisor-body))
  })
  trows.push((
    text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", ""),
    coadvisor-slot,
  ))
  trows.push((
    text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", [学#h(9.5pt)位#h(9.5pt)类#h(9.5pt)别]),
    table-rule(move(dy: -1.43pt, text(
      font: 字体.楷体,
      stroke: 字体.粗体描边,
      size: 字号.三号,
      weight: "regular",
      I.degree-cat,
    ))),
  ))
  trows.push((
    text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", [学#h(9.5pt)科#h(9.5pt)名#h(9.5pt)称]),
    table-rule(move(dy: -1.43pt, text(
      font: 字体.楷体,
      stroke: 字体.粗体描边,
      size: 字号.三号,
      weight: "regular",
      I.major,
    ))),
  ))
  trows.push((
    text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", [研#h(9.5pt)究#h(9.5pt)方#h(9.5pt)向]),
    table-rule(move(dy: -1.43pt, text(
      font: 字体.楷体,
      stroke: 字体.粗体描边,
      size: 字号.三号,
      weight: "regular",
      I.interest,
    ))),
  ))
  trows.push((
    text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "论文提交时间"),
    table-rule(move(dy: -1.43pt, text(
      font: 字体.楷体,
      stroke: 字体.粗体描边,
      size: 字号.三号,
      weight: "regular",
      chinese-date(date-cn-month(I.submit-date)),
    ))),
  ))
  v(2.8pt)
  align(center, grid(
    columns: (85.2pt, 299pt),
    column-gutter: 0.8pt,
    align: (left, left),
    ..trows.flatten(),
  ))
  v(15.7pt)
  set text(font: 字体.宋体, stroke: none, size: 字号.五号, weight: "regular")
  set par(first-line-indent: 0em)
  pad(left: 22pt, align(left, [注1: 注明《国际十进分类法 UDC》的类号]))
}

/// 书脊
#let make-backbone(I, twoside: false) = {
  if twoside {
    pagebreak()
    set page(paper: page-paper, margin: page-margin, header: none, footer: none, numbering: none)
    set text(font: 字体.楷体, stroke: 字体.粗体描边, size: 字号.小四, weight: "regular")
    // 每个字符单独换行；LaTeX 基准的基线间隔约为 18.7pt。
    set par(first-line-indent: 0em, leading: 10.5pt)
    set align(center)
    let bt = if I.backbone-title != "" { I.backbone-title } else { I.title }
    v(8pt)
    move(dy: 0.4pt, block({
      for ch in title-text(bt) { text(ch + "\n") }
    }))
    v(8fr)
    // 基准类在标题与校名之间使用独立的 stretch；校名相对 Typst 的
    // 书脊字符流还需再上移约 25pt 才能落在同一基线。
    v(-53pt)
    move(dy: -22.5pt, block({
      for ch in "南京理工大学" { text(ch + "\n") }
    }))
    v(1fr)
    finish-cover-section(twoside: twoside)
  }
}

/// 中文内封面
#let make-incover(I, twoside: false) = {
  set page(paper: page-paper, margin: page-margin, header: none, footer: none, numbering: none)
  set align(center)
  set par(first-line-indent: 0em, leading: 0pt)

  set text(font: 字体.魏碑, size: 字号.小二, weight: "regular")
  // 多导师页仍沿用学校样例的固定纵向锚点；导师数量只占用预留槽位。
  v(37pt)
  move(dy: 3.65pt, block(degree-content(I.degree, 10.48pt)))
  v(1.9cm)
  v(10pt)

  set text(font: 字体.黑体, stroke: 字体.粗体描边, size: 字号.二号, weight: "regular")
  let lines = title-lines(I.title)
  stack(dir: ttb, spacing: 19pt, ..lines.map(line => block(line)))
  v(2.85cm)

  set text(font: 字体.楷体, stroke: 字体.粗体描边, size: 字号.小二, weight: "regular")
  // 源 LaTeX 的标签是“作\hspace{1em}\hspace{1em}者:”，普通空格会被 Typst 合并。
  // 英文作者名单独锁定 Times New Roman 粗体；中文作者由 cover-author
  // 切换到与“作者”标签一致的楷体粗体。
  // LaTeX 的 tabular 单元格不会把作者拆成两行；使用不可断行的 box
  // 保留“作  者: ChatGPT”在同一基线上。
  move(dx: -7.5pt, box([
    作#h(36pt)者:#h(8.5pt)
    #cover-author(mask-anonymous(I.author, anonymous: I.anonymous), size: 字号.小二)
  ]))
  v(11pt)
  // 多导师格式：标签只出现一次，后续导师与第一位导师姓名对齐。
  // 第二行始终预留固定高度，因此增加/删除协同导师不会移动学校和日期。
  let advisor-prefix = box(width: 89pt, align(left, [指导教师：]))
  let advisor-line(name, title, show-prefix: true) = {
    let prefix = if show-prefix { advisor-prefix } else { box(width: 89pt) }
    [
      #prefix
      #mask-anonymous(name, anonymous: I.anonymous)
      #h(4pt)
      #text(size: 字号.三号, weight: "regular", title)
    ]
  }
  move(dx: 0.5pt, stack(
    dir: ttb,
    spacing: 5pt,
    block(advisor-line(I.advisor, I.advisor-title)),
    if I.coadvisor != "" {
      move(dy: 6pt, block(advisor-line(I.coadvisor, I.coadvisor-title, show-prefix: false)))
    } else {
      box(height: 18pt)
    },
  ))
  v(2fr)

  set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小二, weight: "regular")
  move(dy: -12.55pt, block(I.school))
  v(-5pt)
  move(dy: -18.25pt, block(chinese-date(date-cn-month(I.incover-date))))
  v(41pt)
  finish-cover-section(twoside: twoside)
}

/// 英文内封面
#let make-english-incover(I, twoside: false) = {
  set page(paper: page-paper, margin: page-margin, header: none, footer: none, numbering: none)
  set align(center)
  set par(first-line-indent: 0em, leading: 0pt)

  // LaTeX 英文内封面在页面顶部使用 -18pt 的补偿；本地字体的字面框不同，
  // 这里用显式留白把首行位置校回基准页，再由后续固定间距保持结构一致。
  v(60pt)

  set text(font: 字体.roman, size: 字号.小二, style: "normal", weight: "regular")
  block(I.english-degree)
  v(42pt)

  set text(font: 字体.roman, stroke: none, size: 字号.二号, weight: "bold", style: "normal")
  set par(first-line-indent: 0em, leading: 10.5pt)
  block(I.english-title)
  v(44pt)

  set par(first-line-indent: 0em, leading: 14pt)
  set text(font: 字体.roman, stroke: none, size: 字号.小二, style: "italic", weight: "regular")
  block("By")
  v(-14pt)
  set text(font: 字体.roman, stroke: none, size: 字号.小二, weight: "bold", style: "italic")
  block(mask-anonymous(I.english-author, anonymous: I.anonymous))
  v(46pt)

  set text(font: 字体.roman, stroke: none, size: 字号.小二, style: "italic", weight: "regular")
  // 英文多导师格式与学校样例一致：第二行不重复 Supervised by，且两行使用固定行距。
  // 第一列固定为“Supervised by”的宽度，使两行的职称列严格对齐；
  // 职称保持常规斜体，姓名单独使用粗斜体。
  let supervisor-prefix = box(width: 105pt, align(right, [Supervised by]))
  let supervisor-line(name, title, show-prefix: true) = [
    #if show-prefix { supervisor-prefix } else { box(width: 105pt) }
    #text(font: 字体.roman, stroke: none, weight: "regular", style: "italic", title)
    #h(12pt)
    #text(font: 字体.roman, stroke: none, weight: "bold", style: "italic", mask-anonymous(name, anonymous: I.anonymous))
  ]
  stack(
    dir: ttb,
    spacing: 4pt,
    block(supervisor-line(I.english-advisor, "Prof.")),
    if I.english-coadvisor != "" {
      move(dy: 3.5pt, block(supervisor-line(I.english-coadvisor, I.english-coadvisor-title, show-prefix: false)))
    } else {
      box(height: 16pt)
    },
  )
  v(2fr)
  v(-6.5pt)

  set text(font: 字体.roman, stroke: none, size: 字号.小二, style: "normal", weight: "regular")
  move(dy: -20.6pt, block(I.english-institute))
  v(-14pt)
  move(dy: -20.6pt, block(date-en-month(I.english-date)))
  v(85pt)
  finish-cover-section(twoside: twoside)
}

/// 声明页
#let make-statement(I, twoside: false) = {
  set page(paper: page-paper, margin: page-margin, header: none, footer: none, numbering: none)
  set par(first-line-indent: 0em)

  v(39pt)
  set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.三号, weight: "regular")
  align(center, block([声#h(15pt)明]))
  v(1.1cm)

  set text(font: 字体.宋体, stroke: none, size: 字号.四号, weight: "regular")
  set par(
    leading: 17.3pt,
    first-line-indent: (amount: 2em, all: true),
    justify: true,
  )
  align(left, block(width: 100%, [#I.statement-text]))
  v(1.4cm)

  make-signature(I)
  v(3.85cm)

  set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.三号, weight: "regular")
  align(center, block("学位论文使用授权声明"))
  v(1.1cm)

  set text(font: 字体.宋体, stroke: none, size: 字号.四号, weight: "regular")
  set par(
    leading: 17.3pt,
    first-line-indent: (amount: 2em, all: true),
    justify: true,
  )
  align(left, block(width: 100%, [#I.accredit-text]))
  v(1.35cm)
  make-signature(I)
  finish-cover-section(twoside: twoside)
}

#let preface-footer(twoside: false) = context {
  let current-page = here().page()
  let blank = query(selector(metadata.where(value: inserted-blank-page-marker))).any(it => (
    it.location().page() == current-page + 1
  ))
  if not blank {
    footer-page-number(twoside: twoside)
  }
}

#let set-preface-page(twoside: false, header-degree: "博士学位论文", thesis-title: "") = {
  set page(
    paper: page-paper,
    // 目录、图/表目录、缩写表等文字页与正文使用同一版心。
    margin: text-margin,
    binding: left,
    header: context {
      let even = twoside and calc.rem(here().page(), 2) == 0
      let current-page = here().page()
      let blank = query(selector(metadata.where(value: inserted-blank-page-marker))).any(it => (
        it.location().page() == current-page + 1
      ))
      if not blank {
        set text(font: 字体.宋体, stroke: none, size: 字号.小五, weight: "regular")
        set par(first-line-indent: 0em)
        move(dy: header-offset, stack(
          dir: ttb,
          spacing: 3pt,
          grid(
            columns: (1fr, 1fr),
            align(left, if even { thesis-title } else { header-degree }),
            align(right, if even { header-degree } else { thesis-title }),
          ),
          line(length: 100%, stroke: 0.5pt),
        ))
      }
    },
    footer: preface-footer(twoside: twoside),
  )
  show strong: it => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", it)
}

#let preface-title(title, font: 字体.宋体, size: 字号.三号, stroke: 字体.粗体描边) = {
  // LaTeX 的 chapter* 在页眉下保留约 30pt 的章标题上方留白。
  v(30.5pt)
  // 目录条目需要把显式字距作为一个不可拆分的行内盒；否则 outline
  // 会把“摘  要/目  录”等标题误判为占满整行的块，导致点线换到下一行。
  let display-title = degree-content(title, 32pt)
  // LaTeX 目录中两个汉字的字距略小于页面标题；单独校准目录锚点，
  // 不改变摘要/目录页上实际显示的标题。
  let outline-title = box(degree-content(title, 28pt))
  // Typst 默认 heading 会把字号放大到 1.4em；LaTeX 的前文标题实际就是
  // 三号（16pt），因此只保留 heading 的目录锚点，显示由这里完全接管。
  show heading: it => {
    set text(font: font, stroke: stroke, size: size, weight: "bold", style: "normal")
    set par(first-line-indent: 0em)
    align(center, block(display-title))
  }
  heading(
    level: 1,
    numbering: none,
    outlined: true,
    // 把“摘  要 / 目  录 / 致  谢 / 附  录”的显式字距同时带入目录条目。
    outline-title,
  )
}

#let make-abstract(
  I,
  twoside: false,
  header-degree: "博士学位论文",
  thesis-title: "",
) = {
  set-preface-page(
    twoside: twoside,
    header-degree: header-degree,
    thesis-title: thesis-title,
  )
  show strong: it => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", it)
  preface-title("摘  要")
  v(19.8pt)
  set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
  set par(
    first-line-indent: (amount: 2em, all: true),
    leading: 10.5pt,
    spacing: 10.5pt,
    justify: true,
  )
  [#I.abstract-body]
  if I.keywords != "" {
    v(9.5pt)
    set par(first-line-indent: 0em)
    set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小四, weight: "regular")
    text("关键词：")
    set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
    text(I.keywords)
  }

  finish-cover-section(twoside: twoside)
  set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.三号, weight: "regular")
  preface-title("Abstract", font: 字体.roman, stroke: none)
  v(19.8pt)
  set text(font: 字体.roman, stroke: none, size: 字号.小四, weight: "regular", lang: "en")
  // LaTeX 的英文摘要没有额外的段间距，行距约为 18.72pt。
  set par(
    first-line-indent: (amount: 2em, all: true),
    leading: 10.4pt,
    spacing: 10.2pt,
    justify: true,
  )
  [#I.abstract-en-body]
  if I.keywords-en != "" {
    v(10.8pt)
    set par(first-line-indent: 0em)
    set text(font: 字体.roman, stroke: none, size: 字号.小四, weight: "bold")
    text("Keywords: ")
    set text(font: 字体.roman, stroke: none, size: 字号.小四, weight: "regular")
    text(I.keywords-en)
  }
  // 这里不再重复 set-preface-page：中途 `set page` 会让 Typst 立刻换页，
  // 使分页起点标记落到插入的空白页上，判据就分不清“空白页”和“正文页”。
  // 前置页眉页脚在 make-abstract 开头已经设置，目录页由 outline 自行设置。
  finish-cover-section(twoside: twoside)
}
