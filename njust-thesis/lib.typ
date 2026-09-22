// ============================================================
// NJUST Thesis — 主库文件
// 南京理工大学研究生学位论文模板
// ============================================================

#import "style.typ": 字号, 字体, page-paper, page-margin, text-margin, header-offset
#import "cover.typ": *
#import "page-state.typ": break-to-odd, inserted-blank-page-marker

#let clear-page() = { pagebreak(weak: true) }
#let clear-to-odd(twoside: false) = break-to-odd(twoside: twoside)

// 获取当前页面的一级标题：优先使用本页标题，否则回退到此前最近的标题。
#let active-heading(level: 1) = {
  let loc = here()
  let current = query(selector(heading.where(level: level)).after(loc))
    .filter(it => it.location().page() == loc.page())
  let previous = query(selector(heading.where(level: level)).before(loc))
  if current.len() > 0 {
    current.first()
  } else if previous.len() > 0 {
    previous.last()
  } else {
    none
  }
}

#let heading-display(it) = {
  if it == none {
    ""
  } else {
    let number = if it.has("numbering") and it.numbering != none {
      numbering(it.numbering, ..counter(heading).at(it.location()))
    } else {
      []
    }
    number + [ ] + it.body
  }
}

// -----------------------------------------------------------
// 章节级 API（供章节文件与第三方子图包调用；核心内部也使用）
// -----------------------------------------------------------

/// 将当前一级标题编号与局部元素编号组合为“章.序号”。
///
/// 这是模板对章节公开的编号入口：公式、图和子图都通过它取得章节作用域的编号，
/// 因此编号会随章节自动重置。典型用法（图/子图）：
///
/// ```typst
/// #import "../njust-thesis/lib.typ": chapter-figure-numbering
/// #figure(..., numbering: (..nums) => chapter-figure-numbering("1.1", ..nums), supplement: [图])
/// ```
///
/// 与 `subpar` 等子图包配合时，把本函数直接传给父图的 `numbering`，
/// 并把 `supplement` 设为 `[图]`，避免包默认的英文 `Figure`。
/// 把宽度超过可用宽度的内容整体等比缩小，使其不溢出当前栏宽。
///
/// 用于把宽画布（CeTZ/Fletcher 上游示例）放进子图格或窄栏：宽度由当前可用区域
/// 实测得到，而不是在章节里手写缩放百分比——手算的百分比会随栏宽、图内注释宽度
/// 变化而溢出。宽度不足时不放大，保持图内文字与正文的相对大小。
///
/// ```typst
/// #import "../njust-thesis/lib.typ": fit-width
/// #figure(fit-width(include "../third-party/cetz/gallery/tree.typ"))
/// ```
#let fit-width(content, max-width: 100%, reflow: true) = layout(size => {
  let limit = if type(max-width) == ratio { size.width * max-width } else { max-width }
  let natural = measure(content).width
  if natural > limit and natural > 0pt {
    let factor = limit / natural
    scale(x: factor * 100%, y: factor * 100%, origin: top + left, reflow: reflow, content)
  } else {
    content
  }
})

/// 将上游 CeTZ/Fletcher 示例按官方默认字号放入当前栏宽。
///
/// 上游示例通常以 10pt 为默认文本字号；直接在正文 12.07pt 上下文中 include
/// 会让节点和坐标标注比官方示例大，再由窄栏缩放一次，导致 2.1(b,d)、3.1(d)
/// 的线宽、留白和文字比例发生变化。这个封装只改变示例的局部上下文，不改变
/// 图题、编号、正文段距或模板字体契约。
#let official-example(content) = {
  set text(font: 字体.roman, size: 10pt)
  // 官方示例中的数学标签是图内文字，不应继承论文正文的公式编号。
  set math.equation(block: false, numbering: none)
  // 同时覆盖正文公式规则带来的 12pt 数学字号，使 CeTZ tree.typ
  // 的圆圈数字与 Expression 标签保持同一官方图内字号。
  show math.equation: it => {
    set text(font: "TeX Gyre Termes Math", size: 10pt)
    it
  }
  // 子图容器需要重新排版以适应栏宽；容易受自动形状影响的 Fletcher
  // 快照在源文件中显式固定了官方输出所用的节点形状。
  fit-width(content, reflow: true)
}

