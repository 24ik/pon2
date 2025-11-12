## This module implements simulator's FQDNs.
##
## Compile Options:
## | Option               | Description                | Default          |
## | -------------------- | -------------------------- | ---------------- |
## | `-d:pon2.fqdn=<str>` | FQDN of the web simulator. | `24ik.github.io` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import ../private/[results2, tables2]

export results2

const Pon2Fqdn {.define: "pon2.fqdn".} = "24ik.github.io"

type SimulatorFqdn* {.pure.} = enum
  ## FQDN of the web simulator.
  Pon2 = Pon2Fqdn
  Ishikawa = "ishikawapuyo.net"
  Ips = "ips.karou.jp"

# ------------------------------------------------
# FQDN <-> string
# ------------------------------------------------

const StrToFqdn = collect:
  for fqdn in SimulatorFqdn:
    {$fqdn: fqdn}

func parseSimulatorFqdn*(str: string): Res[SimulatorFqdn] {.inline, noinit.} =
  ## Returns the FQDN converted from the string representation.
  StrToFqdn.getRes(str).context "Invalid FQDN: {str}".fmt
