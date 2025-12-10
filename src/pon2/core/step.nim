## This module implements steps.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sequtils, strformat, sugar]
import ./[cell, common, fqdn, pair, placement]
import ../[utils]
import ../private/[arrayutils, assign, deques, math, strutils, tables]

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

func colorPuyoCount*(self: Step): int {.inline, noinit.} =
  ## Returns the number of color puyos in the step.
  case self.kind
  of PairPlace: 2
  of NuisanceDrop, FieldRotate: 0

func garbagesCount*(self: Step): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the step.
  case self.kind
  of PairPlace, FieldRotate: 0
  of NuisanceDrop: self.counts.sum

func cellCount*(steps: Steps, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the steps.
  steps.mapIt(it.cellCount cell).sum

func puyoCount*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of puyos in the steps.
  steps.mapIt(it.puyoCount).sum

func colorPuyoCount*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of color puyos in the steps.
  steps.mapIt(it.colorPuyoCount).sum

func garbagesCount*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the steps.
  steps.mapIt(it.garbagesCount).sum

# ------------------------------------------------
# Step <-> string
# ------------------------------------------------

const
  PairPlaceSep = '|'
  GarbagePrefix = '('
  GarbageSuffix = ')'
  HardPrefix = '['
  HardSuffix = ']'
  GarbagesSep = ","
  RotateDesc = "R"
  CrossRotateDesc = "C"

func `$`*(self: Step): string {.inline, noinit.} =
  case self.kind
  of PairPlace:
    "{self.pair}{PairPlaceSep}{self.placement}".fmt
  of NuisanceDrop:
    let
      joined = self.counts.mapIt($it).join GarbagesSep
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
  if str == RotateDesc:
    return ok Step.init(cross = false)
  if str == CrossRotateDesc:
    return ok Step.init(cross = true)

  let
    dropGarbage = str.startsWith(GarbagePrefix) and str.endsWith(GarbageSuffix)
    dropHard = str.startsWith(HardPrefix) and str.endsWith(HardSuffix)
  if dropGarbage or dropHard:
    let strs = str[1 ..^ 2].split GarbagesSep
    if strs.len != Width:
      return err "Invalid step (garbages): {str}".fmt

    let counts = collect:
      for s in strs:
        ?s.parseInt.context "Invalid step (garbages): {str}".fmt
    return ok Step.init(
      [Col0: counts[0], counts[1], counts[2], counts[3], counts[4], counts[5]], dropHard
    )

  let strs = str.split PairPlaceSep
  if strs.len != 2:
    return err "Invalid step: {str}".fmt

  let
    pair = ?strs[0].parsePair.context "Invalid step: {str}".fmt
    placement = ?strs[1].parsePlacement.context "Invalid step: {str}".fmt

  ok Step.init(pair, placement)

# ------------------------------------------------
# Step <-> URI
# ------------------------------------------------

const
  GarbageWrapUri = ($Garbage)[0]
  HardWrapUri = ($Hard)[0]
  GarbagesSepUri = "_"
  MaxGarbageToIshikawaUri = "aamyKW"
  IshikawaUriNumbers =
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"

  IshikawaUriToMaxGarbage = collect:
    for i, uri in MaxGarbageToIshikawaUri:
      {uri: i}
  IshikawaUriToNum = collect:
    for i, uri in IshikawaUriNumbers:
      {uri: i}

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
        joined = self.counts.mapIt($it).join GarbagesSepUri
      ok "{wrapper}{joined}{wrapper}".fmt
    of IshikawaPuyo, Ips:
      if not self.isValid(originalCompatible = true) or self.hard:
        return err "Not supported step with IshikawaPuyo/Ips format: {self}".fmt

      let maxGarbageCount = self.counts.max
      if maxGarbageCount == 0:
        return ok "a0"

      let
        diffs = self.counts.mapIt it - maxGarbageCount + 1
        diffVal = sum (0 ..< Width).toSeq.mapIt diffs[it] * 2 ^ (Width - it - 1).Natural

      ok MaxGarbageToIshikawaUri[maxGarbageCount] & IshikawaUriNumbers[diffVal]
  of FieldRotate:
    case fqdn
    of Pon2:
      ok (if self.cross: CrossRotateDesc else: RotateDesc)
    of IshikawaPuyo, Ips:
      err "Not supported step with IshikawaPuyo/Ips format: {self}".fmt

func parseStep*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[Step] {.inline, noinit.} =
  ## Returns the step converted from the URI query.
  case fqdn
  of Pon2:
    if query.len <= 1:
      return
        case query[0]
        of RotateDesc[0]:
          ok Step.init(cross = false)
        of CrossRotateDesc[0]:
          ok Step.init(cross = true)
        else:
          err "Invalid step: {query}".fmt

    let
      dropGarbage = query.startsWith(GarbageWrapUri) and query.endsWith(GarbageWrapUri)
      dropHard = query.startsWith(HardWrapUri) and query.endsWith(HardWrapUri)
    if dropGarbage or dropHard:
      let strs = query[1 ..^ 2].split GarbagesSepUri
      if strs.len != Width:
        return err "Invalid step (garbages): {query}".fmt

      let counts = collect:
        for s in strs:
          ?s.parseInt.context "Invalid step (garbages): {query}".fmt
      ok Step.init(
        [Col0: counts[0], counts[1], counts[2], counts[3], counts[4], counts[5]],
        dropHard,
      )
    elif query.len == 2:
      ok Step.init ?query.parsePair(fqdn).context "Invalid step (pair): {query}".fmt
    elif query.len == 4:
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

    let maxGarbageCountRes = IshikawaUriToMaxGarbage[query[0]]
    if maxGarbageCountRes.isOk:
      let num =
        ?IshikawaUriToNum[query[1]].context("Invalid step (garbage count): {query}".fmt)

      var garbageCounts = Col.initArrayWith maxGarbageCountRes.value.pred
      for col in Col:
        garbageCounts[col].inc num.testBit(Width.pred - col.ord).int

      return ok Step.init(garbageCounts, false)

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

  let steps = collect:
    for s in str.split StepsSep:
      ?s.parseStep.context "Invalid steps: {str}".fmt

  return ok steps.toDeque

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
  case fqdn
  of Pon2:
    var
      index = 0
      steps = Steps.init
    while index < query.len:
      if query[index] in {RotateDesc[0], CrossRotateDesc[0]}:
        steps.addLast ?query[index .. index].parseStep(fqdn).context(
          "Invalid steps: {query}".fmt
        )
        index.inc
      elif query[index] in {HardWrapUri, GarbageWrapUri}:
        let garbageLastIndex = query.find(query[index], start = index.succ)
        if garbageLastIndex == -1:
          return err "Invalid steps (gabrages area does not close): {query}".fmt

        steps.addLast ?query[index .. garbageLastIndex].parseStep(fqdn).context(
          "Invalid steps: {query}".fmt
        )
        index.assign garbageLastIndex.succ
      else:
        if index.succ(4) <= query.len:
          let stepRes = query[index ..< index.succ 4].parseStep fqdn
          if stepRes.isOk:
            steps.addLast stepRes.unsafeValue
            index.inc 4
            continue

        if index.succ(2) > query.len:
          return err "Invalid steps: {query}".fmt

        steps.addLast ?query[index ..< index.succ 2].parseStep(fqdn).context(
          "Invalid steps: {query}".fmt
        )
        index.inc 2

    ok steps
  of IshikawaPuyo, Ips:
    if query.len mod 2 != 0:
      return err "Invalid steps: {query}".fmt

    let steps = collect:
      for i in countup(0, query.len.pred, 2):
        ?query[i .. i.succ].parseStep(fqdn).context "Invalid steps: {query}".fmt

    ok steps.toDeque
