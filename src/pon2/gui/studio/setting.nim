## This module implements studio settings views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type StudioSetting* = object ## Studio settings.
  fixIndices*: seq[int]
  allowDoubleNotLast*: bool
  allowDoubleLast*: bool

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
    AllowDoubleNotLastIdPrefix = "pon2-studio-setting-double-"
    AllowDoubleLastIdPrefix = "pon2-studio-setting-lastdouble-"
    FixIndicesIdPrefix = "pon2-studio-setting-fix-"

  func init(
      T: type StudioSetting,
      fixIndices: seq[int],
      allowDoubleNotLast, allowDoubleLast: bool,
  ): T =
    T(
      fixIndices: fixIndices,
      allowDoubleNotLast: allowDoubleNotLast,
      allowDoubleLast: allowDoubleLast,
    )

  proc toStudioSettingsVNode*(self: ref Studio, helper: VNodeHelper): VNode =
    ## Returns the studio settings node.
    buildHtml tdiv:
      tdiv(class = "block"):
        bold:
          text "ツモ並べ替え設定"
        tdiv(class = "field"):
          tdiv(class = "control"):
            label(class = "checkbox"):
              text "ゾロ"
              input(
                id = AllowDoubleNotLastIdPrefix & helper.studioOpt.unsafeValue.settingId,
                `type` = "checkbox",
                checked = true,
              )
            label(class = "checkbox"):
              text "　最終手ゾロ"
              input(
                id = AllowDoubleLastIdPrefix & helper.studioOpt.unsafeValue.settingId,
                `type` = "checkbox",
              )
            text "　N手目を固定:"
            for stepIndex in 0 ..< self[].simulator.nazoPuyo.puyoPuyo.steps.len:
              label(class = "checkbox"):
                text "　{stepIndex.succ}".fmt.kstring
                input(
                  id =
                    FixIndicesIdPrefix & helper.studioOpt.unsafeValue.settingId &
                    ($stepIndex).kstring,
                  `type` = "checkbox",
                )

  proc getStudioSetting*(helper: VNodeHelper): StudioSetting =
    ## Returns the studio settings.
    var
      stepIndex = 0
      fixIndices = newSeq[int]()
    while true:
      let checkbox = (
        FixIndicesIdPrefix & helper.studioOpt.unsafeValue.settingId &
        ($stepIndex).kstring
      ).getElementById
      if checkbox.isNil:
        break

      if checkbox.checked:
        fixIndices.add(stepIndex)

      stepIndex.inc

    StudioSetting.init(
      fixIndices,
      (AllowDoubleNotLastIdPrefix & helper.studioOpt.unsafeValue.settingId).getElementById.checked,
      (AllowDoubleLastIdPrefix & helper.studioOpt.unsafeValue.settingId).getElementById.checked,
    )
