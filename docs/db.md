# データベース

なぞぷよの管理を行うことができる．
なぞぷよの登録・削除・検索に対応している．

## 使い方

### 登録

以下のいずれかを実行する：

```shell
pon2 database add <question> [<answers>...] [options]
pon2 database a <question> [<answers>...] [options]
pon2 d add <question> [<answers>...] [options]
pon2 d a <question> [<answers>...] [options]
```

例：

```shell
pon2 d a https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03
```

### 削除

以下のいずれかを実行する：

```shell
pon2 database remove <questions>... [options]
pon2 database r <questions>... [options]
pon2 d remove <questions>... [options]
pon2 d r <questions>... [options]
```

例：

```shell
pon2 d r https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03
```

### 検索

以下のいずれかを実行する：

```shell
pon2 database find [options]
pon2 database f [options]
pon2 d find [options]
pon2 d f [options]
```

例：

```shell
pon2 d f --fr 0 --fm 2 --fm 3
```

## オプション（共通）

| オプション | 説明                   | デフォルト値 |
| ---------- | ---------------------- | ------------ |
| -h         | ヘルプ画面を表示する． | しない       |

## オプション（検索）

全てのオプションは，指定しない場合には無視される（すなわち，全てのなぞぷよに検索がヒットする）．

| オプション | 説明                   |
| ---------- | ---------------------- |
| --fr       | 検索したいルール．     |
| --fk       | 検索したいクリア条件． |
| --fm       | 検索したい手数．       |

なお，ルール `--fr` は以下の表を参照して数値で指定する．

| 指定する数字 | ルール     |
| ------------ | ---------- |
| 0            | 通         |
| 1            | すいちゅう |

また，クリア条件 `--fk` は以下の表を参照して数値で指定する．

| 指定する数字 | クリア条件の種類             |
| ------------ | ---------------------------- |
| 0            | cぷよ全て消すべし            |
| 1            | n色消すべし                  |
| 2            | n色以上消すべし              |
| 3            | cぷよn個消すべし             |
| 4            | cぷよn個以上消すべし         |
| 5            | n連鎖するべし                |
| 6            | n連鎖以上するべし            |
| 7            | n連鎖&cぷよ全て消すべし      |
| 8            | n連鎖以上&cぷよ全て消すべし  |
| 9            | n色同時に消すべし            |
| 10           | n色以上同時に消すべし        |
| 11           | cぷよn個同時に消すべし       |
| 12           | cぷよn個以上同時に消すべし   |
| 13           | cぷよn箇所同時に消すべし     |
| 14           | cぷよn箇所以上同時に消すべし |
| 15           | cぷよn連結で消すべし         |
| 16           | cぷよn連結以上で消すべし     |