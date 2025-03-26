{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[fqdn]
import ../../src/pon2/private/[results2]

proc main*() =
  # ------------------------------------------------
  # FQDN <-> string
  # ------------------------------------------------

  # parseIdeFqdn
  block:
    for fqdn in IdeFqdn:
      let fqdnRes = parseIdeFqdn $fqdn
      check fqdnRes == Res[IdeFqdn].ok fqdn

    check "".parseIdeFqdn.isErr