/// 三线表表头单元格：宋体加粗。
///
/// 学校格式文档要求图表内文字用五号宋体，表头另加粗以区分层次。示例中的
/// 三线表统一用 `th(...)` 写表头，线型固定为 1pt 顶线、0.5pt 表头线、1pt 底线，
/// 列宽用 `fr` 比例而不是写死的 pt，需要转页时用 `table.header(...)` 重复表头。
///
/// ```typst
/// #import "../njust-thesis/lib.typ": th
/// #table(columns: (1fr, 2fr), table.hline(stroke: 1pt),
///   th[符号], th[含义], table.hline(stroke: 0.5pt), [$v_0$], [出口速度],
///   table.hline(stroke: 1pt))
/// ```
#let th(body) = text(
  font: 字体.宋体,
  stroke: 字体.粗体描边,
  weight: "regular",
  body,
)

/// 表注放在表格下方，沿表格左边界对齐，并保持与下横线的紧凑距离。
///
/// 表头不再在这里强制居中，而是继承 `table(align: ...)` 的列对齐规则；
/// 因而长文本列、数值列和单位列的表头分别与表体保持一致。
#let table-note(body) = {
  v(2pt)
  block(width: 100%)[
    #set text(font: 字体.宋体, size: 字号.小五, weight: "regular")
    #set par(first-line-indent: 0em, leading: 0pt, spacing: 0pt)
    #align(left, body)
  ]
}

/// 将不需要铺满版心的表格整体收窄并居中。
///
/// 版心较宽的参数表、符号表和小型结果表不应因为三线表横线过长而顶到左右边界。
/// 表体仍在一个明确的宽度约束内排版，长文本会在表内换行；表注若放在同一内容块中，
/// 也会自然地与表格左边界对齐。
///
/// ```typst
/// #figure(compact-table(table(...)), caption: [参数表])
/// ```
#let compact-table(body, width: 80%) = align(center, block(width: width, body))

/// 子图题注统一使用五号宋体，较正文小一号；`num` 已由 `subpar` 实现为 `a)`、
/// `b)` 等已编号内容，不能再次手动添加编号。
#let subfigure-caption(num, caption) = {
  set text(font: 字体.宋体, stroke: none, size: 字号.五号, weight: "regular")
  set par(first-line-indent: 0em, leading: 0pt, spacing: 0pt)
  align(center, num + [ ] + caption.body)
}

#let chapter-figure-numbering(pattern, ..nums) = {
  let chapter = counter(heading).at(here()).first()
  numbering(pattern, chapter, ..nums)
}

// -----------------------------------------------------------
// 前文布局
// -----------------------------------------------------------

#let preface-body(
  it,
  twoside: false,
  header-degree: "博士学位论文",
  thesis-title: "",
) = {
  set page(
    paper: page-paper,
    margin: text-margin,
    binding: left,
    numbering: "I",
    header: context {
      let current-page = here().page()
      let blank = query(selector(metadata.where(value: inserted-blank-page-marker)))
        .any(it => it.location().page() == current-page + 1)
      if not blank and calc.rem(here().page(), 2) == 1 {
        set text(font: 字体.宋体, stroke: none, size: 字号.小五, weight: "regular")
        set par(first-line-indent: 0em)
        move(dy: header-offset, stack(
          dir: ttb,
          spacing: 3pt,
          grid(
            columns: (1fr, 1fr),
            align(left, header-degree),
            align(right, thesis-title),
          ),
          line(length: 100%, stroke: 0.5pt),
        ))
      }
    },
    footer: context {
      let current-page = here().page()
      let blank = query(selector(metadata.where(value: inserted-blank-page-marker)))
        .any(it => it.location().page() == current-page + 1)
      if not blank {
        footer-page-number(twoside: twoside)
      }
    },
  )
  counter(page).update(1)
  counter(heading).update(0)
  set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
  show strong: it => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", it)
  set par(first-line-indent: 2em, leading: 10.5pt, justify: true)
  it
}

