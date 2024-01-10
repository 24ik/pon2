## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[kbase, kdom]
import std/[sugar]

proc copyToClipboard*(text: kstring) {.importjs: "navigator.clipboard.writeText(#);".}
  ## Sets the text to the clipboard.

proc showFlashMessage*(element: Element, messageHtml: string,
                      timeoutMs = Natural 500) {.inline.} =
  ## Sets the flash message on the element for `timeoutMs` ms.
  let oldHtml = element.innerHTML
  element.innerHTML = messageHtml
  discard setTimeout(() => (element.innerHTML = oldHtml), timeoutMs)
