# 本地字体资源

字体文件因授权和体积原因不纳入 Git。请在本目录放置以下文件后运行 `just doctor`：

- `simsun.ttc` — 宋体
- `simhei.ttf` — 黑体
- `simkai.ttf` — 楷体
- `weibei.ttf` — 方正魏碑，用于封面标题
- `texgyretermes-math.otf` — TeX Gyre Termes Math

正文英文与数字还需要系统提供真实的 Times New Roman；Debian/Ubuntu 可安装 `ttf-ms-fonts`。

模板编译时通过 `--font-path font` 加载本目录字体。请确认字体的使用符合相应授权，不要把未经授权的字体文件上传到公共仓库。
