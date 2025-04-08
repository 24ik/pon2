## This module implements steps.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, math, sequtils, strformat, strutils, sugar, tables]
import ./[cell, common, fqdn, pair, placement]
import ../private/[arrayops2, assign3, results2, utils]

type
  StepKind* {.pure.} = enum
    ## Discriminator for `Step`.
    PutPair
    GarbageDrop

  Step* = object ## Game step.
    case kind*: StepKind
    of PutPair:
      pair*: Pair
      optPlacement*: Opt[Placement]
    of GarbageDrop:
      garbageCnts*: array[Col, int]

  Steps* = seq[Step] ## Sequence of steps.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Step, pair: Pair, optPlcmt: OptPlacement): T {.inline.} =
  T(kind: PutPair, pair: pair, optPlacement: optPlcmt)

func init*(T: type Step, pair: Pair): T {.inline.} =
  T.init(pair, NonePlacement)

func init*(T: type Step, pair: Pair, plcmt: Placement): T {.inline.} =
  T.init(pair, Opt[Placement].ok plcmt)

func init*(T: type Step, garbageCnts: array[Col, int]): T {.inline.} =
  T(kind: GarbageDrop, garbageCnts: garbageCnts)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(step1, step2: Step): bool {.inline.} =
  case step1.kind
  of PutPair:
    step2.kind == PutPair and step1.pair == step2.pair and
      step1.optPlacement == step2.optPlacement
  of GarbageDrop:
    step2.kind == GarbageDrop and step1.garbageCnts == step2.garbageCnts

# ------------------------------------------------
# Property
# ------------------------------------------------

func isValid*(self: Step, originalCompatible = false): bool {.inline.} =
  ## Returns `true` if the step is valid.
  case self.kind
  of PutPair:
    true
  of GarbageDrop:
    if originalCompatible:
      let
        maxCnt = self.garbageCnts.max
        minCnt = self.garbageCnts.min

      0 <= minCnt and maxCnt <= 5 and maxCnt - minCnt <= 1
    else:
      self.garbageCnts.min >= 0

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*(self: Step, cell: Cell): int {.inline.} =
  ## Returns the number of `cell` in the step.
  case self.kind
  of PutPair:
    self.pair.cellCnt cell
  of GarbageDrop:
    if cell == Garbage: self.garbageCnts.sum2 else: 0

func cellCnt*(self: Step): int {.inline.} =
  ## Returns the number of `cell` in the step.
  case self.kind
  of PutPair: 2
  of GarbageDrop: self.garbageCnts.sum2

func colorCnt*(self: Step): int {.inline.} =
  ## Returns the number of color puyos in the step.
  case self.kind
  of PutPair: 2
  of GarbageDrop: 0

func garbageCnt*(self: Step): int {.inline.} =
  ## Returns the number of garbage puyos in the step.
  case self.kind
  of PutPair: 0
  of GarbageDrop: self.garbageCnts.sum2

func cellCnt*(steps: Steps, cell: Cell): int {.inline.} =
  ## Returns the number of `cell` in the steps.
  sum2 steps.mapIt it.cellCnt cell

func cellCnt*(steps: Steps): int {.inline.} =
  ## Returns the number of cells in the steps.
  sum2 steps.mapIt it.cellCnt

func colorCnt*(steps: Steps): int {.inline.} =
  ## Returns the number of color puyos in the steps.
  sum2 steps.mapIt it.colorCnt

func garbageCnt*(steps: Steps): int {.inline.} =
  ## Returns the number of garbage puyos in the steps.
  sum2 steps.mapIt it.garbageCnt

# ------------------------------------------------
# Step <-> string
# ------------------------------------------------

const
  PairPlcmtSep = '|'
  GarbagePrefix = '('
  GarbageSuffix = ')'
  GarbageSep = ","

func `$`*(self: Step): string {.inline.} =
  case self.kind
  of PutPair:
    "{self.pair}{PairPlcmtSep}{self.optPlacement}".fmt
  of GarbageDrop:
    let joined = self.garbageCnts.mapIt($it).join GarbageSep
    "{GarbagePrefix}{joined}{GarbageSuffix}".fmt

func parseStep*(str: string): Res[Step] {.inline.} =
  ## Returns the step converted from the string representation.
  if str.startsWith(GarbagePrefix) and str.endsWith(GarbageSuffix):
    let strs = str[1 ..^ 2].split GarbageSep
    if strs.len != Width:
      return err "Invalid step (garbage): {str}".fmt

    let cnts = collect:
      for s in strs:
        ?s.parseIntRes.context "Invalid step (garbage): {str}".fmt
    return ok Step.init([Col0: cnts[0], cnts[1], cnts[2], cnts[3], cnts[4], cnts[5]])

  let strs = str.split PairPlcmtSep
  if strs.len != 2:
    return err "Invalid step: {str}".fmt

  let
    pair = ?strs[0].parsePair.context "Invalid step: {str}".fmt
    optPlcmt = ?strs[1].parseOptPlacement.context "Invalid step: {str}".fmt

  ok Step.init(pair, optPlcmt)

# ------------------------------------------------
# Step <-> URI
# ------------------------------------------------

const
  GarbageWrapUri = ($Garbage)[0]
  GarbageSepUri = "_"
  MaxGarbageToIshikawaUri = "aamyKW"
  IshikawaUriNumbers =
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"

  IshikawaUriToMaxGarbage = collect:
    for i, uri in MaxGarbageToIshikawaUri:
      {uri: i}
  IshikawaUriToNum = collect:
    for i, uri in IshikawaUriNumbers:
      {uri: i}

