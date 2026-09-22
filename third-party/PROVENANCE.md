# 第三方源码快照（Third-party source snapshots）

本目录保存**上游项目的源码快照**，供示例章节 `#include` 使用。它们**不属于本模板的核心模块**
（`njust-thesis/`），也不随模板用户的论文工程强制分发：删除本目录并移除示例章节中的
`#include` 即可完全移除这些依赖，核心 `documentclass` 契约不受影响。

本仓库自身的代码以 MIT 发布（见根目录 `LICENSE`）；本目录下的文件仍受其**上游许可**约束，
并已随附各自的完整许可文本。

## 目录与许可

| 目录 | 上游项目 | 版本 | 许可 | 许可文本 |
|---|---|---|---|---|
| `cetz/gallery/` | [cetz-package/cetz](https://github.com/cetz-package/cetz) | `v0.5.2` | **LGPL-3.0** | `cetz/LICENSE` |
| `fletcher/gallery/`、`fletcher/readme-examples/` | [Jollywatt/typst-fletcher](https://github.com/Jollywatt/typst-fletcher) | `v0.5.8` | **MIT**（Copyright (c) 2023 Joseph Wilson） | `fletcher/LICENSE` |

快照取自上游仓库（不是 Typst 包 tarball，包内不含示例目录），抓取日期 2026-09-21。

## 修改说明

**以下 14 个文件都相对上游做过修改**，均属适配本模板的版式与字体契约，不改变示例的图形结构。
按 LGPL-3.0 的要求，此处登记修改内容；Fletcher 相关文件中带有 `Template adaptation` 注释的，
文件内也直接写明了改动。

共同的修改：

- 删除上游示例用于独立预览的页面设置
  （`#set page(width: auto, height: auto, margin: ...)`），因为文件改为被章节 `#include`，
  页面几何必须由模板控制。
- 数学与文本字体改为模板契约：`Times New Roman` + `TeX Gyre Termes Math`，
  避免引入 New Computer Modern 或触发数学字体回退（仅 Fletcher 相关文件需要）。
- `slash.double` 等 Termes 字体不含的字形改写为等价记号（如 `/`），避免字体回退。

逐文件差异行数（相对上游同名文件，忽略注释行的比较结果）：

| 文件 | 差异行数 |
|---|---:|
| `cetz/gallery/karls-picture.typ` | 3 |
| `cetz/gallery/plate-capacitor.typ` | 1 |
| `cetz/gallery/tree.typ` | 1 |
| `cetz/gallery/waves.typ` | 1 |
| `fletcher/gallery/02-algebra-cube.typ` | 3 |
| `fletcher/gallery/03-ml-architecture.typ` | 5 |
| `fletcher/gallery/04-io-flowchart.typ` | 5 |
| `fletcher/gallery/05-digraph.typ` | 3 |
| `fletcher/gallery/06-node-groups.typ` | 3 |
| `fletcher/gallery/07-uml-diagram.typ` | 3 |
| `fletcher/readme-examples/3-state-machine.typ` | 5 |
| `fletcher/gallery/01-commutative.typ` | 8 |
| `fletcher/gallery/08-tree.typ` | 3 |
| `fletcher/gallery/10-category-theory.typ` | 6 |

## 维护约定

- 升级上游版本时，必须同时更新上表的版本、重新抓取快照、重跑 `bash tests/run-regressions.sh`
  （其中包含题注与图区墨迹断言），并保持 `LICENSE` 文本与上游一致。
- 不要把这里的文件移入 `njust-thesis/`，也不要在核心模块中 `#import` 它们。
- 若上游许可发生变化，以本目录下随附的许可文本为准并更新本文件。