// -----------------------------------------------------------
// 正文布局
// -----------------------------------------------------------

#let mainmatter-header(
  twoside: false,
  header-degree: "博士学位论文",
  thesis-title: "",
) = context {
  let current-page = here().page()
  let blank = query(selector(metadata.where(value: inserted-blank-page-marker)))
    .any(it => it.location().page() == current-page + 1)
  if not blank {
    let even = twoside and calc.rem(current-page, 2) == 0
    let chapter = heading-display(active-heading(level: 1))
    set text(font: 字体.宋体, stroke: none, size: 字号.小五, weight: "regular")
    set par(first-line-indent: 0em)
    move(dy: header-offset, stack(
      dir: ttb,
      spacing: 3pt,
      grid(
        columns: (1fr, 1fr),
        align(left, if even { chapter } else { header-degree }),
        align(right, if even { header-degree } else { thesis-title }),
      ),
      line(length: 100%, stroke: 0.5pt),
    ))
  } else {
    []
  }
}

#let mainmatter-footer(twoside: false) = context {
  let current-page = here().page()
  let blank = query(selector(metadata.where(value: inserted-blank-page-marker)))
    .any(it => it.location().page() == current-page + 1)
  if not blank {
    footer-page-number(twoside: twoside)
  } else {
    []
  }
}

#let start-mainmatter-chapter(
  twoside: false,
) = {
  clear-to-odd(twoside: twoside)
}

