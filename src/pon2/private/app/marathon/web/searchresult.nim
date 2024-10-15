## This module implements the search result for pairs DB.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sugar]
import karax/[karax, karaxdsl, vdom]
import ../[common]
import ../../[misc]
import ../../../../app/[marathon]
import ../../../../core/[pair, pairposition]

const ShowPairCount = 8

func newPlayHandler(marathon: Marathon, pairsIdx: Natural): () -> void =
  ## Returns a new click handler for play buttons.
  # NOTE: inlining does not work due to lazy evaluation
  () => (marathon.play pairsIdx)

proc newMarathonSearchResultNode*(marathon: Marathon): VNode {.inline.} =
  ## Returns the search result node for pairs DB.
  result = buildHtml(table(class = "table")):
    tbody:
      let
        beginPairIdx = marathon.matchResult.pageIndex * MatchResultPairsCountPerPage
        endPairIdx = min(
          marathon.matchResult.pageIndex.succ * MatchResultPairsCountPerPage,
          marathon.matchResult.strings.len,
        )

      for pairsIdx in beginPairIdx ..< endPairIdx:
        tr:
          td:
            button(
              class = "button is-size-7", onclick = marathon.newPlayHandler pairsIdx
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-gamepad")

          let pairsPositions =
            marathon.matchResult.strings[pairsIdx][0 ..< ShowPairCount * 2].toPairsPositions
          for idx in 0 ..< ShowPairCount:
            let pair = pairsPositions[idx].pair

            td:
              figure(class = "image is-16x16"):
                img(src = pair.child.cellImageSrc)
              figure(class = "image is-16x16"):
                img(src = pair.axis.cellImageSrc)
