## This module implements the controller frame.
##

import sugar
import uri

import karax / [karax, karaxdsl, kbase, kdom, vdom]

import ../manager

const
  UriCopyButtonId = "pon2-button-uri"
  UriCopyMessageShowMs = 500

proc copyToClipboard(text: kstring) {.importjs:"navigator.clipboard.writeText(#);".}

proc showFlashMessage(element: Element, messageHtml: string, timeoutMs = Natural 500) {.inline.} =
  let oldHtml = element.innerHTML
  element.innerHTML = messageHtml
  discard setTimeout(() => (element.innerHTML = oldHtml), timeoutMs)

proc controllerFrame*(manager: var Manager): VNode {.inline.} =
  ## Returns the controller frame.
  return buildHtml(tdiv(class = "buttons")):
    button(
      class = (if manager.focusAnswer: "button is-selected is-primary" else: "button"),
      onclick = () => manager.toggleFocus,
    ):
      text "解答を操作"
    button(
      class = (if manager.solving: "button is-loading" else: "button"),
      disabled = manager.solving,
      onclick = () => manager.solve,
    ):
      text "解探索"
    button(
      id = UriCopyButtonId,
      class = "button",
      onclick = () => (
        let btn = document.getElementById(UriCopyButtonId);
        btn.disabled = true;
        copyToClipboard kstring $manager.toUri;
        btn.showFlashMessage(
          "<span class='icon'><i class='fa-solid fa-check'></i></span><span>コピー</span>", UriCopyMessageShowMs);
        discard setTimeout(() => (btn.disabled = false), UriCopyMessageShowMs))
    ):
      text "Pon!通URLをコピー"
