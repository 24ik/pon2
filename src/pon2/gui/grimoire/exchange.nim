## This module implements grimoire data exchange views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[asyncjs, jsconsole, strformat, sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui, strutils]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  proc runExport(helper: VNodeHelper) =
    ## Exports the local storage data.
    {.push warning[Uninit]: off.}
    discard GrimoireLocalStorage.exportedStr
      .then(
        (exportResult: Pon2Result[string]) => (
          block:
            let
              val =
                if exportResult.isOk: exportResult.unsafeValue
                else: "エラー：{exportResult.error}".fmt.replace("\n", " | ")
              exportInput = helper.grimoireOpt.unsafeValue.exportId.getVNodeById
            if not exportInput.isNil:
              exportInput.setInputText val.cstring
            safeRedraw()
        )
      )
      .catch((error: Error) => console.error error)
    {.pop.}

  proc runImport(helper: VNodeHelper) =
    ## Imports the local storage data.
    let importInput = helper.grimoireOpt.unsafeValue.importId.getVNodeById
    if importInput.isNil:
      return

    let inputTxt = ($importInput.getInputText).strip
    if inputTxt.len == 0:
      return

    {.push warning[Uninit]: off.}
    discard GrimoireLocalStorage
      .importStr(inputTxt)
      .then(
        (importResult: Pon2Result[void]) => (
          block:
            let importInput2 = helper.grimoireOpt.unsafeValue.importId.getVNodeById
            if not importInput2.isNil:
              importInput2.setInputText (
                if importResult.isOk: "完了！"
                else: "呪文が間違っています．エラー内容：{importResult.error}".fmt.replace(
                  "\n", " | "
                )
              ).cstring
              safeRedraw()
        )
      )
      .catch((error: Error) => console.error error)
    {.pop.}

  proc toGrimoireExchangeVNode*(self: ref Grimoire, helper: VNodeHelper): VNode =
    ## Returns the grimoire data exchange node.
    let
      exportInput = buildHtml input(
        id = helper.grimoireOpt.unsafeValue.exportId,
        class = "input",
        `type` = "text",
        readonly = true,
      ):
        discard
      exportCopyBtn = buildHtml button(class = "button"):
        text "コピー"
    exportCopyBtn.addCopyBtnHandler () => $exportInput.getInputText

    buildHtml tdiv:
      tdiv(class = "content"):
        h4:
          text "復活の呪文"
        p:
          text "解答済データを別マシンに移行できます．"
          text "また，データ消失を防ぐために定期的な生成・保存を推奨します．"
      tdiv(class = "field has-addons"):
        tdiv(class = "control"):
          exportInput
        tdiv(class = "control"):
          button(class = "button", onclick = () => helper.runExport):
            text "生成"
        tdiv(class = "control"):
          exportCopyBtn
      tdiv(class = "field has-addons"):
        tdiv(class = "control"):
          input(
            id = helper.grimoireOpt.unsafeValue.importId,
            class = "input",
            `type` = "text",
          )
        tdiv(class = "control"):
          button(class = "button", onclick = () => helper.runImport):
            text "読込"
