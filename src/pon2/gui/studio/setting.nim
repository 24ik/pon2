## This module implements studio settings views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type StudioSetting* = object ## Studio settings.
  fixIndices*: seq[int]
  allowDoubleIndices*: seq[int]

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[jsffi, strformat]
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[dom]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const
    FixIndicesIdPrefix = "pon2-studio-setting-fix-"
    AllowDoubleIndicesIdPrefix = "pon2-studio-setting-allowdouble-"

  func init(T: type StudioSetting, fixIndices, allowDoubleIndices: seq[int]): T =
    T(fixIndices: fixIndices, allowDoubleIndices: allowDoubleIndices)

  proc toStudioSettingsVNode*(self: ref Studio, helper: VNodeHelper): VNode =
    ## Returns the studio settings node.
    buildHtml tdiv:
      tdiv(class = "block"):
        bold:
          text "ツモ並べ替え設定"
        tdiv(class = "field"):
          tdiv(class = "control"):
            text "N手目を固定:"
            for stepIndex in 0 ..< self[].simulator.nazoPuyo.puyoPuyo.steps.len:
              label(class = "checkbox"):
                text "　{stepIndex + 1}".fmt.kstring
                input(
                  id =
                    FixIndicesIdPrefix & helper.studioOpt.unsafeValue.settingId &
                    ($stepIndex).kstring,
                  `type` = "checkbox",
                )
        tdiv(class = "field"):
          text "N手目をゾロ許可:"
          for stepIndex in 0 ..< self[].simulator.nazoPuyo.puyoPuyo.steps.len:
            label(class = "checkbox"):
              text "　{stepIndex + 1}".fmt.kstring
              input(
                id =
                  AllowDoubleIndicesIdPrefix & helper.studioOpt.unsafeValue.settingId &
                  ($stepIndex).kstring,
                `type` = "checkbox",
              )

  proc getStudioSetting*(helper: VNodeHelper): StudioSetting =
    ## Returns the studio settings.
    var
      stepIndex = 0
      fixIndices = newSeq[int]()
      allowDoubleIndices = newSeq[int]()
    while true:
      let
        idSuffix = helper.studioOpt.unsafeValue.settingId & ($stepIndex).kstring
        fixCheckbox = (FixIndicesIdPrefix & idSuffix).getElementById
        allowDoubleCheckbox = (AllowDoubleIndicesIdPrefix & idSuffix).getElementById
      if fixCheckbox.isNil or allowDoubleCheckbox.isNil:
        break

      if fixCheckbox.checked:
        fixIndices.add(stepIndex)
      if allowDoubleCheckbox.checked:
        allowDoubleIndices.add(stepIndex)

      stepIndex.inc

    StudioSetting.init(fixIndices, allowDoubleIndices)
