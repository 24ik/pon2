## This module implements helpers for Nazo Puyo Grimoire.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unicode]

func normalized*(str: string): string =
  ## Returns the normalized string.
  var normalized = str.len.newStringOfCap
  for rune in str.toRunes:
    let addStr = block:
      let val = rune.int32

      case val
      of 65 .. 90: # upper -> lower
        $(val + 32).Rune
      of 0x3000: # zenkaku space -> hankaku space
        $(0x0020.Rune)
      of 0xff01 .. 0xff5e: # zenkaku ascii -> hankaku ascii
        $(val - 0xfee0).Rune
      of 0x30a1 .. 0x30f6: # katakana -> hiragana
        $(val - 0x60).Rune
      else:
        $rune

    normalized &= addStr

  normalized
