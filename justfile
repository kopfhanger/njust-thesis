set shell := ["bash", "-cu"]

# Prefer the official Typst CLI, but allow Tinymist's CLI-compatible binary
# when Typst is not installed on the current machine.
typst_bin := env_var_or_default(
  "TYPST_BIN",
  `command -v typst 2>/dev/null || command -v tinymist 2>/dev/null || echo typst`,
)
typst_input := env_var_or_default("TYPST_INPUT", "main.typ")
typst_output := env_var_or_default("TYPST_OUTPUT", "main.pdf")
font_path := env_var_or_default("FONT_PATH", "font")

default: compile

# Build the example thesis. Just intentionally compiles on every invocation;
# this keeps chapter files in arbitrary user directories valid build inputs.
compile: doctor
    @"{{typst_bin}}" compile --font-path "{{font_path}}" "{{typst_input}}" "{{typst_output}}"

doctor:
    @echo "compiler: {{typst_bin}}"
    @"{{typst_bin}}" --version
    @echo "font path: {{font_path}}"
    @test -f "font/simsun.ttc" || { echo "error: missing font asset: font/simsun.ttc" >&2; exit 1; }
    @test -f "font/simhei.ttf" || { echo "error: missing font asset: font/simhei.ttf" >&2; exit 1; }
    @test -f "font/simkai.ttf" || { echo "error: missing font asset: font/simkai.ttf" >&2; exit 1; }
    @test -f "font/weibei.ttf" || { echo "error: missing font asset: font/weibei.ttf" >&2; exit 1; }
    @test -f "font/texgyretermes-math.otf" || { echo "error: missing font asset: font/texgyretermes-math.otf" >&2; exit 1; }
    @test -f "fig/logo/njust.svg" || { echo "error: missing build asset: fig/logo/njust.svg" >&2; exit 1; }
    @echo "fonts: local SimSun/SimHei/KaiTi/FZWeiBei-S03S/TeX Gyre Termes Math + Times New Roman"
    @test "$(fc-match -f '%{family}' 'Times New Roman' 2>/dev/null || true)" = "Times New Roman" || { echo "error: Times New Roman is required and must resolve to the real family (install ttf-ms-fonts)" >&2; exit 1; }
    @echo "assets: required template assets are present"

# Optional extension smoke tests do not belong to the default build.
test-optional:
    bash tests/run-optional-packages.sh

test:
    bash tests/run-regressions.sh

watch: doctor
    @"{{typst_bin}}" watch --font-path "{{font_path}}" "{{typst_input}}"

clean:
    rm -f "{{typst_output}}"
