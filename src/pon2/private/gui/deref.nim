## This module implements dereference functions used with helperes.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.push experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import ../../[app]
  import ../../gui/[helper]

  func derefSimulator*(self: ref Simulator, helper: VNodeHelper): var Simulator =
    ## Dereferences the simulator.
    self[]

  # NOTE: views rejects this procedure
  # ref: https://github.com/24ik/pon2/issues/224#issuecomment-3445207849
  {.pop.}
  proc derefSimulator*(self: ref Studio, helper: VNodeHelper): var Simulator =
    ## Dereferences the simulator.
    if helper.studioOpt.unsafeValue.isReplaySimulator:
      return self[].replaySimulator
    else:
      return self[].simulator

  {.push experimental: "views".}

  proc derefSimulator*(self: ref Marathon, helper: VNodeHelper): var Simulator =
    ## Dereferences the simulator.
    self[].simulator
