# Package

version = "0.12.1"
author = "Keisuke Izumiya"
description = "Puyo Puyo Library"
license = "Apache-2.0"

srcDir = "src"
installExt = @["nim"]
bin = @["pon2"]

# Dependencies

requires "nim ^= 2.0.2"

requires "docopt ^= 0.7.1"
requires "karax ^= 1.3.3"
requires "nigui ^= 0.2.7"
requires "nimsimd ^= 1.2.9"
requires "suru#f6f1e607c585b2bc2f71309996643f0555ff6349"

# Tasks

import std/[os, sequtils, strformat, strutils]

task test, "Run Tests":
  const
    Avx2 {.define: "pon2.avx2".} = 2
    Bmi2 {.define: "pon2.bmi2".} = 2

  exec &"nim c -r -d:pon2.avx2={Avx2} -d:pon2.bmi2={Bmi2} " & "tests/makeTest.nim"
  exec "testament all"

task benchmark, "Benchmarking":
  const
    Avx2 {.define: "pon2.avx2".} = true
    Bmi2 {.define: "pon2.bmi2".} = true

  exec &"nim c -r -d:pon2.avx2={Avx2} -d:pon2.bmi2={Bmi2} " & "benchmark/main.nim"

task documentation, "Make Documentation":
  exec &"nim doc --project -d:pon2.avx2=true src/pon2.nim"
  mvDir "src/htmldocs", "src/htmldocs2"

  exec &"nim doc --project -d:pon2.avx2=false src/pon2.nim"
  cpDir "src/htmldocs2", "src/htmldocs"
  rmDir "src/htmldocs2"

task web, "Make Web Pages":
  const
    danger {.booldefine.} = true
    minify {.booldefine.} = true
    verbose {.booldefine.} = false

  proc compile(src: string, dst: string, options: varargs[string]) =
    let
      (_, tail) = dst.splitPath
      rawJs = getTempDir() / &"raw-{tail}"

    if verbose:
      echo "[pon2] Raw JS output file: ", rawJs

    var cmds = @["nim", "js"] & options.toSeq
    if danger:
      cmds.add "-d:danger"
    cmds &= [&"-o:{rawJs}", &"{src}"]

    exec cmds.join " "

    if minify:
      var cmds2 = @["npx", "--yes", "google-closure-compiler"]
      if not verbose:
        cmds2 &= ["-W", "QUIET"]
      cmds2 &= ["--js", &"{rawJs}", "--js_output_file", &"{dst}"]

      exec cmds2.join " "
    else:
      cpFile rawJs, dst

  # GUI application
  "src/pon2.nim".compile "www/gui/index.min.js"
  "src/pon2.nim".compile "www/gui/worker.min.js", "-d:pon2.worker"

  # marathon
  "src/pon2.nim".compile "www/marathon/index.min.js", "-d:pon2.marathon"

  # documentation
  exec "nimble -y documentation"
  cpDir "src/htmldocs", "www/docs"
  rmDir "src/htmldocs"

  # assets
  exec "nim c -r assets/pairs/generate.nim"
  cpDir "assets", "www/assets"
