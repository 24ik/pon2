## This module implements the search bar for pairs database.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karaxdsl, vdom]

proc initSearchBarNode*: VNode {.inline.} =
  ## Returns the search bar node.
  buildHtml(tdiv(class = "control")):
    input(class = "input", `type` = "text", placeholder = "rgrb")
