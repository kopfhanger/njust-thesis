#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let bent-edge(from, to, ..args) = {
  let midpoint = (from, 50%, to)
  let vertices = (
    from,
    (from, "|-", midpoint),
    (midpoint, "-|", to),
    to,
  )
  edge(..vertices, "-|>", ..args)
}

#diagram(
  // Template adaptation: the gallery output uses rectangular nodes.  Pin the
  // shape because Fletcher's auto-shape heuristic can turn the first leaf
  // into a circle after this example is placed in a narrow subfigure cell.
  node-shape: "rect",
  node-stroke: luma(80%),
  edge-corner-radius: none,
  spacing: (10pt, 20pt),

  // Nodes
  node((1.5,0), [*Entrate\ pubblicitarie*], name: <a>),
  node((0.5,1), [*Numero di\ impression*], name: <b>),
  node((2.5,1), [*Guadagno medio\ per impression*], name: <c>),

  node((0,2), [*Traffico\ sul sito*], name: <d>),
  node((1,2), [*Impression/\ visitatori*], name: <e>),

  node((2,2), [*Modalità\ di vendita*], name: <f>),
  node((3,2), [*Tipo di\ posizionamento*], name: <g>),

  // Edges
  bent-edge(<a>, <b>),
  bent-edge(<a>, <c>),
  bent-edge(<b>, <d>),
  bent-edge(<b>, <e>),
  bent-edge(<c>, <f>),
  bent-edge(<c>, <g>),
)
