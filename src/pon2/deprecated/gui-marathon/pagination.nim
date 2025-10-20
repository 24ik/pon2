## This module implements the marathon pagination node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import karax/[karax, karaxdsl, vdom]
import ../[common]
import ../../../../app/[marathon]

proc newMarathonPaginationNode*(marathon: Marathon): VNode {.inline.} =
  ## Returns the marathon pagination node.
  let
    firstIdx = marathon.matchResult.pageIndex * MatchResultPairsCountPerPage + 1
    lastIdx = min(
      marathon.matchResult.pageIndex.succ * MatchResultPairsCountPerPage,
      marathon.matchResult.strings.len,
    )
    ratio = marathon.matchResult.strings.len / AllPairsCount
    pageTxt =
      if marathon.matchResult.strings.len > 0:
        &"{firstIdx}〜{lastIdx} / {marathon.matchResult.strings.len} " &
          &"({ratio * 100 : .1f}%)"
      else:
        "0 / 0 (0.0%)"

  result = buildHtml(nav(class = "pagination")):
    button(class = "button pagination-link", onclick = () => marathon.prevResultPage):
      span(class = "icon"):
        italic(class = "fa-solid fa-backward-step")
    button(class = "button pagination-link is-static"):
      text pageTxt
    button(class = "button pagination-link", onclick = () => marathon.nextResultPage):
      span(class = "icon"):
        italic(class = "fa-solid fa-forward-step")
