## The `pon2` module provides applications and APIs for
## [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## To access APIs, import the following submodules:
## - [pon2/core](./pon2/core.html)
## - [pon2/app](./pon2/app.html)
##
## Compile Options:
## | Option                            | Description                      | Default             |
## | --------------------------------- | -------------------------------- | ------------------- |
## | `-d:pon2.waterheight=<int>`       | Height of the water.             | `8`                 |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.        | `70`                |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule.      | `90`                |
## | `-d:pon2.avx2=<bool>`             | Use AVX2 instructions.           | `true`              |
## | `-d:pon2.bmi2=<bool>`             | Use BMI2 instructions.           | `true`              |
## | `-d:pon2.fqdn=<str>`              | FQDN of the web IDE.             | `24ik.github.io`    |
## | `-d:pon2.path=<str>`              | URI path of the web simulator.   | `/pon2/`            |
## | `-d:pon2.workerfilename=<str>`    | File name of the web worker.     | `worker.min.js`     |
## | `-d:pon2.assets.native=<str>`     | Assets directory for native app. | `<Pon2Root>/assets` |
## | `-d:pon2.assets.web=<str>`        | Assets directory for web app.    | `./assets`          |
## | `-d:pon2.worker`                  | Generates web worker file.       | `<undefined>`       |
## | `-d:pon2.marathon`                | Generates marathon JS file.      | `<undefined>`       |
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when isMainModule:
  when defined(js):
    import ./pon2/private/main/[web]

    when defined(pon2.worker):
      import ./pon2/private/[webworker]
      assignToWorker workerTask
    elif defined(pon2.marathon):
      import karax/[karax]
      setRenderer marathonRenderer
    else:
      import karax/[karax]
      setRenderer ideRenderer
  else:
    import std/[strformat, tables]
    import ./pon2/private/[misc]
    import ./pon2/private/main/[native]

    let args = getCommandLineArguments()
    if args["--version"]:
      echo &"Pon! Tsu Version {Pon2Version}"
    elif args["solve"] or args["s"]:
      args.runSolver
    elif args["generate"] or args["g"]:
      args.runGenerator
    elif args["permute"] or args["p"]:
      args.runPermuter
    else:
      args.runIde

when defined(nimdoc):
  import ./pon2/app
  import ./pon2/core

  # HACK: dummy to suppress warning
  discard SelectColor
  discard Cell.None
