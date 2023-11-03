## This module implements the share frame.
##

{.experimental: "strictDefs".}

import std/[strformat, sugar, tables, uri]
import karax/[karax, karaxdsl, kbase, kdom, vdom, vstyles]
import ./[field, pairs, requirement]
import ../[render, simulator]

const
  UrlCopyButtonIdPrefix = "puyo-simulator-button-url"
  PosUrlCopyButtonIdPrefix = "puyo-simulator-button-url-pos"

  SimpleDivIdPrefix = "puyo-simulator-div-simple"
  SimplePairDivIdPrefix = "puyo-simulator-div-simple-pair"
  SimplePairPosDivIdPrefix = "puyo-simulator-div-simple-pair-pos"

  UrlCopyMessageShowMs = 500

proc downloadSimpleImage(idx: int) {.importjs: &"""
const div = document.getElementById('{SimpleDivIdPrefix}' + (#));
div.style.display = 'block';
html2canvas(div).then((canvas) => {{
  div.style.display = 'none';

  const element = document.createElement('a');
  element.href = canvas.toDataURL();
  element.download = 'puyo.png';
  element.target = '_blank';
  element.click();
}});""".} ## Downloads the simulator image.

func initDownloadHandler(idx: int, withPositions: bool): () -> void =
  ## Returns the handler for downloading.
  () => (
    block:
      document.getElementById(
        cstring &"{SimplePairDivIdPrefix}{idx}").style.display = (
          if withPositions: "none" else: "block")
      document.getElementById(
        cstring &"{SimplePairPosDivIdPrefix}{idx}").style.display = (
          if withPositions: "block" else: "none")
      downloadSimpleImage(idx))

proc showFlashMessage(element: Element, messageHtml: string,
                      timeoutMs = Natural 500) {.inline.} =
  ## Shows the flash message to the given element.
  let oldHtml = element.innerHTML
  element.innerHTML = messageHtml
  discard setTimeout(() => (element.innerHTML = oldHtml), timeoutMs)

proc copyToClipboard(text: cstring)
  {.importjs: "navigator.clipboard.writeText(#);".}
  ## Stores the text to the clipboard.

#[
HACK: We want to use `func` version.
It works on the first call, but an error occurs on the second call.
The direct cause is access to `undefined`, but the root cause is unknown.
It appears that `simulator` becomes `undefined` on the second call.
So, as a workaround, we store `simulator` in the global container and use it
in the second call.

func initCopyHandler(simulator: Simulator, idx: int,
                     withPosition: bool): () -> void =
  ## Returns the handler for copying URI.
  () => (
    block:
      let
        idPrefix =
          if withPosition: UrlCopyButtonIdPrefix else: PosUrlCopyButtonIdPrefix
        btn = document.getElementById(cstring &"{idPrefix}{idx}")
      btn.disabled = true

      copyToClipboard cstring $simulator.toUri false

      btn.showFlashMessage(
        "<span class='icon'><i class='fa-solid fa-check'></i></span>" &
        "<span>コピー</span>",
        UrlCopyMessageShowMs)
      discard setTimeout(() => (btn.disabled = false), UrlCopyMessageShowMs))
]#
var globalSimulators = initTable[int, Simulator]()
proc initCopyHandler(simulator: Simulator, idx: int,
                     withPositions: bool): () -> void =
  ## Returns the handler for copying URI.
  if idx notin globalSimulators:
    globalSimulators[idx] = simulator

  () => (
    block:
      let
        idPrefix =
          if withPositions: PosUrlCopyButtonIdPrefix else: UrlCopyButtonIdPrefix
        btn = document.getElementById(cstring &"{idPrefix}{idx}")
      btn.disabled = true

      copyToClipboard cstring $globalSimulators[idx].toUri withPositions

      btn.showFlashMessage(
        "<span class='icon'><i class='fa-solid fa-check'></i></span>" &
        "<span>コピー</span>",
        UrlCopyMessageShowMs)
      discard setTimeout(() => (btn.disabled = false), UrlCopyMessageShowMs))

proc shareFrame*(simulator: var Simulator, idx = 0): VNode {.inline.} =
  ## Returns the share frame.
  buildHtml(tdiv):
    tdiv(class = "block"):
      text "URLをシェア"
      tdiv:
        a(class = "button", target = "_blank", rel = "noopener noreferrer",
          href = kstring $simulator.toXlink false):
          span(class = "icon"):
            italic(class = "fa-brands fa-x-twitter")
          span:
            text "操作無URL"
      tdiv:
        a(class = "button", target = "_blank", rel = "noopener noreferrer",
          href = kstring $simulator.toXlink true):
          span(class = "icon"):
            italic(class = "fa-brands fa-x-twitter")
          span:
            text "操作有URL"
    tdiv(class = "block"):
      text "画像ダウンロード"
      tdiv(class = "buttons"):
        button(class = "button is-size-7",
               onclick = initDownloadHandler(idx, false)):
          text "操作無"
        button(class = "button is-size-7",
               onclick = initDownloadHandler(idx, true)):
          text "操作有"
    tdiv(class = "block"):
      text "URLコピー"
      tdiv(class = "buttons"):
        button(id = kstring &"{UrlCopyButtonIdPrefix}{idx}",
               class = "button is-size-7",
               onclick = simulator.initCopyHandler(idx, false)):
          text "操作無"
        button(id = kstring &"{PosUrlCopyButtonIdPrefix}{idx}",
               class = "button is-size-7",
               onclick = simulator.initCopyHandler(idx, true)):
          text "操作有"
    tdiv(id = kstring &"{SimpleDivIdPrefix}{idx}",
         style = style(StyleAttr.display, kstring"none")):
      tdiv(class = "block"):
        simulator.requirementFrame(true)
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.fieldFrame(true)
          tdiv(id = kstring &"{SimplePairDivIdPrefix}{idx}",
               class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.pairsFrame(true, false)
          tdiv(id = kstring &"{SimplePairPosDivIdPrefix}{idx}",
               class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.pairsFrame(true, true)
