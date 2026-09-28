# 本地图片资源

只有模板实际需要的校徽和示例图片纳入 Git；其他图片因授权和体积原因不纳入 Git。资源路径如下：

- `logo/njust.svg` — 南京理工大学校徽矢量图，模板封面必需，已随仓库提供；
- `example/rabbit.png` — 根目录示例论文中的示例插图，已随仓库提供，替换真实章节后可删除。
- `tex/unified-state-space.tex` — TikZ 状态空间示例源文件；
- `tex/unified-response.tex` — PGFPlots 响应曲线示例源文件。

运行 `just figures` 会用 XeLaTeX 重新生成两个 PDF。PDF、`.aux` 和 `.log` 文件只作为本地构建产物，不纳入 Git。两个源文件都显式设置 `Times New Roman` 与 `font/texgyretermes-math.otf`，因此图内文字和数学公式可以与 Typst 正文保持一致。若替换为真实图形，保留这两项字体设置即可。

校徽和其他图片应按各自授权使用。字体资源准备好后运行 `just doctor` 检查必需文件。
