## This module implements the search bar for pairs DB.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../apppkg/[marathon]

const InputIdPrefix = "pon2-pairs-input"

proc initMarathonSearchBarNode*(
    marathon: var Marathon, id = ""): VNode {.inline.} =
  ## Returns the search bar node for pairs DB.
  let inputId = kstring &"{InputIdPrefix}{id}"

  result = buildHtml(tdiv(class = "field is-horizontal")):
    tdiv(class = "field-label is-normal"):
      label(class = "label"):
        text "ツモ"
    tdiv(class = "field-body"):
      tdiv(class = "field"):
        tdiv(class = "control"):
          input(id = inputId, class = "input", `type` = "text",
                placeholder = "例：rgrb もしくは abac", maxlength = "16",
                oninput = () => marathon.match($inputId.getVNodeById.value))
