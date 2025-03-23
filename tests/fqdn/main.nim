{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import results
import ../../src/pon2/core/[fqdn]

proc main*() =
  # ------------------------------------------------
  # FQDN <-> string
  # ------------------------------------------------

  # parseIdeFqdn
  block:
    for fqdn in IdeFqdn:
      let fqdnRes = parseIdeFqdn $fqdn
      check fqdnRes.isOk and fqdnRes.value == fqdn

    check "".parseIdeFqdn.isErr
