## This module implements the search result for pairs DB.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, vdom]
import ../../[misc]
import ../../../../apppkg/[marathon, simulator]
import ../../../../corepkg/[pair]

const ShowPairCount = 8

proc initPlayHandler(marathon: var Marathon, pairsIdx: Natural): () -> void =
  ## Returns a new click handler for play buttons.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler =
    marathon.simulator[].reset true
    marathon.simulator[].pairs = marathon.matchPairsSeq[pairsIdx]
    marathon.simulator[].originalPairs = marathon.matchPairsSeq[pairsIdx]
    marathon.focusSimulator = true

  result = handler

proc initMarathonSearchResultNode*(marathon: var Marathon): VNode {.inline.} =
  ## Returns the search result node for pairs DB.
  result = buildHtml(table(class = "table")):
    tbody:
      let
        beginPairIdx =
          marathon.matchResultPageIdx * MatchResultPairsCountPerPage
        endPairIdx = min(
          marathon.matchResultPageIdx.succ * MatchResultPairsCountPerPage,
          marathon.matchPairsSeq.len)

      for pairsIdx in beginPairIdx..<endPairIdx:
        tr:
          td:
            button(class = "button is-size-7",
                   onclick = marathon.initPlayHandler pairsIdx):
              span(class = "icon"):
                italic(class = "fa-solid fa-gamepad")

          for pairIdx in 0..<ShowPairCount:
            let pair = marathon.matchPairsSeq[pairsIdx][pairIdx]

            td:
              figure(class = "image is-16x16"):
                img(src = pair.child.cellImageSrc)
              figure(class = "image is-16x16"):
                img(src = pair.axis.cellImageSrc)
