######
Pon!通
######

Pon!通は，なぞぷよに関する様々な機能を提供するツールである．
以下の機能が提供されている．

ソルバー
    なぞぷよを解く．
    `[ブラウザで試す] <https://izumiya-keisuke.github.io/pon2/playground>`_

ツモ探索
    なぞぷよのツモを入れ替えて一意解問題を生成する．

データベース
    なぞぷよを管理する．

現在のところ以下の機能には対応していない．

* 壁・固ぷよ・鉄ぷよ
* フィーバーモード
* 途中のお邪魔落下

************
インストール
************

`Nimをインストール <https://nim-lang.org/install.html>`_ した後，以下のコマンドを実行する．

::

    nimble install https://github.com/izumiya-keisuke/pon2

******
使い方
******

各種ドキュメントは以下を参照．

* `ソルバー <doc/solve.rst>`_
* `ツモ探索 <doc/permute.rst>`_
* `データベース <doc/db.rst>`_

**********
開発者向け
**********

このモジュールは `puyo-core <https://github.com/izumiya-keisuke/puyo-core>`_ と
`nazopuyo-core <https://github.com/izumiya-keisuke/nazopuyo-core>`_ を利用しているので，
そちらも参照のこと．

APIの利用
=========

:code:`import pon2` でこのモジュールが提供する全てのAPIにアクセスできる．
詳しくは `APIドキュメント <https://izumiya-keisuke.github.io/pon2>`_ を参照．

テスト
======

::

    nim c -r tests/makeTest.nim
    nimble test

:code:`tests/makeTest.nim` をコンパイルする際，:code:`-d:bmi2=<bool>` や :code:`-d:avx2=<bool>` を
オプションとして与えることで，使用する命令セットを指定することができる．

ベンチマーク
============

::

    nim c -r benchmark/main.nim

テストの書き方
==============

#. :code:`tests` ディレクトリ直下に新しいディレクトリを作成する．
#. 作成したディレクトリ内に新しい :code:`main.nim` ファイルを作成する．
#. 作成したファイル内に，テストのエントリーポイントを :code:`main()` プロシージャとして記述する．

静的ウェブサイト作成
====================

プロジェクトルートで以下を実行する::

    nim js -o:www/index.js src/pon2.nim

その後，:code:`www` ディレクトリ以下の全ファイルを目的のディレクトリにコピーする．

**********
ライセンス
**********

Apache-2.0，MPL-2.0のいずれかを選択する．
詳しくは `NOTICE <NOTICE>`_ を参照．