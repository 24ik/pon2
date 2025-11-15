## This module implements steps.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sequtils, strformat, sugar]
import ./[cell, common, fqdn, pair, placement]
import ../private/[arrayutils, assign, deques, math, results2, strutils, tables]

export deques, pair, placement, results2

type
  StepKind* {.pure.} = enum
    ## Discriminator for `Step`.
    PairPlacement
    Garbages
    Rotate

  Step* = object ## Game step.
    case kind*: StepKind
    of PairPlacement:
      pair*: Pair
      optPlacement*: OptPlacement
    of Garbages:
      cnts*: array[Col, int]
      dropHard*: bool
    of Rotate:
      cross*: bool

  Steps* = Deque[Step] ## Sequence of steps.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Step, pair: Pair, optPlcmt: OptPlacement): T {.inline, noinit.} =
  T(kind: PairPlacement, pair: pair, optPlacement: optPlcmt)

func init*(T: type Step, pair: Pair): T {.inline, noinit.} =
  T.init(pair, NonePlacement)

func init*(T: type Step, pair: Pair, plcmt: Placement): T {.inline, noinit.} =
  T.init(pair, OptPlacement.ok plcmt)

func init*(T: type Step, cnts: array[Col, int], dropHard: bool): T {.inline, noinit.} =
  T(kind: Garbages, cnts: cnts, dropHard: dropHard)

func init*(T: type Step, cross: bool): T {.inline, noinit.} =
  T(kind: Rotate, cross: cross)

func init*(T: type Step): T {.inline, noinit.} =
  T.init Pair.init

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(step1, step2: Step): bool {.inline, noinit.} =
  case step1.kind
  of PairPlacement:
    step2.kind == PairPlacement and step1.pair == step2.pair and
      step1.optPlacement == step2.optPlacement
  of Garbages:
    step2.kind == Garbages and step1.cnts == step2.cnts and
      step1.dropHard == step2.dropHard
  of Rotate:
    step2.kind == Rotate and step1.cross == step2.cross

# ------------------------------------------------
# Property
# ------------------------------------------------

