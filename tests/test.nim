{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[appdirs, dirs, os, osproc, paths, sequtils, strformat]
import unittest2

const
  SimdLvl {.define: "pon2.testsimd".} = 2
  BmiLvl {.define: "pon2.testbmi".} = 2
  TestUnder {.define: "pon2.testunder".} = true

static:
  doAssert SimdLvl in 0 .. 2
  doAssert BmiLvl in 0 .. 2

type Backend {.pure.} = enum
  C = "c"
  Cpp = "cpp"
  Js = "js"

proc testDirs(): seq[Path] =
  currentSourcePath().Path.parentDir.walkDir.toSeq
  .filterIt(it.kind in {pcDir, pcLinkToDir}).mapIt it.path

proc outDir(file: Path, backend: Backend, simdLvl, bmiLvl: int): Path =
  appdirs.getTempDir() / "pon2".Path / "test".Path / ($backend).Path /
    file.parentDir.splitFile.name / "simd{simdLvl}bmi{bmiLvl}".fmt.Path

const TestDirs = testDirs()

func filePath(testDir: Path): Path =
  testDir / "test.nim".Path

proc run(file: Path, backend: Backend, simdLvl, bmiLvl: int): string =
  "nim {backend} -w:off --hints:off -d:pon2.simd={simdLvl} -d:pon2.bmi={bmiLvl} -r --outdir:{outDir(file, backend, simdLvl, bmiLvl)} {file}".fmt.execCmdEx.output

template tests(backend: Backend, simdLvl, bmiLvl: int): untyped =
  for testDir in TestDirs:
    test $testDir.splitFile.name:
      check:
        testDir.filePath.run(backend, simdLvl, bmiLvl) == ""

func suiteName(backend: Backend, simdLvl, bmiLvl: int): string =
  "{backend} simd={simdLvl} bmi={bmiLvl}".fmt

template suites(backend: Backend): untyped =
  let
    simdLvlMax = if backend == Js: 0 else: SimdLvl
    bmiLvlMax = if backend == Js: 0 else: BmiLvl

    simdLvls = (if TestUnder: 0 else: simdLvlMax) .. simdLvlMax
    bmiLvls = (if TestUnder: 0 else: bmiLvlMax) .. bmiLvlMax

  for simdLvl in simdLvls:
    for bmiLvl in bmiLvls:
      suite suiteName(backend, simdLvl, bmiLvl):
        tests backend, simdLvl, bmiLvl

suites C
suites Cpp
suites Js
