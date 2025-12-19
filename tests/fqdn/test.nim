{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[fqdn]

# ------------------------------------------------
# FQDN <-> string
# ------------------------------------------------

block: # parseSimulatorFqdn
  check "24ik.github.io".parseSimulatorFqdn == Pon2Result[SimulatorFqdn].ok Pon2
  check "ishikawapuyo.net".parseSimulatorFqdn ==
    Pon2Result[SimulatorFqdn].ok IshikawaPuyo
  check "ips.karou.jp".parseSimulatorFqdn == Pon2Result[SimulatorFqdn].ok Ips

  check "".parseSimulatorFqdn.isErr
