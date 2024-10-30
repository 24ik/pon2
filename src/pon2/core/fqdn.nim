## This module implements IDE's FQDN.
##
## Compile Options:
## | Option               | Description          | Default          |
## | -------------------- | -------------------- | ---------------- |
## | `-d:pon2.fqdn=<str>` | FQDN of the web IDE. | `24ik.github.io` |
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const Pon2Fqdn* {.define: "pon2.fqdn".} = "24ik.github.io"

type IdeFqdn* {.pure.} = enum
  ## FQDN of the web IDE.
  Pon2 = Pon2Fqdn
  Ishikawa = "ishikawapuyo.net"
  Ips = "ips.karou.jp"
