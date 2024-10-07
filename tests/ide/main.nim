{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[importutils, options, strformat, unittest, uri]
import ../../src/pon2/app/[ide, nazopuyo, simulator]
import
  ../../src/pon2/core/
    [field, fieldtype, fqdn, nazopuyo, pairposition, puyopuyo, requirement]

func parseNazoPuyo[F: TsuField or WaterField](
    query: string, operatingIdx: Natural, host = Pon2
): NazoPuyo[F] =
  result = parseNazoPuyo[F](query, host)
  block:
    result.puyoPuyo.type.privateAccess
    result.puyoPuyo.operatingIdx = operatingIdx

proc main*() =
  # ------------------------------------------------
  # IDE <-> URI
  # ------------------------------------------------

  # toUri, parseIde
  block:
    let
      mainQuery = "field=t-rrb&pairs=rgby12&req-kind=0&req-color=7"
      mainQueryNoPos = "field=t-rrb&pairs=rgby&req-kind=0&req-color=7"
      kindModeQuery = "kind=n&mode=e"
      uriStr = &"https://{Pon2}{IdeUriPath}?{kindModeQuery}&{mainQuery}"
      uriStrNoPos = &"https://{Pon2}{IdeUriPath}?{kindModeQuery}&{mainQueryNoPos}"
      ide = uriStr.parseUri.parseIde
      nazo = parseNazoPuyo[TsuField](mainQuery, Pon2)

    check ide.simulator[].nazoPuyoWrap == nazo.initNazoPuyoWrap
    check ide.simulator[].kind == Nazo
    check ide.simulator[].mode == Edit

    check ide.toUri(withPositions = true) == uriStr.parseUri
    check ide.toUri(withPositions = false) == uriStrNoPos.parseUri

    check ide.toUri(withPositions = true, fqdn = Ishikawa) ==
      "https://ishikawapuyo.net/simu/pn.html?1b_c1Ec__270".parseUri
