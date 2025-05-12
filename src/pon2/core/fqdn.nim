## This module implements IDE's FQDNs.
##
## Compile Options:
## | Option               | Description          | Default          |
## | -------------------- | -------------------- | ---------------- |
## | `-d:pon2.fqdn=<str>` | FQDN of the web IDE. | `24ik.github.io` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import ../private/[results2, tables2]

export results2

const Pon2Fqdn* {.define: "pon2.fqdn".} = "24ik.github.io"

type IdeFqdn* {.pure.} = enum
  ## FQDN of the web IDE.
  Pon2 = Pon2Fqdn
  Ishikawa = "ishikawapuyo.net"
  Ips = "ips.karou.jp"

# ------------------------------------------------
# FQDN <-> string
# ------------------------------------------------

const StrToFqdn = collect:
  for fqdn in IdeFqdn:
    {$fqdn: fqdn}

func parseIdeFqdn*(str: string): Res[IdeFqdn] {.inline.} =
  ## Returns the FQDN converted from the string representation.
  StrToFqdn.getRes(str).context "Invalid FQDN: {str}".fmt
