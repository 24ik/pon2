## This module implements the editor settings node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat]
import karax/[karaxdsl, kbase, kdom, vdom]
import ../../../../app/[gui, nazopuyo, simulator]
import ../../../../core/[position]

const
  ParallelCountSelectIdPrefix = "pon2-settings-parallel"
  AllowDoubleCheckboxIdPrefix = "pon2-settings-double"
  AllowLastDoubleCheckboxIdPrefix = "pon2-settings-lastdouble"
  FixMovesCheckboxIdPrefix = "pon2-settings-fixmoves"

proc getParallelCount(
  id: kstring
): int {.
  importjs:
    &"document.getElementById('{ParallelCountSelectIdPrefix}' + (#)).selectedIndex + 1"
.} ## Returns the parallel count.

proc initEditorSettingsNode*(
    guiApplication: ref GuiApplication, id = ""
): VNode {.inline.} =
  ## Returns the editor settings node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  buildHtml(tdiv):
    tdiv(class = "block"):
      button(class = "button is-static px-2"):
        text "並列数"
      tdiv(class = "select"):
        select(id = kstring &"{ParallelCountSelectIdPrefix}{id}"):
          for count in 1 .. AllPositions.card:
            option(selected = count == 6):
              text $count
    tdiv(class = "block"):
      bold:
        text "ツモ並べ替え設定"
      tdiv(class = "field"):
        tdiv(class = "control"):
          label(class = "checkbox"):
            text "ゾロ"
            input(
              id = kstring &"{AllowDoubleCheckboxIdPrefix}{id}",
              `type` = "checkbox",
              checked = true,
            )
          label(class = "checkbox"):
            text "　最終手ゾロ"
            input(
              id = kstring &"{AllowLastDoubleCheckboxIdPrefix}{id}", `type` = "checkbox"
            )
          text "　N手目を固定:"
          let pairsPositions = guiApplication[].simulator.nazoPuyoWrap.get:
            wrappedNazoPuyo.puyoPuyo.pairsPositions
          for pairIdx in 0 ..< pairsPositions.len:
            label(class = "checkbox"):
              text kstring &"　{pairIdx.succ}"
              input(
                id = kstring &"{FixMovesCheckboxIdPrefix}{id}{pairIdx}",
                `type` = "checkbox",
              )

proc getSettings*(
    id: string, moveCount: Positive
): tuple[
  parallelCount: int, fixMoves: seq[Positive], allowDouble: bool, allowLastDouble: bool
] {.inline.} =
  ## Returns editor settings.
  result.parallelCount = id.getParallelCount
  result.fixMoves = (1.Positive .. moveCount.Positive).toSeq.filterIt(
    document.getElementById(kstring &"{FixMovesCheckboxIdPrefix}{id}{it.int.pred}").checked
  )
  result.allowDouble =
    document.getElementById(kstring &"{AllowDoubleCheckboxIdPrefix}{id}").checked
  result.allowLastDouble =
    document.getElementById(kstring &"{AllowLastDoubleCheckboxIdPrefix}{id}").checked
