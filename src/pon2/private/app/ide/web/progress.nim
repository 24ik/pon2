## This module implements the progress bar.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import karax/[karaxdsl, kbase, vdom]
import ../../../../app/[ide]

proc newEditorProgressBarNode*(ide: Ide): VNode {.inline.} =
  ## Returns the editor progress bar node.
  let
    now = ide.progressBarData.now
    total = ide.progressBarData.total

  result = buildHtml(
    progress(class = "progress is-primary", value = kstring $now, max = kstring $total)
  ):
    text &"{now} / {total}"