func toUriQuery*(self: Step, fqdn = Pon2): Res[string] {.inline.} =
  ## Returns the URI query converted from the step.
  case self.kind
  of PutPair:
    ok "{self.pair.toUriQuery fqdn}{self.optPlacement.toUriQuery fqdn}".fmt
  of GarbageDrop:
    case fqdn
    of Pon2:
      let joined = self.garbageCnts.mapIt($it).join GarbageSepUri
      ok "{GarbageWrapUri}{joined}{GarbageWrapUri}".fmt
    of Ishikawa, Ips:
      if not self.isValid(originalCompatible = true):
        return err "Not supported step with Ishikawa/Ips format: {self}".fmt

      let maxGarbageCnt = self.garbageCnts.max
      if maxGarbageCnt == 0:
        return ok "a0"

      let
        diffs = self.garbageCnts.mapIt it - maxGarbageCnt + 1
        diffVal =
          sum2 (0 ..< Width).toSeq.mapIt diffs[it] * 2 ^ (Width - it - 1).Natural

      ok MaxGarbageToIshikawaUri[maxGarbageCnt] & IshikawaUriNumbers[diffVal]

func parseStep*(query: string, fqdn: IdeFqdn): Res[Step] {.inline.} =
  ## Returns the step converted from the URI query.
  case fqdn
  of Pon2:
    if query.len <= 1:
      return err "Invalid step: {query}".fmt

    if query.startsWith(GarbageWrapUri) and query.endsWith(GarbageWrapUri):
      let strs = query[1 ..^ 2].split GarbageSepUri
      if strs.len != Width:
        return err "Invalid step (garbage): {query}".fmt

      let cnts = collect:
        for s in strs:
          ?s.parseIntRes.context "Invalid step (garbage): {query}".fmt
      ok Step.init([Col0: cnts[0], cnts[1], cnts[2], cnts[3], cnts[4], cnts[5]])
    elif query.len == 2:
      ok Step.init ?query.parsePair(fqdn).context "Invalid step (pair): {query}".fmt
    elif query.len == 4:
      ok Step.init(
        ?query[0 ..< 2].parsePair(fqdn).context "Invalid step (pair): {query}".fmt,
        ?query[2 ..< 4].parseOptPlacement(fqdn).context(
          "Invalid step (placement): {query}".fmt
        ),
      )
    else:
      err "Invalid step: {query}".fmt
  of Ishikawa, Ips:
    if query.len != 2:
      return err "Invalid step: {query}".fmt

    let maxGarbageCntRes = IshikawaUriToMaxGarbage.getRes query[0]
    if maxGarbageCntRes.isOk:
      let num =
        ?IshikawaUriToNum.getRes(query[1]).context(
          "Invalid step (garbage count): {query}".fmt
        )

      var garbageCnts = initArrWith[Col, int](maxGarbageCntRes.value.pred)
      for col in Col:
        garbageCnts[col].inc num.testBit(Width.pred - col.ord).int

      return ok Step.init garbageCnts

    let
      pair = ?query[0 .. 0].parsePair(fqdn).context "Invalid step (pair): {query}".fmt
      optPlcmt =
        ?query[1 .. 1].parseOptPlacement(fqdn).context(
          "Invalid step (placement): {query}".fmt
        )

    ok Step.init(pair, optPlcmt)

# ------------------------------------------------
# Steps <-> string
# ------------------------------------------------

const StepsSep = "\n"

func `$`*(self: Steps): string {.inline.} =
  let strs = collect:
    for step in self:
      $step

  strs.join StepsSep

func parseSteps*(str: string): Res[Steps] {.inline.} =
  ## Returns the steps converted from the string representation.
  let steps = collect:
    for s in str.split StepsSep:
      ?s.parseStep.context "Invalid steps: {str}".fmt

  ok steps

# ------------------------------------------------
# Steps <-> URI
# ------------------------------------------------

func toUriQuery*(self: Steps, fqdn = Pon2): Res[string] {.inline.} =
  ## Returns the URI query converted from the steps.
  let strs = collect:
    for step in self:
      ?step.toUriQuery(fqdn).context "Invalid steps: {self}".fmt

  ok strs.join

func parseSteps*(query: string, fqdn: IdeFqdn): Res[Steps] {.inline.} =
  ## Returns the steps converted from the URI query.
  case fqdn
  of Pon2:
    var
      idx = 0
      steps = newSeq[Step]()
    while idx < query.len:
      if query[idx] == GarbageWrapUri:
        let garbageLastIdx = query.find(GarbageWrapUri, start = idx.succ)
        if garbageLastIdx == -1:
          return err "Invalid steps (gabrage area does not close): {query}".fmt

        steps.add ?query[idx .. garbageLastIdx].parseStep(fqdn).context(
          "Invalid steps: {query}".fmt
        )
        idx.assign garbageLastIdx.succ
      else:
        if idx.succ(4) <= query.len:
          let stepRes = query[idx ..< idx.succ 4].parseStep fqdn
          if stepRes.isOk:
            steps.add stepRes.expect
            idx.inc 4
            continue

        if idx.succ(2) > query.len:
          return err "Invalid steps: {query}".fmt

        steps.add ?query[idx ..< idx.succ 2].parseStep(fqdn).context(
          "Invalid steps: {query}".fmt
        )
        idx.inc 2

    ok steps
  of Ishikawa, Ips:
    if query.len mod 2 != 0:
      return err "Invalid steps: {query}".fmt

    let steps = collect:
      for i in countup(0, query.len.pred, 2):
        ?query[i .. i.succ].parseStep(fqdn).context "Invalid steps: {query}".fmt

    ok steps
