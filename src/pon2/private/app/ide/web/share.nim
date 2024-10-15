## This module implements the share node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, uri]
import karax/[karax, karaxdsl, kbase, kdom, vdom, vstyles]
import ../[common]
import ../../[misc]
import ../../simulator/web/[field, messages, pairs, requirement]
import ../../../../app/[ide, simulator]

const
  UrlCopyButtonIdPrefix = "pon2-ide-share-url-"
  PosUrlCopyButtonIdPrefix = "pon2-ide-share-pos-url-"
  EditorUrlCopyButtonIdPrefix = "pon2-ide-share-editor-url-"
  EditorPosUrlCopyButtonIdPrefix = "pon2-ide-share-editor-pos-url-"

  DisplayDivIdPrefix = "pon2-ide-share-display-"
  DisplayPairDivIdPrefix = "pon2-ide-share-display-pair-"
  DisplayPairPosDivIdPrefix = "pon2-ide-share-display-pair-pos-"

proc downloadDisplayImage(
  id: kstring
) {.
  importjs:
    &"""
const div = document.getElementById('{DisplayDivIdPrefix}' + (#));
div.style.display = 'block';
html2canvas(div).then((canvas) => {{
  div.style.display = 'none';

  const element = document.createElement('a');
  element.href = canvas.toDataURL();
  element.download = 'puyo.png';
  element.target = '_blank';
  element.click();
}});"""
.} ## Downloads the simulator image.

func newDownloadHandler(id: string, withPositions: bool): () -> void =
  ## Returns the handler for downloading.
  # NOTE: cannot inline due to lazy evaluation
  proc handler() =
    document.getElementById(kstring &"{DisplayPairDivIdPrefix}{id}").style.display =
      if withPositions: "none" else: "block"

    document.getElementById(kstring &"{DisplayPairPosDivIdPrefix}{id}").style.display =
      if withPositions: "block" else: "none"
    downloadDisplayImage id.kstring

  result = handler

proc toPlayUri(ide: Ide, withPositions: bool, editor = false): Uri {.inline.} =
  ## Returns the IDE URI for playing.
  let ide2 = ide.simulator.copy.newIde
  ide2.simulator.mode = if editor: PlayEditor else: Play

  result = ide2.toUri withPositions

proc newShareNode*(ide: Ide, id: string): VNode {.inline.} =
  ## Returns the share node.
  let
    urlCopyButtonId = &"{UrlCopyButtonIdPrefix}{id}"
    posUrlCopyButtonId = &"{PosUrlCopyButtonIdPrefix}{id}"
    editorUrlCopyButtonId = &"{EditorUrlCopyButtonIdPrefix}{id}"
    editorPosUrlCopyButtonId = &"{EditorPosUrlCopyButtonIdPrefix}{id}"

  result = buildHtml(tdiv):
    if ide.simulator.mode != View:
      tdiv(class = "block"):
        span(class = "icon"):
          italic(class = "fa-brands fa-x-twitter")
        span:
          text "でシェア"
        tdiv(class = "buttons"):
          a(
            class = "button is-size-7",
            target = "_blank",
            rel = "noopener noreferrer",
            href = kstring $ide.toXlink(withPositions = false),
          ):
            text "操作無"
          a(
            class = "button is-size-7",
            target = "_blank",
            rel = "noopener noreferrer",
            href = kstring $ide.toXlink(withPositions = true),
          ):
            text "操作有"
      tdiv(class = "block"):
        text "画像ダウンロード"
        tdiv(class = "buttons"):
          button(class = "button is-size-7", onclick = newDownloadHandler(id, false)):
            text "操作無"
          button(class = "button is-size-7", onclick = newDownloadHandler(id, true)):
            text "操作有"
      tdiv(class = "block"):
        text "URLコピー"
        tdiv(class = "buttons"):
          button(
            id = urlCopyButtonId.kstring,
            class = "button is-size-7",
            onclick = newCopyButtonHandler(
              () => $ide.toPlayUri(withPositions = false), urlCopyButtonId
            ),
          ):
            text "操作無"
          button(
            id = posUrlCopyButtonId.kstring,
            class = "button is-size-7",
            onclick = newCopyButtonHandler(
              () => $ide.toPlayUri(withPositions = true), posUrlCopyButtonId
            ),
          ):
            text "操作有"
    if ide.simulator.mode != SimulatorMode.Play:
      tdiv(class = "block"):
        text "編集者URLコピー"
        tdiv(class = "buttons"):
          button(
            id = editorUrlCopyButtonId.kstring,
            class = "button is-size-7",
            onclick = newCopyButtonHandler(
              () => $ide.toPlayUri(withPositions = false, editor = true),
              editorUrlCopyButtonId,
            ),
          ):
            text "操作無"
          button(
            id = editorPosUrlCopyButtonId.kstring,
            class = "button is-size-7",
            onclick = newCopyButtonHandler(
              () => $ide.toPlayUri(withPositions = true, editor = true),
              editorPosUrlCopyButtonId,
            ),
          ):
            text "操作有"
    tdiv(
      id = kstring &"{DisplayDivIdPrefix}{id}",
      style = style(StyleAttr.display, kstring"none"),
    ):
      tdiv(class = "block"):
        ide.simulator.newRequirementNode(true, id)
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              ide.simulator.newFieldNode(true)
            tdiv(class = "block"):
              ide.simulator.newMessagesNode
          tdiv(id = kstring &"{DisplayPairDivIdPrefix}{id}", class = "column is-narrow"):
            tdiv(class = "block"):
              ide.simulator.newPairsNode(true, false)
          tdiv(
            id = kstring &"{DisplayPairPosDivIdPrefix}{id}", class = "column is-narrow"
          ):
            tdiv(class = "block"):
              ide.simulator.newPairsNode(true, true)
