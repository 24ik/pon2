## This module implements the search bar for pairs DB.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, vdom]
import ../../../../app/[marathon]

proc newMarathonSearchBarNode*(marathon: Marathon, id: string): VNode {.inline.} =
  ## Returns the search bar node for pairs DB.
  result = buildHtml(tdiv(class = "field is-horizontal")):
    tdiv(class = "field-label is-normal"):
      label(class = "label"):
        text "ツモ"
    tdiv(class = "field-body"):
      tdiv(class = "field"):
        tdiv(class = "control"):
          input(
            id = id,
            class = "input",
            `type` = "text",
            placeholder = "例：rgrb もしくは abac",
            maxlength = "16",
            oninput = () => marathon.match($id.getVNodeById.getInputText),
            disabled = not marathon.isReady,
          )
