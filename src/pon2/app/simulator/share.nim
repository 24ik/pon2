## This module implements share views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[strformat, sugar, uri]
  import karax/[karax, karaxdsl, kdom, vdom]
  import ../[nazopuyowrap, simulator]
  import ../../[core]
  import ../../private/app/simulator/[common]

type ShareView* = object ## View of the share.
  simulator: ref Simulator
  id: string

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type ShareView, simulator: ref Simulator, id: string): T {.inline.} =
  T(simulator: simulator, id: id)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    RuleDescs: array[Rule, string] = ["", "すいちゅう"]
    DisplayDivIdPrefix = "pon2-simulator-share-display-"

  func toXLink(self: ShareView): Uri {.inline.} =
    ## Returns the URI to post to X.
    var uri = initUri()
    uri.scheme = "https"
    uri.hostname = "x.com"
    uri.path = "/intent/tweet" # NOTE: "/intent/post" does not work correctly

    var queries = newSeqOfCap[(string, string)](3)
    queries.add ("url", $self.simulator[].toUri(clearPlacements = true))

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

  proc downloadDisplayImg(
    id: cstring
  ) {.
    importjs:
      """
const div = document.getElementById('{DisplayDivIdPrefix}' + (#));
div.style.display = 'block';
html2canvas(div, {{scale: 3}}).then((canvas) => {{
  div.style.display = 'none';

  const elem = document.createElement('a');
  elem.href = canvas.toDataURL();
  elem.download = 'pon2sim.png';
  elem.target = '_blank';
  elem.click();
}}).catch((err) => {{
  console.error(err);
}});""".fmt
  .} ## Downloads the simulator image in the display div.

  proc toVNodes*(self: ShareView): tuple[share: VNode, display: VNode] {.inline.} =
    ## Returns the share node and display node.
    let
      noPlcmtsUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作無"
      uriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作有"

    noPlcmtsUriCopyBtn.addCopyBtnHandler () =>
      $self.simulator[].toUri(clearPlacements = true)
    uriCopyBtn.addCopyBtnHandler () => $self.simulator[].toUri(clearPlacements = false)

    let noPlcmtsEditorUriCopyBtn, editorUriCopyBtn: VNode
    if self.simulator[].mode in EditorModes:
      noPlcmtsEditorUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作無"
      editorUriCopyBtn = buildHtml button(class = "button is-size-7"):
        text "操作有"

      noPlcmtsEditorUriCopyBtn.addCopyBtnHandler () =>
        $self.simulator[].toUri(clearPlacements = true)
      editorUriCopyBtn.addCopyBtnHandler () =>
        $self.simulator[].toUri(clearPlacements = false)
    else:
      noPlcmtsEditorUriCopyBtn = nil
      editorUriCopyBtn = nil

    let shareNode = buildHtml tdiv:
      tdiv(class = "block"):
        tdiv(class = "buttons"):
          button(
            class = "button is-size-7",
            onclick =
              () => (
                block:
                  "".getElementById.style.display = "block"
                  self.id.cstring.downloadDisplayImg
              ),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-download")
          a(
            class = "button is-size-7",
            target = "_blank",
            rel = "noopener noreferrer",
            href = cstring $self.toXLink,
          ):
            span(class = "icon"):
              italic(class = "fa-brands fa-x-twitter")
      tdiv(class = "block"):
        text "URLコピー"
        tdiv(class = "buttons"):
          noPlcmtsUriCopyBtn
          uriCopyBtn
      if self.simulator[].mode in EditorModes:
        tdiv(class = "block"):
          text "編集者URLコピー"
          noPlcmtsEditorUriCopyBtn
          editorUriCopyBtn

    (shareNode, shareNode) # TODO
