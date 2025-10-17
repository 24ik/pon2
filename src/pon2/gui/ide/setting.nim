## This module implements IDE settings views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[strformat]
  import karax/[kdom, karaxdsl, vdom]

type
  IdeSettingView* = object ## View of the IDE settings.
    ide: ref Ide

  IdeSetting* = object ## IDE settings.
    fixIndices*: seq[int]
    allowDblNotLast*: bool
    allowDblLast*: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type IdeSettingView, ide: ref Ide): T {.inline.} =
  T(ide: ide)

func init(
    T: type IdeSetting, fixIndices: seq[int], allowDblNotLast, allowDblLast: bool
): T {.inline.} =
  T(
    fixIndices: fixIndices, allowDblNotLast: allowDblNotLast, allowDblLast: allowDblLast
  )

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    AllowDblNotLastIdPrefix = "pon2-ide-setting-dbl-"
    AllowDblLastIdPrefix = "pon2-ide-setting-lastdbl-"
    FixIndicesIdPrefix = "pon2-ide-setting-fix-"

  proc toVNode*(self: IdeSettingView, id: cstring): VNode {.inline.} =
    ## Returns the IDE settings node.
    let stepCnt = runIt self.ide[].simulator[].nazoPuyoWrap:
      it.steps.len

    buildHtml tdiv:
      tdiv(class = "block"):
        bold:
          text "ツモ並べ替え設定"
        tdiv(class = "field"):
          tdiv(class = "control"):
            label(class = "checkbox"):
              text "ゾロ"
              input(
                id = "{AllowDblNotLastIdPrefix}{id}".fmt.cstring,
                `type` = "checkbox",
                checked = true,
              )
            label(class = "checkbox"):
              text "　最終手ゾロ"
              input(id = "{AllowDblLastIdPrefix}{id}".fmt.cstring, `type` = "checkbox")
            text "　N手目を固定:"
            for stepIdx in 0 ..< stepCnt:
              label(class = "checkbox"):
                text "　{stepIdx.succ}".fmt.cstring
                input(
                  id = "{FixIndicesIdPrefix}{id}{stepIdx}".fmt.cstring,
                  `type` = "checkbox",
                )

  proc getIdeSetting*(id: cstring): IdeSetting {.inline.} =
    ## Returns the IDE settings.
    var
      stepIdx = 0
      fixIndices = newSeq[int]()
    while true:
      let checkbox = "{FixIndicesIdPrefix}{id}{stepIdx}".fmt.cstring.getElementById
      if checkbox.isNil:
        break

      if checkbox.checked:
        fixIndices.add(stepIdx)

      stepIdx.inc

    IdeSetting.init(
      fixIndices, "{AllowDblNotLastIdPrefix}{id}".fmt.cstring.getElementById.checked,
      "{AllowDblLastIdPrefix}{id}".fmt.cstring.getElementById.checked,
    )
