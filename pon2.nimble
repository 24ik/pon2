# Package

version = "0.28.3"
author = "Keisuke Izumiya"
description = "Application of Puyo Puyo and Nazo Puyo"
license = "Apache-2.0"

srcDir = "src"
installExt = @["nim"]
bin = @["pon2"]


# Dependencies

requires "nim ^= 2.2.6"

requires "chroma ^= 1.0.0"
requires "cligen ^= 1.9.5"
requires "karax ^= 1.5.0"
requires "nimsimd ^= 1.3.2"
requires "regex ^= 0.26.3"
requires "results ^= 0.5.1"
requires "stew ^= 0.4.2"
requires "unittest2 ^= 0.2.5"


# Tasks

import std/[os, sequtils, strformat, strutils]

task pages, "Generate Web Pages":
  const
    Pon2Path {.define: "pon2.path".} = ""
    danger {.booldefine.} = true
    minify {.booldefine.} = true
    verbose {.booldefine.} = false

  proc compile(src: string, dst: string, options: varargs[string]) =
    let
      (_, tail) = dst.splitPath
      rawJs = getTempDir() / "raw-{tail}".fmt

    if verbose:
      echo "[pon2] Raw JS output file: ", rawJs

    var cmds = @["nim", "js"] & options.toSeq
    if Pon2Path != "":
      cmds.add "-d:pon2.path={Pon2Path}".fmt
    if danger:
      cmds.add "-d:danger"
    cmds &= ["-o:{rawJs}".fmt, src]

    exec cmds.join " "

    if minify:
      var cmds2 = @["npx", "--yes", "google-closure-compiler"]
      if not verbose:
        cmds2 &= ["-W", "QUIET"]
      cmds2 &= ["--js", rawJs, "--js_output_file", dst]

      exec cmds2.join " "
    else:
      cpFile rawJs, dst

  # studio
  "src/pon2.nim".compile "pages/studio/index.min.js"
  "src/pon2.nim".compile "pages/studio/worker.min.js", "-d:pon2.build.worker"

  # marathon
  "src/pon2.nim".compile "pages/marathon/index.min.js", "-d:pon2.build.marathon"

  # documentation
  exec "nim doc --project --outdir:pages/docs/api/native src/pon2.nim"
  exec "nim doc --project --outdir:pages/docs/api/js --backend:js src/pon2.nim"

  # assets
  cpDir "assets", "pages/assets"