#let mainmatter-body(
  it,
  twoside: false,
  header-degree: "博士学位论文",
  thesis-title: "",
) = {
  set page(
    paper: page-paper,
    margin: text-margin,
    binding: left,
    numbering: "1",
    header: mainmatter-header(
      twoside: twoside,
      header-degree: header-degree,
      thesis-title: thesis-title,
    ),
    footer: mainmatter-footer(twoside: twoside),
  )
  counter(page).update(1)
  counter(heading).update(0)

  set math.equation(
    block: true,
    // Termes Math 的字面框与 MathType 公式编号垂直中心基本一致，不再
    // 沿用 NewCM 时代的 4.9pt 下移补偿。
    numbering: (..nums) => move(dy: 0pt, chapter-figure-numbering("(1.1)", ..nums)),
    supplement: "式",
  )
  // 王一珉论文的 LaTeX 模板设置了 `\arraystretch=1.3`，因此 cases
  // 内部各行不会采用 Typst 默认的紧凑间距。把这个规则放在正文入口，
  // 保证第 1--6 章以及用户替换后的真实公式使用同一套分段公式行距。
  // 该设置只影响大括号分段公式，不改变普通单行公式或公式块上下留白。
  set math.cases(gap: 0.8em)
  // 王一珉论文的 MathType 公式采用 Times 风格数学字形；本地 TeX Gyre
  // Termes Math 提供相近的字形和完整数学度量，避免把数学字体误当正文 TNR。
  // 所有正文行间公式统一从这里获得上下间距。不要在章节文件中再用
  // `#v(...)` 包裹公式：那种写法只对示例章节有效，替换成真实内容后
  // 很容易造成不同章节的公式、图表和正文节奏不一致。
  show math.equation: it => {
    // 按王一珉论文实测的全文规则统一设置：正文末行到公式字面约 7pt，
    // 公式块下方保留统一的 13pt。下方值按多行公式、cases 和编号公式
    // 的完整字面框校准，避免不同公式结构侵入下一行正文。
    set block(above: 10pt, below: 13pt)
    set text(font: "TeX Gyre Termes Math", size: 12pt)
    it
  }
  // 公式可能在引用之后出现；引用时必须回到公式自身的位置取编号。
  show ref: it => {
    let equation = math.equation
    let element = it.element
    if element == none or element.func() != equation {
      return it
    }
    // 参考王一珉论文使用“式(2.1)”且不允许“式”和编号跨行。
    let chapter = counter(heading).at(element.location()).first()
    let number = numbering("(1.1)", chapter, ..counter(equation).at(element.location()))
    link(
      element.location(),
      box([式#number]),
    )
  }
  show figure.where(kind: image): set figure(
    numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
    supplement: "图",
  )
  show figure.where(kind: table): set figure(
    numbering: (..nums) => chapter-figure-numbering("1.1", ..nums),
    supplement: "表",
  )
  set figure.caption(separator: " ")
  show figure.where(kind: table): set figure.caption(position: top)
  // 王一珉论文中，图面到图题的可见距离约为 6.5pt；在本地字体度量
  // 下用 8pt 的 figure gap 得到相同的字面间距。表题到表头也采用同一
  // 规则，实测约为 12pt。
  set figure(gap: 8pt)
  // 题注后接正文/标题的距离由 figure 统一提供，避免章节文件分别补
  // 空白造成真实论文换入内容后排版节奏改变。
  show figure: it => {
    // 普通图片前的正文末行到图面约 8pt；表格的题注位于表格上方，
    // 其前置距离按王一珉论文实测的约 12–13pt 单独增加。
    let above = if it.kind == table { 16pt } else { 10pt }
    set block(above: above, below: 12pt)
    it
    // block(above/below) 对题注后的下一个元素并不总能形成可见留白；
    // 这里显式补足王一珉论文中题注到下一行正文约 16pt 的节奏。
    v(6.5pt)
  }

  // heading 编号：1, 1.1, 1.1.1, 1.1.1.1
  set heading(numbering: (..nums) => {
    let depth = nums.pos().len()
    if depth == 1 { numbering("1", ..nums) + h(10pt) }
    else if depth == 2 { numbering("1.1", ..nums) + h(10pt) }
    else if depth == 3 { numbering("1.1.1", ..nums) + h(8pt) }
    else { numbering("1.1.1.1", ..nums) + h(8pt) }
  })

  // 只在正文标题的可见编号上复刻 LaTeX 的数字字重：一级至三级标题的编号
  // 属于 \bfseries，四级标题编号保持普通体；底层 numbering 不改，从而页眉和
  // 目录仍使用原有的普通数字度量。
  let visible-heading = it => {
    if it.numbering == none {
      it.body
    } else {
      let values = counter(heading).at(it.location())
      let depth = values.len()
      let raw-number = numbering(it.numbering, ..values)
      let gap = if depth <= 2 { 10pt } else { 8pt }
      let number = if depth <= 3 {
        text(font: 字体.roman, stroke: none, weight: "bold", raw-number)
      } else {
        raw-number
      }
      number + h(gap) + it.body
    }
  }

  // 正文默认
  set text(font: 字体.宋体, stroke: none, size: 字号.正文, weight: "regular")
  show strong: it => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", it)
  // 代码示例也必须使用模板字体回退链；模板不依赖宿主机的 DejaVu Sans Mono
  // 或其他不可复现的默认等宽字体。
  show raw: it => {
    set text(font: 字体.宋体, stroke: none)
    it
  }
  // 以王一珉论文正文实测的约 20pt 基线间距为基准；本地 SimSun 的
  // 字面宽度略不同，但上下文的垂直节奏统一由这里控制。
  // 王一珉论文的段落分隔按当前正文节奏固定为 12.5pt；Typst 默认段间距
  // 更大，会在正文中每经过一个段落逐渐累积到数毫米的漂移。
  set par(
    leading: 11.75pt,
    spacing: 12.5pt,
    first-line-indent: (amount: 2em, all: true),
    justify: true,
  )
  // 列表和表格也是正文的一部分，默认规则必须对所有章节一致。
  set list(indent: 19.7pt)
  // 王一珉论文正文表格的连续行基线约为 22.7pt；在本地字体度量下，
  // y=8pt 与该值最接近，同时避免表格把后续正文无谓推到下一页。
  // 三线表默认所有单元格水平、垂直居中；局部表格只有在确有语义需要时才覆盖水平对齐。
  set table(align: center + horizon, inset: (x: 1pt, y: 8pt), stroke: none)
  show table: it => {
    // 学校《博士、硕士学位论文撰写格式》：表说用五号宋体在表上，图表内的字体用五号宋体。
    // 因此表内文字统一为五号（比正文小四小一号）；行高由全局 inset 统一控制，
    // 而不是由章节文件分别补空白。
    set text(font: 字体.宋体, stroke: none, size: 字号.五号, weight: "regular")
    it
  }

  show heading: it => {
    if it.level == 1 {
      counter(math.equation).update(0)
      counter(figure.where(kind: image)).update(0)
      counter(figure.where(kind: table)).update(0)
      start-mainmatter-chapter(
        twoside: twoside,
      )
      v(32pt)
      set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小三, weight: "regular")
      set par(first-line-indent: 0em, leading: 0pt)
      block(above: 50pt, below: 31pt, align(left, visible-heading(it)))
    } else if it.level == 2 {
      set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.四号, weight: "regular")
      set par(first-line-indent: 0em, leading: 0pt)
      block(above: 22pt, below: 24pt, align(left, visible-heading(it)))
    } else if it.level == 3 {
      set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小四, weight: "regular")
      set par(first-line-indent: 0em, leading: 0pt)
      block(above: 17.5pt, below: 18pt, align(left, visible-heading(it)))
    } else {
      set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
      set par(first-line-indent: 0em, leading: 0pt)
      block(inset: (left: 24pt), above: 17.5pt, below: 18pt, align(left, visible-heading(it)))
    }
  }

  show figure.caption: it => {
    set text(font: 字体.宋体, size: 字号.五号, weight: "regular")
    set par(first-line-indent: 0em, leading: 0pt, spacing: 0pt)
    align(center, it)
  }

  // 算法浮动体：题注置顶并左对齐加粗。机内其他学校（国防科技大学、中国地质大学）
  // 的算法块都是“算法 N 名称”左对齐在框上方，居中会被读成图题。
  // 章节里用 `figure(kind: "algorithm", supplement: "算法", ...)` 即可，
  // 框内的输入/输出行、线型与行号格式由章节按内容给出。
  show figure.where(kind: "algorithm"): it => {
    set figure.caption(position: top)
    show figure.caption: cit => {
      set text(font: 字体.宋体, size: 字号.五号, weight: "regular",
        stroke: 字体.粗体描边)
      align(left, cit)
    }
    it
  }

  it
}

