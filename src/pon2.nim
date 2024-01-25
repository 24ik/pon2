## The `pon2` module provides applications and APIs for
## [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## API Documentations:
## - [Puyo Puyo](./pon2pkg/core.html)
## - [Nazo Puyo](./pon2pkg/nazopuyo.html)
## - [GUI Application](./pon2pkg/app.html)
##
## Generate Static Web Pages on JS Backend:
## | Compile Option    | Generated File                  |
## | ----------------- | ------------------------------- |
## | No Option         | Main file.                      |
## | `-d:Pon2Worker`   | Web worker file.                |
## | `-d:Pon2Marathon` | Main file for marathon manager. |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when isMainModule:
  when defined(js):
    when defined(Pon2Worker):
      import ./pon2pkg/private/[webworker]
      import ./pon2pkg/private/main/[web]

      assignToWorker workerTask
    elif defined(Pon2Marathon):
      import std/[sugar]
      import karax/[karax]
      import ./pon2pkg/apppkg/[marathon as marathonModule]

      var marathon = initMarathon()
      setRenderer () => marathon.initMarathonNode
    else:
      import std/[sugar]
      import ./pon2pkg/apppkg/[editorpermuter]
      import ./pon2pkg/private/main/[web]
      import karax/[karax]

      var
        pageInitialized = false
        globalEditorPermuter: EditorPermuter

      setRenderer (routerData: RouterData) => routerData.initEditorPermuterNode(
        pageInitialized, globalEditorPermuter)
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
  # HACK: need to access something to generate documentation
  import ./pon2pkg/app as appDoc
  import ./pon2pkg/core as coreDoc
  import ./pon2pkg/nazopuyo as nazoDoc
  discard coreDoc.Cell.None
  discard nazoDoc.MarkResult.Accept
  discard appDoc.SimulatorState.Stable
