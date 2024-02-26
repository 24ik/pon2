## This module implements the share control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[browsers, sugar, uri]
import nigui
import ../[common]
import ../../../../app/[simulator]

type ShareControl* = ref object of LayoutContainer ## Share control.
  simulator: ref Simulator

proc initShareControl*(simulator: ref Simulator): ShareControl {.inline.} =
  ## Returns a share control.
  result = new ShareControl
  result.init
  result.layout = Layout_Vertical

  result.padding = 10.scaleToDpi
  result.spacing = 10.scaleToDpi

  result.simulator = simulator

  # share
  let shareLabel = newLabel()
  result.add shareLabel
  shareLabel.text = "𝕏でシェア"

  let shareButtonWithoutUrl = newButton()
  result.add shareButtonWithoutUrl
  shareButtonWithoutUrl.text = "操作無"
  shareButtonWithoutUrl.onClick =
    (event: ClickEvent) =>
    ($simulator[].toXLink(withPositions = false, editor = false)).openDefaultBrowser

  let shareButtonWithUrl = newButton()
  result.add shareButtonWithUrl
  shareButtonWithUrl.text = "操作有"
  shareButtonWithUrl.onClick =
    (event: ClickEvent) =>
    ($simulator[].toXLink(withPositions = true, editor = false)).openDefaultBrowser

  # copy URL
  let copyLabel = newLabel()
  result.add copyLabel
  copyLabel.text = "URLコピー"

  let copyButtons = newLayoutContainer Layout_Horizontal
  result.add copyButtons

  let copyButtonWithoutUrl = newButton()
  copyButtons.add copyButtonWithoutUrl
  copyButtonWithoutUrl.text = "操作無"
  copyButtonWithoutUrl.onClick =
    (event: ClickEvent) =>
    (app.clipboardText = $simulator[].toUri(withPositions = false, editor = false))

  let copyButtonWithUrl = newButton()
  copyButtons.add copyButtonWithUrl
  copyButtonWithUrl.text = "操作有"
  copyButtonWithUrl.onClick =
    (event: ClickEvent) =>
    (app.clipboardText = $simulator[].toUri(withPositions = true, editor = false))

  # copy URL (editor)
  let copyLabel = newLabel()
  result.add copyLabel
  copyLabel.text = "編集者URLコピー"

  let editorCopyButtons = newLayoutContainer Layout_Horizontal
  result.add editorCopyButtons

  let editorCopyButtonWithoutUrl = newButton()
  editorCopyButtons.add editorCopyButtonWithoutUrl
  editorCopyButtonWithoutUrl.text = "操作無"
  editorCopyButtonWithoutUrl.onClick =
    (event: ClickEvent) =>
    (app.clipboardText = $simulator[].toUri(withPositions = false, editor = true))

  let editorCopyButtonWithUrl = newButton()
  editorCopyButtons.add editorCopyButtonWithUrl
  editorCopyButtonWithUrl.text = "操作有"
  editorCopyButtonWithUrl.onClick =
    (event: ClickEvent) =>
    (app.clipboardText = $simulator[].toUri(withPositions = true, editor = true))
