## This module implements browser-related functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[browsers]
import ./[uri]
import ../[utils]

export browsers, utils

proc openDefaultBrowser*(uri: Uri): Pon2Result[void] {.inline, noinit.} =
  ## Opens the default web browser with the given URI.
  try:
    ($uri).openDefaultBrowser
    ok()
  except IOError as ex:
    err ex.msg
