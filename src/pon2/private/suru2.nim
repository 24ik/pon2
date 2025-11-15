## This module implements progress bars.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import suru

export suru except finish, setup, update

proc setup*(progressBar: var SuruBar) {.inline, noinit.} =
  ## Sets up the progress bar.
  try:
    suru.setup progressBar
  except:
    discard

proc update*(
    progressBar: var SuruBar, delayNs = 8_000_000, index: int = -1
) {.inline, noinit.} =
  ## Updates the progress bar.
  try:
    suru.update progressBar, delayNs, index
  except:
    discard

proc finish*(progressBar: var SuruBar) {.inline, noinit.} =
  ## Cleans up the progress bar.
  try:
    suru.finish progressBar
  except:
    discard

proc fill*(progressBar: var SingleSuruBar) {.inline, noinit.} =
  ## Fills the progress bar.
  progressBar.inc progressBar.total - progressBar.progress

proc shutdown*(progressBar: var SuruBar) {.inline, noinit.} =
  ## Completes the progress bar.
  for singleBar in progressBar.mitems:
    singleBar.fill

  progressBar.update
  progressBar.finish
