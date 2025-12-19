## This module implements steps.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, sugar]
import ./[cell, common, fqdn, pair, placement]
import ../[utils]
import
  ../private/[arrayutils, assign, bitops, deques, math, staticfor, strutils, tables]

export deques, pair, placement, utils

type
  StepKind* {.pure.} = enum
    ## Discriminator for `Step`.
    PairPlace
    NuisanceDrop
    FieldRotate

  Step* = object ## Game step.
    case kind*: StepKind
    of PairPlace:
      pair*: Pair
      placement*: Placement
    of NuisanceDrop:
      counts*: array[Col, int]
      hard*: bool
    of FieldRotate:
      cross*: bool

  Steps* = Deque[Step] ## Sequence of steps.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Step, pair: Pair, placement = Placement.None): T {.inline, noinit.} =
  T(kind: PairPlace, pair: pair, placement: placement)

func init*(T: type Step, counts: array[Col, int], hard = false): T {.inline, noinit.} =
  T(kind: NuisanceDrop, counts: counts, hard: hard)

func init*(T: type Step, cross: bool): T {.inline, noinit.} =
  T(kind: FieldRotate, cross: cross)

func init*(T: type Step): T {.inline, noinit.} =
  T.init Pair.init

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(step1, step2: Step): bool {.inline, noinit.} =
  if step1.kind != step2.kind:
    return false

  case step1.kind
  of PairPlace:
    step1.pair == step2.pair and step1.placement == step2.placement
  of NuisanceDrop:
    step1.counts == step2.counts and step1.hard == step2.hard
  of FieldRotate:
    step2.kind == FieldRotate and step1.cross == step2.cross

# ------------------------------------------------
# Property
# ------------------------------------------------

