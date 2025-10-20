{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karax, karaxdsl, vdom]

proc newMainNode(): VNode =
  buildHtml(section(class = "section")):
    tdiv(class = "content"):
      h1(class = "title"):
        text "Pon!通 操作方法"
      img(src = "./manual.png", width = "800")

when isMainModule:
  setRenderer newMainNode
