// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

#import "@preview/fontawesome:0.3.0": *

#let color-link = rgb("#483d8b")

#let article(
  title: none,
  subtitle: none,
  header: none,
  code-repo: none,
  authors: none,
  date: none,
  abstract: none,
  keywords: none,
  custom-keywords: none,
  thanks: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  sansfont: (),
  mathfont: (),
  number-type: auto,
  number-width: auto,
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize,
           number-type: number-type,
           number-width: number-width,)
  show math.equation: set text(font: mathfont)
  set heading(numbering: sectionnumbering)

  show heading: set text(font: sansfont, weight: "semibold")

  show figure.caption: it => [
    #set text(font: sansfont, size: 0.9em)
    #if it.supplement == [Figure] {
      set align(left)
      text(weight: "semibold")[#it.supplement #it.counter.display(it.numbering): ]
      it.body
    } else {
      text(weight: "semibold")[#it.supplement #it.counter.display(it.numbering): ]
      it.body
    }
    
  ]
  
  show ref: it => {
    let eq = math.equation
    let el = it.element
    if el == none {
      it
    } else if el.func() == eq {
      link(el.location())[
        #numbering(el.numbering,
        ..counter(eq).at(el.location())
        )
      ]
      
    } else if el.func() == figure {
      el.supplement.text
      link(el.location())[
        #set text(fill: color-link)
        #numbering(el.numbering,..el.counter.at(el.location()))
      ]
    } else {
      it
    }
  }

  show link: set text(fill: color-link)
  set bibliography(title: "References")

  if date != none {
    align(left)[#block()[
      #text(weight: "semibold", font: sansfont, size: 0.8em)[
        #date
        #if header != none {
          h(3em)
          text(weight: "regular")[#header]
        }
      ]
    ]]
  }

  if code-repo != none {
    align(left)[#block()[
      #text(weight: "regular", font: sansfont, size: 0.8em)[
        #code-repo
      ]
    ]]
  }
  
  if title != none {
    align(left)[#block(spacing: 4em)[
      #text(weight: "semibold", size: 1.5em, font: sansfont)[
        #title
        #if thanks != none {
          footnote(numbering: "*", thanks)
        }\
        #if subtitle != none {
          text(weight: "regular", style: "italic", size: 0.8em)[#subtitle]
        }
      ]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(left)[
            #text(size: 1.2em, font: sansfont)[#author.name]
            #if author.orcid != [] {
                link("https://orcid.org/" + author.orcid.text)[
                  #set text(size: 0.85em, fill: rgb("a6ce39"))
                  #fa-orcid()
                ]
            } \
            #text(size: 0.85em, font: sansfont)[#author.affiliation] \
            #text(size: 0.7em, font: sansfont, fill: color-link)[
              #link("mailto:" + author.email.children.map(email => email.text).join())[#author.email]
            ]
          ]
      )
    )
  }  

  if abstract != none {
    block(inset: 2em)[
      #text(weight: "semibold", font: sansfont, size: 0.9em)[ABSTRACT] #h(0.5em)
      #text(font: sansfont)[#abstract]
      #if keywords != none {
         text(weight: "semibold", font: sansfont, size: 0.9em)[\ Keywords:]
         h(0.5em)
         text(font: sansfont)[#keywords]
      }
      #if custom-keywords != none {
        for it in custom-keywords {
          text(weight: "semibold", font: sansfont, size: 0.9em)[\ #it.name:]
          h(0.5em)
          text(font: sansfont)[#it.values]
        }
      }
    ]
  }  

  if toc {
    block(above: 0em, below: 2em)[
    #outline(
      title: auto,
      depth: none
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }

}

#let appendix(content) = {
  // Reset Numbering
  set heading(numbering: "A.1.1")
  counter(heading).update(0)
  counter(figure.where(kind: "quarto-float-fig")).update(0)
  counter(figure.where(kind: "quarto-float-tbl")).update(0)

  // Figure & Table Numbering
  set figure(numbering: it => {
    [A.#it]
  })

  // Appendix Start
  pagebreak(weak: true)
  text(size: 2em)[Appendix]
  content
}
#show: doc => article(
  title: [Quarto Academic Typst],
  subtitle: [A minimalistic Quarto + Typst template for academic writing],
  authors: (
    ( name: [Kazuharu Yanagimoto],
      affiliation: [CEMFI],
      email: [kazuharu.yanagimoto\@cemfi.edu.es],
      orcid: [0009-0007-1967-8304]
    ),
    ),
  date: [Sunday, April 6, 2025],
  abstract: [Ut ut condimentum augue, nec eleifend nisl. Sed facilisis egestas odio ac pretium. Pellentesque consequat magna sed venenatis sagittis. Vivamus feugiat lobortis magna vitae accumsan. Pellentesque euismod malesuada hendrerit. Ut non mauris non arcu condimentum sodales vitae vitae dolor. Nullam dapibus, velit eget lacinia rutrum, ipsum justo malesuada odio, et lobortis sapien magna vel lacus. Nulla purus neque, hendrerit non malesuada eget, mattis vel erat. Suspendisse potenti.

],
  keywords: [Quarto, Typst, format],
  thanks: [You can write acknowledgements here.

],
  sectionnumbering: "1.1.1",
  cols: 1,
  doc,
)