func isValid*(self: Step, originalCompatible = false): bool {.inline, noinit.} =
  ## Returns `true` if the step is valid.
  case self.kind
  of PairPlace, FieldRotate:
    true
  of NuisanceDrop:
    if originalCompatible:
      let
        maxCount = self.counts.max
        minCount = self.counts.min

      0 <= minCount and maxCount <= 5 and maxCount - minCount <= 1
    else:
      self.counts.min >= 0

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*(self: Step, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the step.
  case self.kind
  of PairPlace:
    self.pair.cellCount cell
  of NuisanceDrop:
    if (cell == Hard and self.hard) or (cell == Garbage and not self.hard):
      self.counts.sum
    else:
      0
  of FieldRotate:
    0

func puyoCount*(self: Step): int {.inline, noinit.} =
  ## Returns the number of puyos in the step.
  case self.kind
  of PairPlace: 2
  of NuisanceDrop: self.counts.sum
  of FieldRotate: 0

func coloredPuyoCount*(self: Step): int {.inline, noinit.} =
  ## Returns the number of colored puyos in the step.
  case self.kind
  of PairPlace: 2
  of NuisanceDrop, FieldRotate: 0

func nuisancePuyoCount*(self: Step): int {.inline, noinit.} =
  ## Returns the number of nuisance puyos in the step.
  case self.kind
  of PairPlace, FieldRotate: 0
  of NuisanceDrop: self.counts.sum

func cellCount*(steps: Steps, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the steps.
  steps.sumIt it.cellCount cell

func puyoCount*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of puyos in the steps.
  steps.sumIt it.puyoCount

func coloredPuyoCount*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of color puyos in the steps.
  steps.sumIt it.coloredPuyoCount

func nuisancePuyoCount*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the steps.
  steps.sumIt it.nuisancePuyoCount

# ------------------------------------------------
# Step <-> string
# ------------------------------------------------

const
  PairPlaceSep = '|'
  GarbagePrefix = '('
  GarbageSuffix = ')'
  HardPrefix = '['
  HardSuffix = ']'
  NuisanceSep = ","
  RotateDesc = "R"
  CrossRotateDesc = "C"

func `$`*(self: Step): string {.inline, noinit.} =
  case self.kind
  of PairPlace:
    "{self.pair}{PairPlaceSep}{self.placement}".fmt
  of NuisanceDrop:
    let
      joined = self.counts.mapIt($it).join NuisanceSep
      prefix, suffix: char
    if self.hard:
      prefix = HardPrefix
      suffix = HardSuffix
    else:
      prefix = GarbagePrefix
      suffix = GarbageSuffix

    "{prefix}{joined}{suffix}".fmt
  of FieldRotate:
    if self.cross: CrossRotateDesc else: RotateDesc

func parseStep*(str: string): Pon2Result[Step] {.inline, noinit.} =
  ## Returns the step converted from the string representation.
  # rotate
  if str == RotateDesc:
    return ok Step.init(cross = false)
  if str == CrossRotateDesc:
    return ok Step.init(cross = true)

  # nuisance
  let
    garbageDrop = str.startsWith(GarbagePrefix) and str.endsWith(GarbageSuffix)
    hardDrop = str.startsWith(HardPrefix) and str.endsWith(HardSuffix)
  if garbageDrop or hardDrop:
    let errorMsg = "Invalid step (nuisance): {str}".fmt

    let strs = str[1 ..^ 2].split NuisanceSep
    if strs.len != Width:
      return err errorMsg

    let counts = collect:
      for s in strs:
        ?s.parseInt.context errorMsg
    return ok Step.init(
      [Col0: counts[0], counts[1], counts[2], counts[3], counts[4], counts[5]],
      hard = hardDrop,
    )

  # pair
  let errorMsg = "Invalid step: {str}".fmt

  let strs = str.split PairPlaceSep
  if strs.len != 2:
    return err errorMsg

  let
    pair = ?strs[0].parsePair.context errorMsg
    placement = ?strs[1].parsePlacement.context errorMsg

  ok Step.init(pair, placement)

# ------------------------------------------------
# Step <-> URI
# ------------------------------------------------

const
  GarbageWrapUri = ($Garbage)[0]
  HardWrapUri = ($Hard)[0]
  NuisanceSepUri = "_"
  MaxCountToIshikawaUri = "amyKW"
  ValToIshikawaUri = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"

func toUriQuery*(self: Step, fqdn = Pon2): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the step.
  case self.kind
  of PairPlace:
    ok "{self.pair.toUriQuery fqdn}{self.placement.toUriQuery fqdn}".fmt
  of NuisanceDrop:
    case fqdn
    of Pon2:
      let
        wrapper = if self.hard: HardWrapUri else: GarbageWrapUri
        joined = self.counts.mapIt($it).join NuisanceSepUri
      ok "{wrapper}{joined}{wrapper}".fmt
    of IshikawaPuyo, Ips:
      if self.hard or not self.isValid(originalCompatible = true):
        return err "Not supported step with IshikawaPuyo/Ips format: {self}".fmt

      let maxCount = self.counts.max
      if maxCount == 0:
        return ok "a0"

      let diffVal =
        Col.sumIt (self.counts[it] - maxCount + 1) * 2 ^ (Width - it.ord - 1)
      ok MaxCountToIshikawaUri[maxCount - 1] & ValToIshikawaUri[diffVal]
  of FieldRotate:
    case fqdn
    of Pon2:
      ok $self
    of IshikawaPuyo, Ips:
      err "Not supported step with IshikawaPuyo/Ips format: {self}".fmt

func parseStep*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[Step] {.inline, noinit.} =
  ## Returns the step converted from the URI query.
  case fqdn
  of Pon2:
    # rotate
    if query == RotateDesc:
      return ok Step.init(cross = false)
    if query == CrossRotateDesc:
      return ok Step.init(cross = true)

    # nuisance
    let
      garbageDrop = query.startsWith(GarbageWrapUri) and query.endsWith(GarbageWrapUri)
      hardDrop = query.startsWith(HardWrapUri) and query.endsWith(HardWrapUri)
    if garbageDrop or hardDrop:
      let errorMsg = "Invalid step (nuisance): {query}".fmt

      let strs = query[1 ..^ 2].split NuisanceSepUri
      if strs.len != Width:
        return err errorMsg

      let counts = collect:
        for s in strs:
          ?s.parseInt.context errorMsg
      return ok Step.init(
        [Col0: counts[0], counts[1], counts[2], counts[3], counts[4], counts[5]],
        hard = hardDrop,
      )

    # pair
    case query.len
    of 2:
      ok Step.init ?query.parsePair(fqdn).context "Invalid step (pair): {query}".fmt
    of 4:
      ok Step.init(
        ?query[0 ..< 2].parsePair(fqdn).context "Invalid step (pair): {query}".fmt,
        ?query[2 ..< 4].parsePlacement(fqdn).context(
          "Invalid step (placement): {query}".fmt
        ),
      )
    else:
      err "Invalid step: {query}".fmt
  of IshikawaPuyo, Ips:
    if query.len != 2:
      return err "Invalid step: {query}".fmt

    # nuisance
    if query == "a0":
      return ok Step.init [Col0: 0, 0, 0, 0, 0, 0]
    let maxCount = MaxCountToIshikawaUri.find(query[0]) + 1
    if maxCount > 0:
      let val = ValToIshikawaUri.find query[1]
      if val < 0:
        return err "Invalid step: {query}".fmt

      var counts = Col.initArrayWith maxCount - 1
      staticFor(col, Col):
        counts[col] += val.testBit(Width - col.ord - 1).int

      return ok Step.init counts

    # pair
    let
      pair = ?query[0 .. 0].parsePair(fqdn).context "Invalid step (pair): {query}".fmt
      placement =
        ?query[1 .. 1].parsePlacement(fqdn).context(
          "Invalid step (placement): {query}".fmt
        )
    ok Step.init(pair, placement)

# ------------------------------------------------
# Steps <-> string
# ------------------------------------------------

const StepsSep = "\n"

func `$`*(self: Steps): string {.inline, noinit.} =
  let strs = collect:
    for step in self:
      $step

  strs.join StepsSep

func parseSteps*(str: string): Pon2Result[Steps] {.inline, noinit.} =
  ## Returns the steps converted from the string representation.
  if str == "":
    return ok Steps.init

  let strs = str.split StepsSep

  var steps = Steps.init strs.len
  for s in strs:
    steps.addLast ?s.parseStep.context "Invalid steps: {str}".fmt

  ok steps

# ------------------------------------------------
# Steps <-> URI
# ------------------------------------------------

func toUriQuery*(self: Steps, fqdn = Pon2): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the steps.
  let strs = collect:
    for step in self:
      ?step.toUriQuery(fqdn).context "Invalid steps: {self}".fmt

  ok strs.join

func parseSteps*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[Steps] {.inline, noinit.} =
  ## Returns the steps converted from the URI query.
  let errorMsg = "Invalid steps: {query}".fmt

  case fqdn
  of Pon2:
    var
      index = 0
      steps = Steps.init
    while index < query.len:
      case query[index]
      of RotateDesc[0]:
        steps.addLast Step.init(cross = false)
        index += 1
      of CrossRotateDesc[0]:
        steps.addLast Step.init(cross = true)
        index += 1
      of HardWrapUri, GarbageWrapUri:
        let lastIndex = query.find(query[index], start = index + 1)
        if lastIndex == -1:
          return err errorMsg

        steps.addLast ?query[index .. lastIndex].parseStep(fqdn).context errorMsg
        index.assign lastIndex + 1
      else:
        let stepResult = query.substr(index, index + 3).parseStep fqdn
        if stepResult.isOk:
          steps.addLast stepResult.unsafeValue
          index += 4
          continue

        let stepResult2 = query.substr(index, index + 1).parseStep fqdn
        if stepResult2.isOk:
          steps.addLast stepResult2.unsafeValue
          index += 2
          continue

        return err errorMsg

    ok steps
  of IshikawaPuyo, Ips:
    if query.len mod 2 != 0:
      return err errorMsg

    var steps = Steps.init query.len div 2
    for index in countup(0, query.len - 1, 2):
      steps.addLast ?query[index .. index + 1].parseStep(fqdn).context errorMsg

    ok steps
