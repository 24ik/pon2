## This module implements the share node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, uri]
import karax/[karax, karaxdsl, kbase, kdom, vdom, vstyles]
import ./[field, pairs, requirement]
import ../[render]
import ../../[misc]
import ../../../../apppkg/[simulator]

const
  UrlCopyButtonIdPrefix = "pon2-share-url"
  PosUrlCopyButtonIdPrefix = "pon2-share-pos-url"
  EditorUrlCopyButtonIdPrefix = "pon2-share-editor-url"
  EditorPosUrlCopyButtonIdPrefix = "pon2-share-editor-pos-url"

  DisplayDivIdPrefix = "pon2-share-display"
  DisplayPairDivIdPrefix = "pon2-share-display-pair"
  DisplayPairPosDivIdPrefix = "pon2-share-display-pair-pos"

proc downloadDisplayImage(id: kstring) {.importjs: &"""
const div = document.getElementById('{DisplayDivIdPrefix}' + (#));
div.style.display = 'block';
html2canvas(div).then((canvas) => {{
  div.style.display = 'none';

  const element = document.createElement('a');
  element.href = canvas.toDataURL();
  element.download = 'puyo.png';
  element.target = '_blank';
  element.click();
}});""".} ## Downloads the simulator image.

func initDownloadHandler(id: string, withPositions: bool): () -> void =
  ## Returns the handler for downloading.
  # NOTE: cannot inline due to lazy evaluation
  proc handler =
    document.getElementById(kstring &"{DisplayPairDivIdPrefix}{id}").
      style.display = if withPositions: "none" else: "block"
    document.getElementById(kstring &"{DisplayPairPosDivIdPrefix}{id}").
      style.display = if withPositions: "block" else: "none"
    downloadDisplayImage id.kstring

  result = handler

proc initShareNode*(simulator: var Simulator, id = ""): VNode {.inline.} =
  ## Returns the share node.
  let
    urlCopyButtonId = &"{UrlCopyButtonIdPrefix}{id}"
    posUrlCopyButtonId = &"{PosUrlCopyButtonIdPrefix}{id}"
    editorUrlCopyButtonId = &"{EditorUrlCopyButtonIdPrefix}{id}"
    editorPosUrlCopyButtonId = &"{EditorPosUrlCopyButtonIdPrefix}{id}"

  result = buildHtml(tdiv):
    tdiv(class = "block"):
      span(class = "icon"):
        italic(class = "fa-brands fa-x-twitter")
      span:
        text "でシェア"
      tdiv(class = "buttons"):
        a(class = "button is-size-7", target = "_blank",
          rel = "noopener noreferrer", href = kstring $simulator.toXlink false):
          text "操作無"
        a(class = "button is-size-7", target = "_blank",
          rel = "noopener noreferrer", href = kstring $simulator.toXlink true):
          text "操作有"
    tdiv(class = "block"):
      text "画像ダウンロード"
      tdiv(class = "buttons"):
        button(class = "button is-size-7",
               onclick = initDownloadHandler(id, false)):
          text "操作無"
        button(class = "button is-size-7",
               onclick = initDownloadHandler(id, true)):
          text "操作有"
    tdiv(class = "block"):
      text "URLコピー"
      tdiv(class = "buttons"):
        button(id = urlCopyButtonId.kstring, class = "button is-size-7",
               onclick = initCopyButtonHandler(
                () => $simulator.toUri(false, false), urlCopyButtonId)):
          text "操作無"
        button(id = posUrlCopyButtonId.kstring, class = "button is-size-7",
               onclick = initCopyButtonHandler(
                () => $simulator.toUri(false, true), posUrlCopyButtonId)):
          text "操作有"
    if simulator.editor:
      tdiv(class = "block"):
        text "編集者URLコピー"
        tdiv(class = "buttons"):
          button(id = editorUrlCopyButtonId.kstring, class = "button is-size-7",
                 onclick = initCopyButtonHandler(
                   () => $simulator.toUri(true, false), editorUrlCopyButtonId)):
            text "操作無"
          button(id = editorPosUrlCopyButtonId.kstring,
                 class = "button is-size-7",
                 onclick = initCopyButtonHandler(
                   () => $simulator.toUri(true, true),
                   editorPosUrlCopyButtonId)):
            text "操作有"
    tdiv(id = kstring &"{DisplayDivIdPrefix}{id}",
         style = style(StyleAttr.display, kstring"none")):
      tdiv(class = "block"):
        simulator.initRequirementNode(true, id)
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.initFieldNode(true)
          tdiv(id = kstring &"{DisplayPairDivIdPrefix}{id}",
               class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.initPairsNode(true, false)
          tdiv(id = kstring &"{DisplayPairPosDivIdPrefix}{id}",
               class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.initPairsNode(true, true)
