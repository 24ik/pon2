## This module implements helpers for Nazo Puyo Grimoire.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unicode]
import ../[assign]

func normalized*(str: string): string =
  ## Returns the normalized string.
  var normalized = str.len.newStringOfCap
  for rune in str.toRunes:
    var val = rune.int32

    # zenkaku -> hankaku
    if val == 0x3000: # zenkaku space -> hankaku space
      val.assign 0x0020
    elif val in 0xff01 .. 0xff5e: # zenkaku ascii -> hankaku ascii
      val -= 0xfee0

    # upper -> lower
    if val in 65 .. 90:
      val += 32

    # katakana -> hiragana
    if val in 0x30a1 .. 0x30f6:
      val -= 0x60

    normalized &= $val.Rune

  normalized
