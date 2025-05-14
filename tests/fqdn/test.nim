{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[fqdn]

# ------------------------------------------------
# FQDN <-> string
# ------------------------------------------------

block: # parseSimulatorFqdn
  for fqdn in SimulatorFqdn:
    let fqdnRes = parseSimulatorFqdn $fqdn
    check fqdnRes == Res[SimulatorFqdn].ok fqdn

  check "".parseSimulatorFqdn.isErr
