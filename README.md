# NJUST-Thesis-Typst

南京理工大学研究生学位论文 Typst 模板。

基于 [njusttt](https://github.com/pasteller/njusttt) (LaTeX) 重新实现，采用 `documentclass` 设计模式（借鉴 [modern-nju-thesis](https://github.com/nju-lug/modern-nju-thesis)）。

## 使用方法

构建命令使用 [Just](https://just.systems/)；请先安装 `just`，并确保 `typst` 或 `tinymist` 位于 `PATH` 中。

### 编译

```bash
just doctor   # 检查编译器、字体和图片依赖
just          # 编译 main.pdf
just test-optional           # 编译选定的可选包 smoke tests
just watch    # 实时预览
just clean    # 清理生成的 PDF
```

`just` 会优先使用 PATH 中的 `typst`；如果没有安装官方 CLI，则使用 PATH 中的 `tinymist`。当前模板按 Typst 0.15.1 验证。`just compile` 每次都会先运行 `doctor`，再编译入口文件；这使得章节放在任意源码子目录时不需要维护构建依赖清单。也可以显式指定编译器或入口文件：

```bash
TYPST_BIN=/path/to/typst just compile
TYPST_INPUT=main.typ just compile
```

手动编译时需要显式传入本地字体路径：

```bash
typst compile --font-path font main.typ
typst watch --font-path font main.typ
```

如果环境中只有 Tinymist，则将上面命令中的 `typst` 替换为 `tinymist`。构建固定从 `font/` 加载中文字体和数学字体；正文拉丁字母、数字以及英文封面使用 Times New Roman，因此新环境需要安装该字体（Debian/Ubuntu 可安装 `ttf-ms-fonts`）。

模板依赖 `font/` 下的本地字体以及仓库中随附的 `fig/logo/njust.svg` 矢量校徽。示例章节另外使用仓库中随附的 `fig/example/rabbit.png`；替换为真实章节后可以删除。字体和其他未列出的图片属于本地二进制资源，不纳入版本控制；在新环境中应先按相同相对路径提供字体，再运行 `just doctor`。

### 目录结构

```
njust-thesis/
├── main.typ               # 主入口文件
├── justfile               # 编译命令
├── njust-thesis/          # 模板核心
│   ├── lib.typ            # documentclass 主库
│   ├── style.typ          # 字体与字号定义
│   └── cover.typ          # 封面/摘要/声明页
├── chapter/               # 内容章节
│   ├── abbreviations.typ  # 缩写表
│   ├── symbols.typ        # 符号表
│   ├── ch1.typ ~ ch6.typ  # 各章正文
│   ├── thanks.typ         # 致谢
│   └── publications.typ   # 附录（成果列表）
├── font/                  # 中文字体文件（本地资源，不纳入版本控制）
│   ├── simsun.ttc         # 宋体
│   ├── simhei.ttf         # 黑体
│   ├── simkai.ttf         # 楷体
│   └── weibei.ttf         # 方正魏碑（外封面学位论文标题）
├── fig/                   # 必要示例图片（其余本地图片不纳入版本控制）
│   ├── logo/              # 校徽
│   └── example/           # 示例章节图片（可替换或删除）
├── third-party/           # CeTZ/Fletcher 上游源码快照（含各自许可与修改登记）
├── ref/                   # 参考文献 (.bib)
├── template/              # 空白起步文件 thesis.typ（没有示例假数据）
├── tools/                 # 版式测量脚本（对参考论文量页眉/正文/页脚与标题间距）
├── tests/                 # 结构回归与可选扩展 smoke tests，不参与论文正文
└── docs/                  # 格式基线与工程记录
```

## 配置说明

在 `main.typ` 中通过 `documentclass()` 设置论文信息：

| 参数 | 说明 |
|------|------|
| `anonymous` | 匿名送审模式（默认 `false`）：按学校格式文档第 7 节隐去封面、封二与致谢中的导师和作者信息，并整页不渲染致谢 |
| `twoside` | 双面排版；默认 `true`，设为 `false` 时不生成书脊页 |
| `degree` / `page-degree` | 学位论文类型 |
| `title` | 论文题目；推荐写成数组逐行给出，也兼容 `"第一行\\第二行"` |
| `author` | 作者姓名 |
| `advisor` / `advisor-title` | 导师姓名 / 职称 |
| `coadvisor` / `coadvisor-title` | 协同导师姓名 / 职称；为空时保留 LaTeX 基准中的空白行 |
| `degree-cat` | 学位类别（如工学博士） |
| `major` / `interest` | 学科名称 / 研究方向 |
| `school` | 学校名称 |
| `backbone-title` | 书脊标题；留空则使用 `title` |
| `logo-path` | 校徽路径；默认相对于 `njust-thesis/cover.typ` 指向 `../fig/logo/njust.svg` |
| `submit-date` / `incover-date` / `signature-date` / `english-date` | 日期；可传 `datetime(...)`（月精度写 `day: 1`，模板按学校写法格式化）或直接写字符串 |
| `abstract-body` / `keywords` | 中文摘要内容与关键词 |
| `abstract-en-body` / `keywords-en` | 英文摘要内容与关键词 |
| `english-*` | 英文封面信息；多导师时可用 `english-coadvisor` / `english-coadvisor-title` 添加第二行 |
| `classification` / `confidential` / `udc` | 分类号 / 密级 / UDC |
| `statement-text` / `accredit-text` | 声明页的声明文字 / 授权使用说明文字 |

匿名送审只按学校文档的范围遮蔽封面、封二与致谢；**成果列表（附录页）里出现的作者姓名、基金号等信息不在此范围内**，送审前需要自己替换。

## 示例

模板包含完整的示例论文《超音速牛奶喷射与时间旅行的概率动力学研究》，可直接编译查看效果。示例正文按公式类型与版式分散到各章并配有说明文字：第 2 章给出矩阵与范数、级数积分与极限、微分算子、概率分布与贝叶斯更新；第 3 章给出导数与泰勒展开、最优性与 KKT 条件、特征分解与奇异值分解、常用不等式；第 4 章给出有限差分与时间步进、收敛阶与外推、CFL 与放大因子、最小二乘与正则化、蒙特卡洛与重要性采样；第 5 章给出滤波与谱分析、不确定度合成、复杂度与终止判据；第 6 章把结论写成可核对的量化形式。第 2 章另设“公式版式与编号”一节，集中演示行内与行间公式、多行对齐、逐行编号、分段函数、矩阵与方程组、大算符、连分数、上下标注、集合与映射、指标式、变换对与泛函等写法。表格部分覆盖普通三线表、分组表头与合并单元格、带单位表头与表注、并排双表、跨页长表五种版式；第 1 章给出论文结构框架图并扩充了研究背景与研究现状，摘要、绪论、致谢与参考文献均按学位论文的正常篇幅书写（参考文献为排版演示用条目，接入时必须整表替换）。第 1—6 章是连续正文，而不是独立示例附录：第 1 章展示研究问题和技术路线；第 2 章展示行内公式、行间公式、物理记号、科学单位、三线表、CeTZ 子图组和 Lilaq 统计图组；第 3 章展示中文定义、定理、证明、分段公式、模型验证和 Fletcher 状态关系子图组；第 4 章展示 CeTZ 结构图、Lilaq 普通数据图、Lilaq 诊断图组和 Lilaq 多子图；第 5 章展示排版后的伪代码算法、CeTZ 流程图和 Fletcher 工程模块子图组；第 6 章展示结论证据表和真实论文接入建议。

仓库不再编译“每个官方示例占一页”的附录，也不再维护 Gribouille 和 plotsy-3d 的示例集合。`third-party/` 保存被示例正文 `#include` 的 CeTZ/Fletcher 上游源码快照（**不是核心模块**，删除该目录与相应 `#include` 即可移除）；被正文调用的 Fletcher 数学图包含了模板字体适配，以避免引入 New Computer Modern 或不兼容数学字形。正文按研究语境组织图：同一绘图系统的多张示意图合并为一个子图组（第 2 章的 CeTZ 组、第 3 章的状态关系组、第 5 章的工程模块组），父图共用总题注和编号、子图题注用 (a)(b)… 标注；Lilaq 的同类数据对象同样组织为子图组。图题、编号、上下间距和分页仍由模板统一控制。

`third-party/` 下的文件不适用本仓库的 MIT 许可：`third-party/cetz/` 来自 cetz（**LGPL-3.0**），`third-party/fletcher/` 来自 typst-fletcher（**MIT**）。各目录随附上游许可全文，`third-party/PROVENANCE.md` 逐个文件登记了上游项目、版本、许可、抓取来源与修改内容。这里只保留正文实际 `#include` 的示例快照；其余官方示例请直接从上游项目获取。升级上游版本时必须同步更新该登记并重跑回归。

真实论文接入时，推荐直接用**空白起步文件** `template/thesis.typ`：它没有示例假数据，`info`、摘要、后文都写成占位内容，并逐项注释了可用参数与三种可选页（缩写表、符号表、字体自检）。可以单独编译预览：

```bash
tinymist compile --font-path font template/thesis.typ /tmp/starter.pdf
```

也可以保留示例 `main.typ` 的调用方式，把 `info` 和中英文摘要换成真实内容，再把正文章节文件放进任意源码子目录、在 `mainmatter` 中 `#include`。模板不会读取示例章节中的作者、导师或题名；这些内容只存在于根目录的示例 `main.typ` 和 `chapter/` 文件中。

正文的默认段落、列表、行间公式、表格、图题和表题规则集中在 `njust-thesis/lib.typ`，第 1—6 章共享同一套规则。章节文件不应通过额外的 `#v(...)` 或 `#set` 修改正文与图表的间距；特殊算法框等对象内部的紧凑排版只作用于该对象。接入真实论文时可以直接替换示例章节，不会继承示例章节的局部排版状态。

图目录和表目录由 `thesis.list-of-figures()` 与 `thesis.list-of-tables()` 分别生成（两个入口各占一页，按学校样例起新页）；缩写表、通用符号表和字体自检页 `thesis.fonts-page()` 在示例入口中默认注释掉，需要时可取消注释。参考文献可在后文中显式调用：

```typst
#(thesis.backmatter)[
  #(thesis.thanks)[
    #include "chapter/thanks.typ"
  ]
  // 默认只列出正文中实际使用 @key 引用的文献。
  #(thesis.bibliography)("ref/thesis.bib")
  #(thesis.publications)[
    #include "chapter/publications.typ"
  ]
]
```

`just doctor` 只检查模板必需的字体、数学字体、校徽和真实的 Times New Roman 字体解析，不会因为删除示例章节图片而失败。`just compile` 不限制章节目录：新增或替换 `.typ`、`.bib`、`.csv` 和 `.txt` 文件后直接重新运行即可。

真实论文应使用 Typst 的 `@key` 文献引用，并使用默认的 `full: false`。示例论文为了保持与 LaTeX 基准一致，仍使用手工上标，因此在 `main.typ` 中显式传入 `full: true`；这不是模板的默认契约。

模板自带的 `tests/regression-long-chapter.typ` 用于检查长章节、章节间空白页和无手写 `#h(2em)` 时的首段缩进；`tests/citation.typ` 用于检查只列出实际引用文献；`tests/check-pagination.py` 对 PDF **逐页**校验页眉/页码不变量，并构建下列对抗性 fixture：章节结束在偶数页、章节结束在奇数页、章节内容正好填满整页、整页只有位图、整页只有纯矢量图形、`twoside: false` 单面模式；`tests/check-figures.py` 校验题注存在且题注上方图形带**真的有墨迹**（散文不计入，空图实测为 0），避免"包失效、图渲染成空白但题注还在"被放过；`tests/check-cover-fonts.py` 用 `pdftohtml -xml` 做**字形级**断言，确认外封面与内封面的中文作者名都落在楷体而不是回退到宋体。`tests/anonymous.typ` 用同一份内容在匿名/实名两种输入下各编译一次，实名版作为正向对照，匿名版必须读不到姓名与致谢；`template/thesis.typ` 与 `tests/fonts-page.typ` 分别保证起步文件能独立编译、字体自检页逐角色齐全。判断"页面有没有正文"用灰度渲染后的正文带墨迹统计，因此文字、位图和矢量图一视同仁。可以用下面的命令单独运行它们：

```bash
tinymist compile --font-path font tests/regression-long-chapter.typ /tmp/njust-long.pdf
tinymist compile --font-path font tests/citation.typ /tmp/njust-citation.pdf
tinymist compile --font-path font tests/cover-chinese-author.typ /tmp/njust-cover.pdf
tinymist compile --font-path font --input anonymous=true tests/anonymous.typ /tmp/njust-anon.pdf
tinymist compile --font-path font template/thesis.typ /tmp/njust-starter.pdf
python3 tests/check-pagination.py      # 逐页分页不变量
python3 tests/check-pagination.py -v   # 额外输出每页墨迹像素数
python3 tests/check-cover-fonts.py /tmp/njust-cover.pdf
python3 tests/check-figures.py main.pdf --captions 图2.1,图5.1 --ink-floor 10
# 完整回归：还会检查默认 PDF 的结构、图注墨迹、匿名送审与字体回退
bash tests/run-regressions.sh
```

回归脚本使用 Tinymist/Typst、Python 3、Poppler 的 `pdfinfo`/`pdftotext`/`pdftoppm`/`pdffonts`/`pdftohtml`、`qpdf`、`awk` 和 POSIX `grep`；这些工具只用于工程验证，不是模板用户编译论文的运行时依赖。

仓库是一个需要本地字体资源的项目模板，而不是开箱即用的 `@preview` 模板包。字体文件不进入 Git；校徽和示例兔图是为保证示例可编译而随仓库提供的必要图片，其他图片仍按 `.gitignore` 忽略。源代码许可证见 `LICENSE`，字体和校徽仍以其各自的上游授权为准。

示例中的 CeTZ 和 Fletcher 负责结构、流程和模块关系图；Lilaq 负责曲线、散点和数据比较图。首次编译时 Tinymist/Typst 会按包导入自动获取依赖；若处于无网络环境，可先在有网络的环境编译一次，或将对应包安装到本地 Typst 包目录。真实论文不需要某个扩展时，可以删除对应章节中的导入和内容对象，其余模板功能不受影响。

## 可选扩展

核心模板只依赖本地 `njust-thesis/` 模块、字体和校徽；下面的包不会被导入核心模块，也不会影响默认论文的版式。它们通过 `tests/optional/` 提供最小示例，所有导入都锁定版本：

| 包 | 版本 | 适用场景 |
|---|---:|---|
| `unify` | `0.8.1` | 科学数字、误差、单位和范围 |
| `lilaq` | `0.6.0` | 曲线、散点、误差棒和数据可视化 |
| `lovelace` | `0.3.1` | 带缩进、行号和嵌套结构的算法伪代码 |
| `fletcher` | `0.5.8` | 带箭头的流程图、状态图和数学关系图 |
| `physica` | `0.9.8` | 物理记号、向量、张量、梯度和偏导数；即用户所称的 `typst-physics` |
| `ctheorems` | `2.0.0` | 定义、定理、证明、编号和交叉引用；即用户所称的 `typst-theorems` |
| `subpar` | `0.2.2` | 同一组示意图或数据图的父图/子图题注、编号和布局（CeTZ、Fletcher、Lilaq 共用） |

使用方式是把对应 fixture 中的版本化 `#import` 复制到自己的章节或项目入口，再按包的文档配置局部规则。例如 `ctheorems` 需要 `#show: thm-rules`，不应把它无条件写进模板核心。可选扩展回归需要联网下载或已有 Typst 包缓存，运行：

```bash
just test-optional
```

Metro 暂不列为已验证扩展。`metro:0.3.0` 已复现为在 `src/defs/units.typ:7:15` 因 `unknown variable: kelvin` 导入失败；`metro:0.2.0` 在当前本机先报 `failed to decompress package`，但其源码仍保留同一 `kelvin` 定义，预期会遇到同类阻塞。上游修复前不建议把它引入论文工程。`tablex` 也不引入：当前 Typst 原生 `table`/`grid` 已支持单元格、跨行列、线条和重复表头等模板所需能力，继续使用原生三线表实现更稳定。

七个已验证扩展的最小示例分别位于 `tests/optional/unify.typ`、`lilaq.typ`、`lovelace.typ`、`fletcher.typ`、`physica.typ`、`ctheorems.typ` 和 `subpar.typ`。这些文件是 API smoke test，不是模板核心入口；删除它们不会改变 `main.pdf`。

为便于观察这些包在论文正文中的实际用法，示例第 2—6 章分别启用了 unify/Physica、ctheorems、Lilaq/subpar、CeTZ/Lovelace/Fletcher。Metro、Gribouille 和 plotsy-3d 不进入示例正文或已验证扩展集合；`tablex` 也不引入，表格继续使用 Typst 原生 `table`/`grid`。`subpar` 既包装同一数据对象的 Lilaq 图，也包装同一绘图系统的 CeTZ/Fletcher 示意图（示例中的图 2.1、图 3.1、图 5.3）；不同绘图系统的对象不混在同一子图组内。

## 字体

模板使用以下中文字体（位于 `font/`），编译时需通过 `--font-path font` 或 `just` 加载：

- **宋体** (`SimSun`): `simsun.ttc`
- **黑体** (`SimHei`): `simhei.ttf`
- **楷体** (`KaiTi`): `simkai.ttf`
- **魏碑** (`FZWeiBei-S03S`): `weibei.ttf`，用于外封面学位论文标题
- **TeX Gyre Termes Math**: `texgyretermes-math.otf`，用于正文数学公式
- Times New Roman：由系统提供，用于 LaTeX 基准中的拉丁字母、数字和英文封面

四个中文字体文件均提供常规字重。模板对需要加粗的宋体、楷体文字使用轻量描边模拟粗体；英文粗体、斜体和数字字形直接使用 Times New Roman 的对应字重。

## 致谢

- [njusttt](https://github.com/pasteller/njusttt) — 南京理工大学 LaTeX 学位论文模板
- [modern-nju-thesis](https://github.com/nju-lug/modern-nju-thesis) — 南京大学 Typst 学位论文模板
