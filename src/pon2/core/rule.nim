## This module implements Puyo Puyo rules.
##
## Compile Options:
## | Option                                   | Description                         | Default  |
## | ---------------------------------------- | ----------------------------------- | -------- |
## | `-d:pon2.garbagerate.tsu=<int>`          | Garbage rate in Tsu rule.           | `70`     |
## | `-d:pon2.garbagerate.spinner=<int>`      | Garbage rate in Spinner rule.       | `120`    |
## | `-d:pon2.garbagerate.crossspinner=<int>` | Garbage rate in Cross Spinner rule. | `120`    |
## | `-d:pon2.garbagerate.water=<int>`        | Garbage rate in Water rule.         | `90`     |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ../private/[results2]

export results2

const
  TsuGarbageRate {.define: "pon2.garbagerate.tsu".} = 70
  SpinnerGarbageRate {.define: "pon2.garbagerate.spinner".} = 120
  CrossSpinnerGarbageRate {.define: "pon2.garbagerate.crossspinner".} = 120
  WaterGarbageRate {.define: "pon2.garbagerate.water".} = 90

static:
  doAssert TsuGarbageRate > 0
  doAssert SpinnerGarbageRate > 0
  doAssert CrossSpinnerGarbageRate > 0
  doAssert WaterGarbageRate > 0

type
  Rule* {.pure.} = enum ## Puyo Puyo rule.
    Tsu = "通"
    Spinner = "だいかいてん"
    CrossSpinner = "クロスかいてん"
    Water = "すいちゅう"

  Phys* {.pure.} = enum
    ## Puyo Puyo physics of fields.
    Tsu
    Water

  DeadRule* {.pure.} = enum
    ## Puyo Puyo rule of dead conditions.
    Tsu
    Fever
    Water

  Behaviour* = object ## Field behaviour.
    phys*: Phys
    dead*: DeadRule
    garbageRate*: int

const Behaviours*: array[Rule, Behaviour] = [
  Behaviour(phys: Phys.Tsu, dead: DeadRule.Tsu, garbageRate: TsuGarbageRate),
  Behaviour(phys: Phys.Tsu, dead: Fever, garbageRate: SpinnerGarbageRate),
  Behaviour(phys: Phys.Tsu, dead: Fever, garbageRate: CrossSpinnerGarbageRate),
  Behaviour(phys: Phys.Water, dead: DeadRule.Water, garbageRate: WaterGarbageRate),
]

# ------------------------------------------------
# Rule <-> string
# ------------------------------------------------

func parseRule*(str: string): StrErrorResult[Rule] {.inline, noinit.} =
  ## Returns the rule converted from the string representation.
  case str
  of $Rule.Tsu:
    ok Rule.Tsu
  of $Spinner:
    ok Spinner
  of $CrossSpinner:
    ok CrossSpinner
  of $Rule.Water:
    ok Rule.Water
  else:
    err "Invalid rule: {str}".fmt
