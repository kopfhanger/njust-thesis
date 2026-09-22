#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

// Template adaptation: use the bundled Termes math font instead of the
// compiler default New Computer Modern for the official math diagram.
// The unsupported `slash.double` glyph is written as an ordinary quotient
// slash so the diagram does not trigger a fallback math font.
#set text(font: "TeX Gyre Termes Math")
#show math.equation: set text(font: "TeX Gyre Termes Math")

#diagram(
	spacing: (1em, 3em),
	$
		& tau^* (bold(A B)^n R / R^times) edge(->) & bold(B)^n R / R^times \
		X edge("ur", "-->") edge("=") & X edge(->, tau) edge("u", <-) & bold(B) R^times edge("u", <-)
	$,
	edge((2,1), "d,ll,u", "->>", text(blue, $Gamma^*_R$), stroke: blue, label-side: center)
)
