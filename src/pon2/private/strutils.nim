## This module implements string utilities.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strutils]
import ../[utils]

export utils
export strutils except parseInt

func parseInt*(str: string): Pon2Result[int] {.inline, noinit.} =
  ## Returns the integer converted from the string.
  try:
    ok strutils.parseInt str
  except ValueError as ex:
    err ex.msg

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
