## This module implements the editor permute node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat]
import karax/[karaxdsl, kbase, kdom, vdom]
import ../../../../../apppkg/[editorpermuter, simulator]
import ../../../../../corepkg/[pair]

const
  AllowDoubleCheckboxIdPrefix = "pon2-permute-double"
  AllowLastDoubleCheckboxIdPrefix = "pon2-permute-lastdouble"
  FixMovesCheckboxIdPrefix = "pon2-permute-fixmoves"

proc initEditorPermuteNode*(editorPermuter: var EditorPermuter, id = ""): VNode
                           {.inline.} =
  ## Returns the editor permute node.
  buildHtml(tdiv(class = "field")):
    tdiv(class = "control"):
      label(class = "checkbox"):
        text "ゾロ"
        input(id = kstring &"{AllowDoubleCheckboxIdPrefix}{id}",
              `type` = "checkbox", checked = true)
      label(class = "checkbox"):
        text "　最終手ゾロ"
        input(id = kstring &"{AllowLastDoubleCheckboxIdPrefix}{id}",
              `type` = "checkbox")
      text "　N手目を固定:"
      for pairIdx in 0..<editorPermuter.simulator[].pairs.len:
        label(class = "checkbox"):
          text kstring &"　{pairIdx.succ}"
          input(id = kstring &"{FixMovesCheckboxIdPrefix}{id}{pairIdx}",
                `type` = "checkbox")

proc getPermuteData*(id: string, moveCount: Positive): tuple[
    fixMoves: seq[Positive], allowDouble: bool, allowLastDouble: bool]
    {.inline.} =
  ## Returns arguments for permuting.
  result.fixMoves = (1.Positive..moveCount.Positive).toSeq.filterIt(
    document.getElementById(
      kstring &"{FixMovesCheckboxIdPrefix}{id}{it.int.pred}").checked)
  result.allowDouble = document.getElementById(
    kstring &"{AllowDoubleCheckboxIdPrefix}{id}").checked
  result.allowLastDouble = document.getElementById(
    kstring &"{AllowLastDoubleCheckboxIdPrefix}{id}").checked
