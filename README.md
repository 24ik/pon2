# Pon!通

Pon!通は，なぞぷよに関する様々な機能を提供するツールである．
以下の機能が提供されている．
- ソルバー：なぞぷよを解く．[【ブラウザで試す】](https://izumiya-keisuke.github.io/pon2/playground)
- ジェネレータ：なぞぷよを生成する．
- ツモ探索：なぞぷよのツモを入れ替えて一意解問題を生成する．
- データベース：なぞぷよを管理する．
- GUIアプリケーション：なぞぷよを編集したり自分でプレイしたりする．

現在のところ以下の機能には対応していない．
- 壁・固ぷよ・鉄ぷよ
- フィーバーモード
- 途中のお邪魔落下

## インストール

### ビルド済バイナリ

[最新リリース](https://github.com/izumiya-keisuke/pon2/releases/latest)の「Assets」から，使用するOSに応じてダウンロードできる．

#### 注意点

- Windowsでは，Microsoft Defenderのセキュリティチェックに引っかかってダウンロードに失敗する場合がある．失敗したら，[対処法の記事](https://www.gigafree.net/faq/Windows-Security-Detection/)等を参考にダウンロードを再試行することで改善すると思われる．
- 技術的な制約により，GUIアプリケーションは実行ファイルが入ったディレクトリで実行する必要がある．

### ソースからビルド

[Nimをインストール](https://nim-lang.org/install.html)した後，以下のコマンドを実行する．

```shell
nimble install https://github.com/izumiya-keisuke/pon2
```

## 使い方

各種ドキュメントは以下を参照．
- [ソルバー](/doc/solve.rst)
- [ジェネレーター](/doc/generate.rst)
- [ツモ探索](/doc/permute.rst)
- [データベース](/doc/db.rst)
- [GUIアプリケーション](/doc/gui.rst)

## 開発者向け

このモジュールは[puyo-core](https://github.com/izumiya-keisuke/puyo-core)と
[nazopuyo-core](https://github.com/izumiya-keisuke/nazopuyo-core)を利用しているので，そちらも参照のこと．

### APIの利用

`import pon2` でこのモジュールが提供する全てのAPIにアクセスできる．
詳しくは[APIドキュメント](https://izumiya-keisuke.github.io/pon2)を参照．

### テスト

```shell
nim c -r tests/makeTest.nim
nimble test
```

`tests/makeTest.nim` をコンパイルする際，`-d:bmi2=<bool>` や `-d:avx2=<bool>` を
オプションとして与えることで，使用する命令セットを指定することができる．

### ベンチマーク

```shell
nim c -r benchmark/main.nim
```

### テストの書き方

1. `tests` ディレクトリ直下に新しいディレクトリを作成する．
1. 作成したディレクトリ内に新しい `main.nim` ファイルを作成する．
1. 作成したファイル内に，テストのエントリーポイントを `main()` プロシージャとして記述する．

### 静的ウェブサイト作成

プロジェクトルートで以下を実行する：

```shell
nim js -o:www/index.js src/pon2.nim
```

その後，`www` ディレクトリ以下の全ファイルを目的のディレクトリにコピーする．

### 開発への協力

ブランチを切って作業した上で，`main` ブランチへのPRを出してください．

## ライセンス

Apache-2.0，MPL-2.0のいずれかを選択する．
詳しくは[NOTICE](/NOTICE)を参照．
