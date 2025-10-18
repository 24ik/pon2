## This module implements share views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[asyncjs, jsffi, strformat, sugar, uri]
  import karax/[karax, karaxdsl, vdom]
  import ../../[core]
  import ../../private/[tables2, utils]
  import ../../private/gui/[simulator]

type ShareView* = object ## View of the share.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type ShareView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const RuleDescs: array[Rule, string] = ["", "すいちゅう"]

  func toUri(self: ShareView): Uri {.inline.} =
    ## Returns the URI of the simulator before any moves.
    "TODO".parseUri

  func toXLink(self: ShareView): Uri {.inline.} =
    ## Returns the URI to post to X.
    var uri = initUri()
    uri.scheme = "https"
    uri.hostname = "x.com"
    uri.path = "/intent/tweet" # NOTE: "/intent/post" does not work correctly on mobile

    var queries = newSeqOfCap[(string, string)](3)
    queries.add ("url", $self.simulator[].toExportUri.unsafeValue)

    if self.simulator[].nazoPuyoWrap.optGoal.isOk:
      self.simulator[].nazoPuyoWrap.runIt:
        let
          ruleDesc = RuleDescs[it.field.rule]
          moveCnt = it.steps.len
          goalDesc = $self.simulator[].nazoPuyoWrap.optGoal.unsafeValue

        queries.add ("text", "{ruleDesc}{moveCnt}手・{goalDesc}".fmt)
        queries.add ("hashtags", "なぞぷよ")

    uri.query = queries.encodeQuery

    uri

  proc downloadCameraReadyImg(cameraReadyId: cstring) =
    let cameraReadyElem = cameraReadyId.getElemJsObjById
    cameraReadyElem.style.display = "block".cstring

    {.push warning[Uninit]: off.}
    discard cameraReadyElem
      .html2canvas(scale = 3)
      .then(
        (canvas: JsObject) => (
          block:
            cameraReadyElem.style.display = "none".cstring

            let elem = "a".createElemJsObj
            elem.href = canvas.toDataURL()
            elem.download = "pon2sim.png".cstring
            elem.target = "_blank".cstring
            elem.click()
        )
      ).catch
    {.pop.}

  proc toVNode*(self: ShareView, cameraReadyId: cstring): VNode {.inline.} =
    ## Returns the share node.
    let
      noPlcmtsUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作無"
      uriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作有"

    noPlcmtsUriCopyBtn.addCopyBtnHandler () => $self.simulator[].toExportUri.unsafeValue
    uriCopyBtn.addCopyBtnHandler () =>
      $self.simulator[].toExportUri(clearPlacements = false).unsafeValue

    let noPlcmtsEditorUriCopyBtn, editorUriCopyBtn: VNode
    if self.simulator[].mode in EditorModes:
      noPlcmtsEditorUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作無"
      editorUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作有"

      noPlcmtsEditorUriCopyBtn.addCopyBtnHandler () =>
        $self.simulator[].toExportUri(viewer = false).unsafeValue
      editorUriCopyBtn.addCopyBtnHandler () =>
        $self.simulator[].toExportUri(viewer = false, clearPlacements = false).unsafeValue
    else:
      # TODO
      noPlcmtsEditorUriCopyBtn = nil
      editorUriCopyBtn = nil

    buildHtml tdiv:
      tdiv(class = "block"):
        tdiv(class = "buttons"):
          button(
            class = "button is-size-7",
            onclick = () => cameraReadyId.downloadCameraReadyImg,
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-download")
            span:
              text "画像"
          a(
            class = "button is-size-7",
            target = "_blank",
            rel = "noopener noreferrer",
            href = cstring $self.toXLink,
          ):
            span(class = "icon"):
              italic(class = "fa-brands fa-x-twitter")
            span:
              text "投稿"
      tdiv(class = "block"):
        text "URLコピー"
        tdiv(class = "buttons"):
          noPlcmtsUriCopyBtn
          uriCopyBtn
      if self.simulator[].mode in EditorModes:
        tdiv(class = "block"):
          text "編集者URLコピー"
          tdiv(class = "buttons"):
            noPlcmtsEditorUriCopyBtn
            editorUriCopyBtn
