## This module implements studio settings views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type StudioSetting* = object ## Studio settings.
  fixIndices*: seq[int]
  allowDblNotLast*: bool
  allowDblLast*: bool

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[jsffi, strformat]
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[dom]

  export vdom

  const
    AllowDblNotLastIdPrefix = "pon2-studio-setting-dbl-"
    AllowDblLastIdPrefix = "pon2-studio-setting-lastdbl-"
    FixIndicesIdPrefix = "pon2-studio-setting-fix-"

  func init(
      T: type StudioSetting, fixIndices: seq[int], allowDblNotLast, allowDblLast: bool
  ): T =
    T(
      fixIndices: fixIndices,
      allowDblNotLast: allowDblNotLast,
      allowDblLast: allowDblLast,
    )

  proc toStudioSettingsVNode*(self: ref Studio, helper: VNodeHelper): VNode =
    ## Returns the studio settings node.
    let stepCnt = unwrapNazoPuyo self[].simulator.nazoPuyoWrap:
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
                id = AllowDblNotLastIdPrefix & helper.studioOpt.unsafeValue.settingId,
                `type` = "checkbox",
                checked = true,
              )
            label(class = "checkbox"):
              text "　最終手ゾロ"
              input(
                id = AllowDblLastIdPrefix & helper.studioOpt.unsafeValue.settingId,
                `type` = "checkbox",
              )
            text "　N手目を固定:"
            for stepIdx in 0 ..< stepCnt:
              label(class = "checkbox"):
                text "　{stepIdx.succ}".fmt.cstring
                input(
                  id =
                    FixIndicesIdPrefix & helper.studioOpt.unsafeValue.settingId &
                    ($stepIdx).cstring,
                  `type` = "checkbox",
                )

  proc getStudioSetting*(helper: VNodeHelper): StudioSetting =
    ## Returns the studio settings.
    var
      stepIdx = 0
      fixIndices = newSeq[int]()
    while true:
      let checkbox = (
        FixIndicesIdPrefix & helper.studioOpt.unsafeValue.settingId & ($stepIdx).cstring
      ).getElementById
      if checkbox.isNil:
        break

      if checkbox.checked:
        fixIndices.add(stepIdx)

      stepIdx.inc

    StudioSetting.init(
      fixIndices,
      (AllowDblNotLastIdPrefix & helper.studioOpt.unsafeValue.settingId).getElementById.checked,
      (AllowDblLastIdPrefix & helper.studioOpt.unsafeValue.settingId).getElementById.checked,
    )
