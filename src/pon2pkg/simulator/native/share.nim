## This module implements the share frame.
##

{.experimental: "strictDefs".}

import std/[browsers, sugar, uri]
import nigui
import ../[render, simulator]

type ShareControl* = ref object of LayoutContainer
  ## Share control.
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
  shareLabel.text = "URLをシェア"

  let shareButtonWithoutUrl = newButton()
  result.add shareButtonWithoutUrl
  shareButtonWithoutUrl.text = "𝕏 操作無URL"
  shareButtonWithoutUrl.onClick =
    (event: ClickEvent) => ($simulator[].toXLink false).openDefaultBrowser

  let shareButtonWithUrl = newButton()
  result.add shareButtonWithUrl
  shareButtonWithUrl.text = "𝕏 操作有URL"
  shareButtonWithUrl.onClick =
    (event: ClickEvent) => ($simulator[].toXLink true).openDefaultBrowser

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
    (event: ClickEvent) => (app.clipboardText = $simulator[].toUri false)

  let copyButtonWithUrl = newButton()
  copyButtons.add copyButtonWithUrl
  copyButtonWithUrl.text = "操作有"
  copyButtonWithUrl.onClick =
    (event: ClickEvent) => (app.clipboardText = $simulator[].toUri true)
