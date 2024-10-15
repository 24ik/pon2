## This module implements Puyo Puyo simulators for native backends.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import nigui
import ../[simulator]
import
  ../../private/app/simulator/native/[
    assets,
    field,
    immediatepairs,
    messages,
    operating as operatingModule,
    pairs as pairsModule,
    requirement,
    select,
  ]

type SimulatorControl* = ref object of LayoutContainer ## Root control of the simulator.

# ------------------------------------------------
# Control
# ------------------------------------------------

proc newSimulatorControl*(self: Simulator): SimulatorControl {.inline.} =
  ## Returns the simulator control.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init
  result.layout = Layout_Vertical

  # row=0
  let reqControl = self.newRequirementControl
  result.add reqControl

  # row=1
  let secondRow = newLayoutContainer Layout_Horizontal
  result.add secondRow

  # row=1, left
  let left = newLayoutContainer Layout_Vertical
  secondRow.add left

  let
    assets = newAssets()
    field = self.newFieldControl assets
    messages = self.newMessagesControl assets
  left.add self.newOperatingControl assets
  left.add field
  left.add messages
  left.add self.newSelectControl reqControl

  # row=1, center
  secondRow.add self.newImmediatePairsControl assets

  # row=1, right
  secondRow.add self.newPairsControl assets

  # set size
  reqControl.setWidth secondRow.naturalWidth
  messages.setWidth field.naturalWidth
