## This module implements progress bars.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import suru

export suru

proc setup2*(pBar: var SuruBar) {.inline.} =
  ## Sets up the progress bar.
  try:
    pBar.setup
  except:
    discard

proc update2*(pBar: var SuruBar, delayNs = 8_000_000, idx: int = -1) {.inline.} =
  ## Updates the progress bar.
  try:
    pBar.update delayNs, idx
  except:
    discard

proc finish2*(pBar: var SuruBar) {.inline.} =
  ## Cleans up the progress bar.
  try:
    pBar.finish
  except:
    discard

proc fill*(pBar: var SingleSuruBar) {.inline.} =
  ## Fills the progress bar.
  pBar.inc pBar.total - pBar.progress

proc shutdown*(pBar: var SuruBar, idx = -1) {.inline.} =
  ## Completes the progress bar.
  if idx < 0:
    for singleBar in pBar.mitems:
      singleBar.fill
  else:
    pBar[idx].fill

  pBar.update2
  pBar.finish2
