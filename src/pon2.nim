## The `pon2` module provides applications and APIs for
## [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## To access APIs, import the following submodules:
## - [pon2pkg/core](./pon2pkg/core.html)
## - [pon2pkg/app](./pon2pkg/app.html)
##
## Compile Options:
## | Option                            | Description                 | Default |
## | --------------------------------- | --------------------------- | ------- |
## | `-d:pon2.waterheight=<int>`       | Height of the water.        | `8`     |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.   | `70`    |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule. | `90`    |
## | `-d:pon2.avx2=<bool>`             | Use AVX2 instructions.      | `true`  |
## | `-d:pon2.bmi2=<bool>`             | Use BMI2 instructions.      | `true`  |
## | `-d:pon2.worker`                  | Generate web worker file.   |         |
## | `-d:pon2.marathon`                | Generate marathon JS file.  |         |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when isMainModule:
  when defined(js):
    when defined(pon2.worker):
      import ./pon2pkg/private/[webworker]
      import ./pon2pkg/private/main/[web]

      assignToWorker workerTask
    elif defined(pon2.marathon):
      import std/[sugar]
      import karax/[karax]
      import ./pon2pkg/app/[marathon as marathonModule]
      import ./pon2pkg/private/main/[web]

      var marathon = initMarathon()

      setRenderer () => marathon.initMainMarathonNode
    else:
      import std/[sugar]
      import ./pon2pkg/app/[gui]
      import ./pon2pkg/private/main/[web]
      import karax/[karax]

      var
        pageInitialized = false
        guiApplication: GuiApplication

      setRenderer (routerData: RouterData) =>
        routerData.initGuiApplicationNode(pageInitialized, guiApplication)
  else:
    import std/[tables]
    import ./pon2pkg/private/main/[native]

    let args = getCommandLineArguments()
    if args["solve"] or args["s"]:
      args.runSolver
    elif args["generate"] or args["g"]:
      args.runGenerator
    elif args["permute"] or args["p"]:
      args.runPermuter
    else:
      args.runGuiApplication

when defined(nimdoc):
  import ./pon2pkg/app
  import ./pon2pkg/core

  # HACK: dummy to suppress warning
  discard SelectColor
  discard Cell.None
