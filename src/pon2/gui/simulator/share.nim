## This module implements share views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[asyncjs, jsffi, strformat, sugar, uri]
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[assign, dom, gui, utils]

  export vdom

  const RuleDescs: array[Rule, string] = ["", "すいちゅう"]

  proc toXLink[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): Uri =
    ## Returns the URI to post to X.
    var uri = initUri()
    uri.scheme.assign "https"
    uri.hostname.assign "x.com"
    uri.path.assign "/intent/tweet"
      # NOTE: "/intent/post" does not work correctly on mobile

    var queries = newSeqOfCap[(string, string)](3)
    queries.add ("url", $self.derefSimulator(helper).toExportUri.unsafeValue)

    self.derefSimulator(helper).nazoPuyoWrap.unwrap:
      if it.goal != NoneGoal:
        let
          ruleDesc = RuleDescs[it.puyoPuyo.field.rule]
          moveCount = it.puyoPuyo.steps.len
          goalDesc = $it.goal

        queries.add ("text", "{ruleDesc}{moveCount}手・{goalDesc}".fmt)
        queries.add ("hashtags", "なぞぷよ")

    uri.query.assign queries.encodeQuery

    uri

  proc downloadCameraReadyImg(helper: VNodeHelper) =
    let cameraReadyElem = helper.simulator.cameraReadyId.getElemJsObjById
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
            elem.download = "pon2.png".cstring
            elem.target = "_blank".cstring
            elem.click()
        )
      ).catch
    {.pop.}

  proc toShareVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the share node.
    let
      noPlacementsUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作無"
      uriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作有"

    noPlacementsUriCopyBtn.addCopyBtnHandler () =>
      $self.derefSimulator(helper).toExportUri.unsafeValue
    uriCopyBtn.addCopyBtnHandler () =>
      $self.derefSimulator(helper).toExportUri(clearPlacements = false).unsafeValue

    let noPlacementsEditorUriCopyBtn, editorUriCopyBtn: VNode
    if self.derefSimulator(helper).mode in EditorModes:
      noPlacementsEditorUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作無"
      editorUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作有"

      noPlacementsEditorUriCopyBtn.addCopyBtnHandler () =>
        $self.derefSimulator(helper).toExportUri(viewer = false).unsafeValue
      editorUriCopyBtn.addCopyBtnHandler () =>
        $self
        .derefSimulator(helper)
        .toExportUri(viewer = false, clearPlacements = false).unsafeValue
    else:
      noPlacementsEditorUriCopyBtn = nil
      editorUriCopyBtn = nil

    buildHtml tdiv:
      tdiv(class = "block"):
        tdiv(class = "field is-grouped"):
          tdiv(class = "control"):
            button(
              class = "button is-size-7", onclick = () => helper.downloadCameraReadyImg
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-download")
              span:
                text "画像"
          tdiv(class = "control"):
            a(
              class = "button is-size-7",
              target = "_blank",
              rel = "noopener noreferrer",
              href = cstring $self.toXLink helper,
            ):
              span(class = "icon"):
                italic(class = "fa-brands fa-x-twitter")
              span:
                text "投稿"
      tdiv(class = "block"):
        text "URLコピー"
        tdiv(class = "field is-grouped"):
          tdiv(class = "control"):
            noPlacementsUriCopyBtn
          tdiv(class = "control"):
            uriCopyBtn
      if self.derefSimulator(helper).mode in EditorModes:
        tdiv(class = "block"):
          text "編集者URLコピー"
          tdiv(class = "field is-grouped"):
            tdiv(class = "control"):
              noPlacementsEditorUriCopyBtn
            tdiv(class = "control"):
              editorUriCopyBtn