// -----------------------------------------------------------
// 后文布局
// -----------------------------------------------------------

#let backmatter-header(
  twoside: false,
  header-degree: "博士学位论文",
  thesis-title: "",
)= context {
  let even = twoside and calc.rem(here().page(), 2) == 0
  set text(font: 字体.宋体, size: 字号.小五, weight: "regular")
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

#let backmatter-footer(twoside: false) = footer-page-number(twoside: twoside)

// 后文标题既要保持 LaTeX 的版式，也要进入目录；这里直接使用带目录锚点的
// heading，并局部覆盖其显示方式，避免 Typst 默认标题样式改变后文坐标。
#let backmatter-title(title, top: 30pt, outlined: true) = {
  v(top)
  show heading: it => {
    set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小三, weight: "regular")
    set par(first-line-indent: 0em)
    align(center, block(it.body))
  }
  heading(level: 1, numbering: none, outlined: outlined, title)
  v(20pt)
}

#let set-backmatter-page(
  twoside: false,
  header-degree: "博士学位论文",
  thesis-title: "",
) = {
  set page(
    paper: page-paper,
    margin: text-margin,
    binding: left,
    header: backmatter-header(
      twoside: twoside,
      header-degree: header-degree,
      thesis-title: thesis-title,
    ),
    footer: backmatter-footer(twoside: twoside),
  )
}