func isValid*(self: Step, originalCompatible = false): bool {.inline, noinit.} =
  ## Returns `true` if the step is valid.
  case self.kind
  of PairPlacement:
    true
  of Garbages:
    if originalCompatible:
      let
        maxCnt = self.cnts.max
        minCnt = self.cnts.min

      0 <= minCnt and maxCnt <= 5 and maxCnt - minCnt <= 1
    else:
      self.cnts.min >= 0
  of Rotate:
    true

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*(self: Step, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the step.
  case self.kind
  of PairPlacement:
    self.pair.cellCnt cell
  of Garbages:
    if (cell == Hard and self.dropHard) or (cell == Garbage and not self.dropHard):
      self.cnts.sum
    else:
      0
  of Rotate:
    0

func puyoCnt*(self: Step): int {.inline, noinit.} =
  ## Returns the number of puyos in the step.
  case self.kind
  of PairPlacement: 2
  of Garbages: self.cnts.sum
  of Rotate: 0

func colorPuyoCnt*(self: Step): int {.inline, noinit.} =
  ## Returns the number of color puyos in the step.
  case self.kind
  of PairPlacement: 2
  of Garbages: 0
  of Rotate: 0

func garbagesCnt*(self: Step): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the step.
  case self.kind
  of PairPlacement: 0
  of Garbages: self.cnts.sum
  of Rotate: 0

func cellCnt*(steps: Steps, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the steps.
  sum steps.mapIt it.cellCnt cell

func puyoCnt*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of puyos in the steps.
  sum steps.mapIt it.puyoCnt

func colorPuyoCnt*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of color puyos in the steps.
  sum steps.mapIt it.colorPuyoCnt

func garbagesCnt*(steps: Steps): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the steps.
  sum steps.mapIt it.garbagesCnt

# ------------------------------------------------
# Step <-> string
# ------------------------------------------------

const
  PairPlcmtSep = '|'
  GarbagePrefix = '('
  GarbageSuffix = ')'
  HardPrefix = '['
  HardSuffix = ']'
  GarbagesSep = ","
  RotateDesc = "O"
  CrossRotateDesc = "X"

func `$`*(self: Step): string {.inline, noinit.} =
  case self.kind
  of PairPlacement:
    "{self.pair}{PairPlcmtSep}{self.optPlacement}".fmt
  of Garbages:
    let
      joined = self.cnts.mapIt($it).join GarbagesSep
      prefix, suffix: char
    if self.dropHard:
      prefix = HardPrefix
      suffix = HardSuffix
    else:
      prefix = GarbagePrefix
      suffix = GarbageSuffix

    "{prefix}{joined}{suffix}".fmt
  of Rotate:
    if self.cross: CrossRotateDesc else: RotateDesc

func parseStep*(str: string): StrErrorResult[Step] {.inline, noinit.} =
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

    let cnts = collect:
      for s in strs:
        ?s.parseInt.context "Invalid step (garbages): {str}".fmt
    return ok Step.init(
      [Col0: cnts[0], cnts[1], cnts[2], cnts[3], cnts[4], cnts[5]], dropHard
    )

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

func toUriQuery*(self: Step, fqdn = Pon2): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the step.
  case self.kind
  of PairPlacement:
    ok "{self.pair.toUriQuery fqdn}{self.optPlacement.toUriQuery fqdn}".fmt
  of Garbages:
    case fqdn
    of Pon2:
      let
        wrapper = if self.dropHard: HardWrapUri else: GarbageWrapUri
        joined = self.cnts.mapIt($it).join GarbagesSepUri
      ok "{wrapper}{joined}{wrapper}".fmt
    of Ishikawa, Ips:
      if not self.isValid(originalCompatible = true) or self.dropHard:
        return err "Not supported step with Ishikawa/Ips format: {self}".fmt

      let maxGarbageCnt = self.cnts.max
      if maxGarbageCnt == 0:
        return ok "a0"

      let
        diffs = self.cnts.mapIt it - maxGarbageCnt + 1
        diffVal = sum (0 ..< Width).toSeq.mapIt diffs[it] * 2 ^ (Width - it - 1).Natural

      ok MaxGarbageToIshikawaUri[maxGarbageCnt] & IshikawaUriNumbers[diffVal]
  of Rotate:
    case fqdn
    of Pon2:
      ok (if self.cross: CrossRotateDesc else: RotateDesc)
    of Ishikawa, Ips:
      err "Not supported step with Ishikawa/Ips format: {self}".fmt

func parseStep*(
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[Step] {.inline, noinit.} =
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

      let cnts = collect:
        for s in strs:
          ?s.parseInt.context "Invalid step (garbages): {query}".fmt
      ok Step.init(
        [Col0: cnts[0], cnts[1], cnts[2], cnts[3], cnts[4], cnts[5]], dropHard
      )
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

    let maxGarbageCntRes = IshikawaUriToMaxGarbage[query[0]]
    if maxGarbageCntRes.isOk:
      let num =
        ?IshikawaUriToNum[query[1]].context("Invalid step (garbage count): {query}".fmt)

      var garbageCnts = Col.initArrayWith maxGarbageCntRes.value.pred
      for col in Col:
        garbageCnts[col].inc num.testBit(Width.pred - col.ord).int

      return ok Step.init(garbageCnts, false)

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

func `$`*(self: Steps): string {.inline, noinit.} =
  let strs = collect:
    for step in self:
      $step

  strs.join StepsSep

func parseSteps*(str: string): StrErrorResult[Steps] {.inline, noinit.} =
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

func toUriQuery*(self: Steps, fqdn = Pon2): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the steps.
  let strs = collect:
    for step in self:
      ?step.toUriQuery(fqdn).context "Invalid steps: {self}".fmt

  ok strs.join

func parseSteps*(
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[Steps] {.inline, noinit.} =
  ## Returns the steps converted from the URI query.
  case fqdn
  of Pon2:
    var
      idx = 0
      steps = Steps.init
    while idx < query.len:
      if query[idx] in {RotateDesc[0], CrossRotateDesc[0]}:
        steps.addLast ?query[idx .. idx].parseStep(fqdn).context(
          "Invalid steps: {query}".fmt
        )
        idx.inc
      elif query[idx] in {HardWrapUri, GarbageWrapUri}:
        let garbageLastIdx = query.find(query[idx], start = idx.succ)
        if garbageLastIdx == -1:
          return err "Invalid steps (gabrages area does not close): {query}".fmt

        steps.addLast ?query[idx .. garbageLastIdx].parseStep(fqdn).context(
          "Invalid steps: {query}".fmt
        )
        idx.assign garbageLastIdx.succ
      else:
        if idx.succ(4) <= query.len:
          let stepRes = query[idx ..< idx.succ 4].parseStep fqdn
          if stepRes.isOk:
            steps.addLast stepRes.unsafeValue
            idx.inc 4
            continue

        if idx.succ(2) > query.len:
          return err "Invalid steps: {query}".fmt

        steps.addLast ?query[idx ..< idx.succ 2].parseStep(fqdn).context(
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

    ok steps.toDeque
