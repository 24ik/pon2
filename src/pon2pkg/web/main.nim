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
            text "このツールは開発途中です．以下の点に注意してください．"
            ul:
              li:
                text "バグ（探索結果の間違い等）がある可能性があります．見つけたら"
                a(href = "https://twitter.com/PP_Orange_PP"): text "作者"
                text "までご連絡ください．"
              li: text "固ぷよ・鉄ぷよ・壁や，フィーバーモード，途中でお邪魔が降る問題には対応していません．"
              li: text "探索が遅いです．4手問題まで，多くても5手問題までの利用を推奨します．"
              li:
                text "以下の種類のなぞぷよは探索が"
                strong: text "非常に"
                text "遅いです．"
              ul:
                li: text "cぷよn箇所[以上]同時に消すべし"
                li: text "cぷよn連結[以上]で消すべし"
              li: text "探索中にこのWebページの動作が固まります．仕様です．"
              li: text "探索を中断したい場合，このページを再読込してください．"

          solverField()
        section(class = "section"):
          messageTable()
      tdiv(class = "column"):
        section(class = "section"):
          simulatorFrame()

proc makeWebPage* =
  ## Makes the full web page.
  makeWebPageCore.setRenderer
