## This module implements browser-related functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[browsers, uri]
import ./[results2]

export browsers, results2

proc openDefaultBrowser*(uri: Uri): Res[void] {.inline, noinit.} =
  ## Opens the default web browser with the given URI.
  try:
    ($uri).openDefaultBrowser
    ok()
  except IOError as ex:
    err ex.msg
