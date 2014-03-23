rv2sa
=====
an application and a ruby script which compose and decompose Scripts.rvdata2 of rpgvxace.
rv2sa: rpgvxaceのGame.exeが読み込むScripts.rvdata2を分解したり生成したりするツールです。

## 使い方
コマンドラインから実行します。

### 分解
(Scripts.rvdata2を分解してscriptフォルダに入れる)

`rv2sa -d Scripts.rvdata2 -w script`

#### ファイルの順序をテキストファイルに出力する場合
`rv2sa -d Scripts.rvdata2 -w script -l link.txt`

### 生成
(scriptフォルダのものをまとめてScripts.rvdata2に書き込む)

`rv2sa -c Scripts.rvdata2 -w script`

#### ファイルの順序をテキストファイルで指定する場合
`rv2sa -c Scripts.rvdata2 -w script -l link.txt`


## 想定する運用方法

### 初回
* デフォルトで生成されるScripts.rvdata2を分解し、好きなフォルダに展開しておく。

### 更新時
* ファイラー上でソースコードを追加/編集する。
* Scripts.rvdata2 を生成してからゲームを起動する。

# 参考情報
## ファイルの順序
* -l オプションを使用しない場合、「生成」後のファイルの並びはindexに依存します(※ 名前_index_id.rb )。同じindexのファイルが存在する場合は Find.file の探索順序に依存します。
* -l オプションを使用する場合、ファイル中に記載された順序になります。

# 注意点
* ファイルの中身はUTF-8で記述してください。
* Game.exeは起動時にScripts.rvdata2を読み込みます。エディター起動後にScripts.rvdata2を生成しても問題ありません。(rpgvxace1.02a時点)
* エディタは起動時にScripts.rvdata2を読み込むと、それ以降はScripts.rvdata2を読み直しません。エディタのスクリプトエディタでスクリプトを編集したい場合は、エディタを起動しなおしてください。(rpgvxace1.02a時点)
* エディタ上でスクリプトエディタやデータベースなどを開くと、Scripts.rvdata2が再生成されます。このとき生成されるScripts.rvdata2の中身は、エディタが起動時にロードした中身になります。エディタ起動後に外部からScripts.rvdata2を生成し、その後エディタ上でスクリプトエディタを開いた場合、外部から生成したScripts.rvdata2は破棄され、エディタを起動した時点の中身に戻ってしまいます。(rpgvxace1.02a時点)  
※この問題を回避するには、rvhookを使いGame.exeを起動するたびにrv2saを呼び出すという方法があります。

# 更新履歴
* 1.3.0 -l オプションを設けた。
* 1.2.0	ファイル名を　ファイル名_index_id.rb　に変更した。
* 1.1.0	生成時のスクリプトごとのIDを通し番号に変更した。
* 1.0.0	最初のバージョン

