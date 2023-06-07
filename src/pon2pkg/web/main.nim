## This module implements the entry point for making a web page.
##

include karax/prelude

import ./view/message
import ./view/simulator
import ./view/solve

proc makeWebPageCore: VNode =
  ## Returns the full page.
  buildHtml(tdiv):
    tdiv(class = "columns"):
      tdiv(class = "column"):
        section(class = "section"):
          h1(class = "title"):
            text "解探索"

          tdiv(class = "content"):
            ul:
              li:
                text "バグ（探索結果の間違い等）を見つけたら"
                a(href = "https://twitter.com/PP_Orange_PP"): text "作者"
                text "までご連絡ください．"
              li: text "固ぷよ・鉄ぷよ・壁，フィーバー，お邪魔ぷよが降る問題は未対応です．"
              li: text "探索が遅いです．4手問題まで，多くても5手問題までの利用を推奨します．"
              li:
                text "以下の種類のなぞぷよは探索が"
                strong: text "非常に"
                text "遅いです．"
              ul:
                li: text "cぷよn箇所[以上]同時に消すべし"
                li: text "cぷよn連結[以上]で消すべし"
              li: text "探索中に動作が固まりますが，仕様です．探索を止める場合はページを再読込してください．"

          solverField()
        section(class = "section"):
          messageTable()
      tdiv(class = "column"):
        section(class = "section"):
          simulatorFrame()

proc makeWebPage* =
  ## Makes the full web page.
  makeWebPageCore.setRenderer