This document shows a minimal example of the template. For more information, see the #link("https://kazuyanagimoto.com/quarto-academic-typst/template-full.pdf")[full demo] and its #link("https://kazuyanagimoto.com/quarto-academic-typst/template-full.qmd")[source];.

= Section as Heading Level 1
<section-as-heading-level-1>
Section numbering can be specified in the YAML `section-numbering` field as other Typst templates.

== Subsection as Heading Level 2
<subsection-as-heading-level-2>
You can use LaTeX math expressions:

$ Y_(i t) = alpha_i + lambda_t + sum_(k eq.not - 1) tau_h { E_i + k = t } + epsilon_(i t) . $

=== Subsubsection as Heading Level 3
<subsubsection-as-heading-level-3>
I don’t use and don’t recommend using heading levels 3 and below but it works.

== Citation
<citation>
You can cite a reference like this @katsushika1831 or #cite(<horst2020>, form: "prose");. Typst has some built-in citation styles. Check the #link("https://typst.app/docs/reference/model/bibliography/#parameters-style")[Typst documentation] for more information.

= Figures and Tables
<figures-and-tables>
== Figures
<figures>
As @fig-hist-mpg shows, the caption is displayed below the figure. As a caption of the figure (`fig-cap`), I use bold text for the title and use a normal text for the description.

#figure([
#box(image("paper-1_files/figure-typst/fig-hist-mpg-1.svg"))
], caption: figure.caption(
position: bottom, 
[
#strong[Histogram of Miles per Gallon];. The x-axis shows the miles per gallon, and the y-axis shows the frequency.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-hist-mpg>


== Tables
<tables>
You can use #link("https://vincentarelbundock.github.io/tinytable/")[tinytable] for general tables and #link("https://vincentarelbundock.github.io/modelsummary/")[modelsummary] for regression tables.#footnote[Since the default backend of `modelsummary` is `tinytable`, you can use the customization options of `tinytable` for `modelsummary`.] As @tbl-mtcars-head shows, the caption is displayed above the table. The notes of the table can be added using the `notes` argument of the `tinytable::tt()` function.

#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 5;
#let ncol = 5;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (16.00%, 16.00%, 16.00%, 16.00%, 16.00%),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 5, stroke: 0.05em + black),
 table.hline(y: 6, start: 0, end: 5, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 5, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[mpg], [cyl], [disp], [hp], [drat],
    ),

    // tinytable cell content after
[21.0], [6], [160], [110], [3.90],
[21.0], [6], [160], [110], [3.90],
[22.8], [4], [108], [93], [3.85],
[21.4], [6], [258], [110], [3.08],
[18.7], [8], [360], [175], [3.15],

    // tinytable footer after

    table.footer(
      repeat: false,
      // tinytable notes after
    table.cell(align: left, colspan: 5, text([_Notes_: This table shows the first six rows of the mtcars dataset.])),
    ),
    

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Head of the mtcars Dataset
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-mtcars-head>


= Last words
<last-words>
I made this template for my working papers, so it may not be suitable for other fields than economics. I am happy to receive feedback and suggestions for improvement.

#show: appendix
= Supplemental Figures
<supplemental-figures>
The figure numbering will be reset to "A.1", "A.2", etc so that it is clear that these figures are part of the appendix.

#figure([
#box(image("paper-1_files/figure-typst/fig-scatter-car-1.svg"))
], caption: figure.caption(
position: bottom, 
[
#strong[Scatter Plot of Car Data];. The x-axis shows the weight of the car, and the y-axis shows the miles per gallon.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-scatter-car>


#pagebreak()



#bibliography("references.bib")

