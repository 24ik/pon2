## This module implements string utilities.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, strutils]
import ../[utils]

export utils
export strutils except parseInt

func safeParseInt(str: string): Pon2Result[int] {.inline, noinit.} =
  ## Returns the integer converted from the string.
  # NOTE: we cannot define this function as `parseInt` directly since `parseOrdinal`
  # uses this function and its `parseInt` calling causes ambiguous-calling error
  try:
    ok strutils.parseInt str
  except ValueError as ex:
    err ex.msg

func parseInt*(str: string): Pon2Result[int] {.inline, noinit.} =
  ## Returns the integer converted from the string.
  str.safeParseInt

func parseOrdinal*[T: Ordinal](str: string): Pon2Result[T] {.inline, noinit.} =
  ## Returns the ordinal type converted from the string.
  let val = ?str.safeParseInt.context "Invalid ordinal: {str}".fmt

  if val in T.low.ord .. T.high.ord:
    ok val.T
  else:
    let typeDesc = $T
    err "Invalid ordinal (out of {typeDesc}'s range): {str}".fmt

func split2*(str, sep: string, maxsplit = -1): seq[string] {.inline, noinit.} =
  ## Returns a sequence of substrings by splitting the string with the given separator.
  ## If the string is empty, returns an empty sequence.
  if str == "":
    newSeq[string]()
  else:
    str.split(sep, maxsplit)

iterator split2*(str, sep: string, maxsplit = -1): string {.inline.} =
  ## Iterates over substrings by splitting the string with the given separator.
  ## If the string is empty, yields nothing.
  if str != "":
    for s in str.split(sep, maxsplit):
      yield s