#let backmatter-body(
  it,
  twoside: false,
  header-degree: "博士学位论文",
  thesis-title: "",
) = {
  clear-to-odd(twoside: twoside)
  set-backmatter-page(
    twoside: twoside,
    header-degree: header-degree,
    thesis-title: thesis-title,
  )
  set heading(numbering: none)
  show strong: it => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", it)
  it
}

// -----------------------------------------------------------
// 模板入口
// -----------------------------------------------------------

#let documentclass(
  info: (:),
  abstract-body: [],
  abstract-en-body: [],
  keywords: "",
  keywords-en: "",
  twoside: true,
  anonymous: false,
) = {
  // 默认信息
  let default = (
    degree: "博  士  学  位  论  文",
    page-degree: "博士学位论文",
    title: "（论文题目）",
    author: "（作者姓名）",
    advisor: "（导师姓名）",
    advisor-title: "（专业技术职务）",
    coadvisor: "",
    coadvisor-title: "",
    degree-cat: "（XX学位）",
    major: "（XX工程）",
    interest: "（XX方向）",
    school: "南京理工大学",
    // 路径相对于 njust-thesis/cover.typ；默认值保持当前项目布局。
    logo-path: "../fig/logo/njust.svg",
    submit-date: "yyyy.mm",
    incover-date: "yyyy年mm月",
    backbone-title: "",
    english-degree: "Ph.D.",
    english-title: "(English Title of Thesis)",
    english-author: "(Author Name)",
    english-advisor: "(Supervisor's Name)",
    english-coadvisor: "",
    english-coadvisor-title: "Prof.",
    english-institute: "Nanjing University of Science & Technology",
    english-date: "January, 2024",
    classification: "",
    confidential: "（无）",
    udc: "",
    statement-text: "本学位论文是我在导师的指导下取得的研究成果，尽我所知，在本学位论文中，除了加以标注和致谢的部分外，不包含其他人已经发表或公布过的研究成果，也不包含我为获得任何教育机构的学位或学历而使用过的材料。与我一同工作的同事对本学位论文做出的贡献均已在论文中作了明确的说明。",
    accredit-text: "南京理工大学有权保存本学位论文的电子和纸质文档，可以借阅或上网公布本学位论文的部分或全部内容，可以向有关部门或机构送交并授权其保存、借阅或上网公布本学位论文的部分或全部内容。对于保密论文，按保密的有关规定和程序处理。",
    signature-date: "    年    月    日",
  )
  // anonymous 放在最后：显式参数优先于 info 中的同名键。
  let I = default + info + (anonymous: anonymous)

  // 图/表目录页的公共排版：同一页型、同一套点线规则。
  let list-page(title, target) = {
    clear-page()
    set-preface-page(
      twoside: twoside,
      header-degree: I.page-degree,
      thesis-title: title-text(I.title),
    )
    set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小三, weight: "regular")
    set par(first-line-indent: 0em)
    preface-title(title)
    set text(font: 字体.宋体, size: 字号.小四, weight: "regular")
    set par(first-line-indent: 0em)
    show outline.entry: it => {
      set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
      pad(left: 20pt, it)
    }
    show outline.entry: set outline.entry(
      fill: repeat([.], gap: 0.45em),
    )
    v(28pt)
    outline(title: none, target: target)
  }

  (
    // 封面
    cover: (..args) => {
      let J = I + args.named()
      make-cover(J)
      make-backbone(J, twoside: twoside)
      make-incover(J, twoside: twoside)
      make-english-incover(J, twoside: twoside)
      make-statement(J, twoside: twoside)
    },

    // 摘要（由前文内部调用）
    abstract: (..args) => {
      make-abstract(
        I + (abstract-body: abstract-body, abstract-en-body: abstract-en-body,
             keywords: keywords, keywords-en: keywords-en) + args.named(),
        twoside: twoside,
        header-degree: I.page-degree,
        thesis-title: title-text(I.title),
      )
    },

    // 布局
    preface: (..args) => preface-body(
      twoside: twoside,
      header-degree: I.page-degree,
      thesis-title: title-text(I.title),
      ..args,
    ),
    mainmatter: (..args) => mainmatter-body(
      twoside: twoside,
      header-degree: I.page-degree,
      thesis-title: title-text(I.title),
      ..args,
    ),
    backmatter: (..args) => backmatter-body(
      twoside: twoside,
      header-degree: I.page-degree,
      thesis-title: title-text(I.title),
      ..args,
    ),

    // 目录
    outline: (title, depth: 2) => {
      clear-page()
      set-preface-page(
        twoside: twoside,
        header-degree: I.page-degree,
        thesis-title: title-text(I.title),
      )
      set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小三, weight: "regular")
      set par(first-line-indent: 0em)
      preface-title(title)
      set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
      set par(first-line-indent: 0em)
      show outline.entry.where(level: 1): set text(
        font: 字体.宋体,
        stroke: 字体.粗体描边,
        size: 字号.四号,
        weight: "regular",
      )
      show outline.entry.where(level: 2): set text(
        font: 字体.宋体,
        size: 字号.小四,
        weight: "regular",
      )
      // LaTeX 的目录点线比 Typst 默认 repeat[.] 更疏朗。
      show outline.entry: set outline.entry(
        fill: repeat([.], gap: 0.45em),
      )
      // LaTeX 的一级目录条目之间约有 5.2pt 的额外行距；二级条目仍按
      // 默认行距排列，避免把 1.1 推得过低。
      show outline.entry.where(level: 1): it => pad(bottom: 5.2pt, it)
      v(23.2pt)
      outline(title: none, depth: depth)
      finish-cover-section(twoside: twoside)
    },

    // 图目录与表目录：共用同一页型的排版，但拆成两个独立入口，
    // 由入口文件按顺序分别调用（学校样例中两者各占一页起）。
    list-of-figures: () => {
      list-page("图目录", figure.where(kind: image))
      finish-cover-section(twoside: twoside)
    },
    list-of-tables: () => {
      list-page("表目录", figure.where(kind: table))
      finish-cover-section(twoside: twoside)
    },

    // 字体自检页：逐角色渲染样本，便于在其他机器上目视确认字形是否齐全
    // （缺字会显示为豆腐块）。中文字体来自工程内的 font/，Times New Roman 由系统提供。
    fonts-page: () => {
      clear-page()
      set-preface-page(
        twoside: twoside,
        header-degree: I.page-degree,
        thesis-title: title-text(I.title),
      )
      set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小三, weight: "regular")
      set par(first-line-indent: 0em)
      preface-title("字体自检")
      set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
      set par(first-line-indent: 0em, leading: 1.35em)
      v(17pt)
      for (name, font) in (
        ("宋体", 字体.宋体),
        ("黑体", 字体.黑体),
        ("楷体", 字体.楷体),
        ("魏碑", 字体.魏碑),
        ("拉丁与数字", 字体.roman),
      ) {
        block[
          #text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", name + "：")
          #text(font: font, [南京理工大学学位论文 AaBbGg 0123456789])
        ]
      }
      block[
        #text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", "数学公式：")
        #text(font: "TeX Gyre Termes Math")[$ integral_0^1 x^2 dif x = 1/3, quad alpha, beta, Gamma, nabla $]
      ]
      v(1em)
      block(text(font: 字体.宋体, size: 字号.五号)[
        任一角色显示为方块或字形明显不同，说明该字体在本机缺失或被替换。
        中文字体来自工程内的 `font/` 目录，编译时需 `--font-path font` 或直接运行 `just`；
        Times New Roman 由系统提供，可运行 `just doctor` 检查。
      ])
      finish-cover-section(twoside: twoside)
    },

    // 特殊环境
    abbreviations: (body) => {
      clear-page()
      set-preface-page(
        twoside: twoside,
        header-degree: I.page-degree,
        thesis-title: title-text(I.title),
      )
      set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小三, weight: "regular")
      set par(first-line-indent: 0em)
      preface-title("缩写与中英文对照表")
      set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
      set par(first-line-indent: 0em)
      v(17pt)
      body
      finish-cover-section(twoside: twoside)
    },
    symbols: (body) => {
      clear-page()
      set-preface-page(
        twoside: twoside,
        header-degree: I.page-degree,
        thesis-title: title-text(I.title),
      )
      set text(font: 字体.宋体, stroke: 字体.粗体描边, size: 字号.小三, weight: "regular")
      set par(first-line-indent: 0em)
      preface-title("通用符号")
      set text(font: 字体.宋体, stroke: none, size: 字号.小四, weight: "regular")
      set par(first-line-indent: 0em)
      v(17pt)
      body
      finish-cover-section(twoside: twoside)
    },
    thanks: (body) => {
      // 学校格式文档第 7 节：匿名送审版必须隐去致谢中的导师与作者信息。
      // 致谢通常直接点名致谢对象，因此匿名模式下整页不渲染。
      if I.anonymous { return }
      set page(header: none, footer: none)
      clear-to-odd(twoside: twoside)
      set page(
        paper: page-paper,
        margin: text-margin,
        binding: left,
        header: backmatter-header(
          twoside: twoside,
          header-degree: I.page-degree,
          thesis-title: title-text(I.title),
        ),
        footer: backmatter-footer(twoside: twoside),
      )
      backmatter-title([致#h(2em)谢])
      set text(font: 字体.宋体, size: 字号.小四, weight: "regular")
      show strong: it => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", it)
      set par(first-line-indent: 2em, leading: 10.5pt, justify: true)
      body
    },
    publications: (body) => {
      set page(header: none, footer: none)
      clear-to-odd(twoside: twoside)
      set page(
        paper: page-paper,
        margin: text-margin,
        binding: left,
        header: backmatter-header(
          twoside: twoside,
          header-degree: I.page-degree,
          thesis-title: title-text(I.title),
        ),
        footer: backmatter-footer(twoside: twoside),
      )
      // LaTeX 的附录页标题紧接页眉，致谢页才有额外的 30pt 顶部留白。
      backmatter-title([附#h(2em)录], top: 0pt)
      set text(font: 字体.宋体, size: 字号.小四, weight: "regular")
      show strong: it => text(font: 字体.宋体, stroke: 字体.粗体描边, weight: "regular", it)
      set par(first-line-indent: 0em, leading: 10.5pt)
      body
    },

    // 参考文献
    bibliography: (bib-path, full: false) => {
      set page(header: none, footer: none)
      clear-to-odd(twoside: twoside)
      set page(
        paper: page-paper,
        margin: text-margin,
        binding: left,
        header: backmatter-header(
          twoside: twoside,
          header-degree: I.page-degree,
          thesis-title: title-text(I.title),
        ),
        footer: backmatter-footer(twoside: twoside),
      )
      set text(font: 字体.宋体, size: 字号.小四, weight: "regular")
      set par(first-line-indent: 0em)
      // 参考文献页面自身提供目录锚点，确保目录页码指向实际文献页。
      backmatter-title([参考文献])
      set bibliography(style: "gb-7714-2015-numeric", title: none)
      // Typst 在模板函数内部解析路径；对外统一约定 bib-path 相对于
      // 工程根目录传入，因此这里回到根目录再定位用户的参考文献文件。
      bibliography("../" + bib-path, full: full)
    },
  )
}
