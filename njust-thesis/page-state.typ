// ============================================================
// NJUST Thesis — 分页状态
// ============================================================

// 只在 Typst 真的插入了一张空白页时，才在 pagebreak 的目的地写这个标记；
// 页眉页脚据此隐藏“目的地前一页”（见 lib.typ / cover.typ 的页眉页脚）。
#let inserted-blank-page-marker = "njust-odd-break-destination"

// 断点起点标记：零尺寸，记录分页前内容流落在哪一页。
#let break-origin-marker = "njust-odd-break-origin"

// 双面模式跳到下一个奇数页，并只在真的插入空白页时留下目的地标记。
//
// 判据：目的地页 - 起点页 ≥ 2，说明 Typst 在两者之间插入了一张空白页。
// - 上一章结束在偶数页 → 目的地就是下一页（差 1），不写标记，正文页仍保留页眉页码；
// - 上一章结束在奇数页 → 目的地跳过一张偶数页（差 2），写标记，只有该页被隐藏。
//
// 这个判据只看分页本身，不看页面有没有正文元素，因此跨页段落、跨页表格的
// 续页不会因为没有新的元素起点而被误判为空白页。
#let break-to-odd(twoside: false) = {
  if twoside {
    metadata(break-origin-marker)
    pagebreak(to: "odd", weak: true)
    context {
      let destination = here().page()
      let origins = query(
        selector(metadata.where(value: break-origin-marker)).before(here()),
      )
      if origins.len() > 0 and destination - origins.last().location().page() >= 2 {
        metadata(inserted-blank-page-marker)
      }
    }
  } else {
    pagebreak(weak: true)
  }
}
