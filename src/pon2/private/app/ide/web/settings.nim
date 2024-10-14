## This module implements the editor settings node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, strformat]
import karax/[karaxdsl, kbase, kdom, vdom]
import ../../../../app/[ide, nazopuyo, simulator]
import ../../../../core/[position]

const
  ParallelCountSelectIdPrefix = "pon2-ide-settings-parallel-"
  AllowDoubleCheckboxIdPrefix = "pon2-ide-settings-double-"
  AllowLastDoubleCheckboxIdPrefix = "pon2-ide-settings-lastdouble-"
  FixMovesCheckboxIdPrefix = "pon2-ide-settings-fixmoves-"

proc getParallelCount(
  id: kstring
): int {.
  importjs:
    &"document.getElementById('{ParallelCountSelectIdPrefix}' + (#)).selectedIndex + 1"
.} ## Returns the parallel count.

proc newEditorSettingsNode*(ide: Ide, id: string): VNode {.inline.} =
  ## Returns the editor settings node.
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
          let pairsPositions = ide.simulator[].nazoPuyoWrap.get:
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
  (
    parallelCount: id.getParallelCount,
    fixMoves: (1.Positive .. moveCount.Positive).toSeq.filterIt(
      document.getElementById(kstring &"{FixMovesCheckboxIdPrefix}{id}{it.int.pred}").checked
    ),
    allowDouble:
      document.getElementById(kstring &"{AllowDoubleCheckboxIdPrefix}{id}").checked,
    allowLastDouble:
      document.getElementById(kstring &"{AllowLastDoubleCheckboxIdPrefix}{id}").checked,
  )
