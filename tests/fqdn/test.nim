{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[fqdn]

# ------------------------------------------------
# FQDN <-> string
# ------------------------------------------------

block: # parseIdeFqdn
  for fqdn in IdeFqdn:
    let fqdnRes = parseIdeFqdn $fqdn
    check fqdnRes == Res[IdeFqdn].ok fqdn

  check "".parseIdeFqdn.isErr
