rv2sa
=====
an application and a ruby script which compose and decompose Scripts.rvdata2 of rpgvxace.
rv2sa: rpgvxaceのGame.exeが読み込むScripts.rvdata2を分解したり生成したりするツールです。

## 使い方
コマンドラインから実行します。

### 分解
(Scripts.rvdata2を分解してscriptフォルダに入れる)

`rv2sa -d Scripts.rvdata2 -o script`

Scripts.rvdata2に含まれるフィルと、Scripts.conf.rbが自動的に生成されます。


### 生成
(scriptフォルダに分解した内容をScripts.rvdata2にまとめる)

`rv2sa -c script/Scripts.conf.rb -o Scripts.rvdata2`

#### フラグ

* -f オプションでフラグを指定できます。このフラグはScripts.conf.rbで追加するファイルを制御するために使用できます。
* `rv2sa -f "debug,test"` とすると Scripts.conf.rb でファイルを追加する際に :debug :test の二つを有効だとして扱います。詳細は**Scripts.conf.rbの表記方法**を参照してください。


## Scripts.conf.rbの表記方法

Rubyスクリプトとして可能な表記はすべて使用できます。

### ファイルの追加

* `add "ファイル名"` と記載することで、Scripts.rvdata2に含めるファイルを追加できます。
* `"ファイル名"` の部分には、Scripts.conf.rbからの**相対パス**で**拡張子抜き**のファイルパスを記載します。
* %Q()の記法やヒアドキュメントを使用することができます。ヒアドキュメントを使用する場合は String.unindent を使用することで、行頭のインデントを除外できます（一番浅い行のインデントが0になるように除外します）。

### フラグ

* `add "ファイル名", :symbol` とすることで、rv2sa実行時のflagとしてsymbolが指定された場合のみにファイルが追加されるようになります。
* デバッグ用のファイルを `add "file_for_debug", :debug` という風に指定すると、rv2sa実行時に`-f debug`を指定した場合は追加され、それ以外では追加されないようになります。
* add時のフラグは`add "file", [:debug, :test]` のように配列で渡すことで複数設定できます。この場合、いずれかのフラグが有効であればファイルは追加されます。

### 別ファイルのインポート

* `import "ファイル名"` と記載すると、別のファイルをインポートできます。
* import先、import元にかかわらず、ファイルの中身は、そのファイルからの相対パスで記載してください。

## プリプロセス

rv2saを通してScripts.rvdata2を生成する際、特定の記法に基づいて、Scripts.conf.rbに記載された各ファイルの中身を書き換える処理を行います。
ユーザー環境では使用しないコードを事前に除去するなどの用途に使用できます。

### 記法

C/C++のプリプロセッサに似た書式で記述します。

以下の書式で記載されたものは、全て、プリプロセッサに対する指示（ディレクティブ）と見なされます。

`#identifier arguments`

* `#` と `identifier` は連続しなければなりません。
* `identifier` と `arguments` の間には一つ以上の空白が必要です。
* `#` の前には、空白があっても構いません。ただし、`#`の前に空白以外の文字があると、ディレクティブとは見なされません。

#### ディレクティブの種類

##### #define

* `#define :name`
* `#define :name, value`

定数を定義します。value を省略した場合は nil を値として設定します。

後述する、分岐用のディレクティブや文字列置換に使用できます。

##### #undef

* #define で定義された定数を未定義状態にします。


##### #if-#else-#endif

* `#if`-`#else`-`#end` でくくられた範囲は、条件を満たさなければ、コードから除外されます。
* 入れ子にすることが可能です。
* `#ifdef :name` - `#if defined(:name)`の簡易表現です。
* `#ifndef :name` - `#ifdef :name`が偽のときに真になります。
* `#elif` - Rubyでいう elsif を意味します。
* `#else_ifdef :name` - Ruby風に書くと elsif defined :name と同様です
* `#else ifndef :name` - Ruby風に書くと elsif (! defined :name) と同様です。

##### #warning

* `#warning message`

rv2sa を実行する際に、標準エラーに message を表示します。

##### #error

* `#error message`

rv2sa を失敗させ、標準エラーに message を表示します。

##### #include

* `#include filename`

この行を filename の中身に置き換えます。

##### その他

ディレクティブのargumentsとして指定可能な表記を示します。

* `defined(:name)` :name が #defined されていれば true そうでなければ false になります。
* `defined(:name, value)` name が #defined されていれば、その値を value === で比較した結果を返します。
* `defined_value(:name)` #defined された値を返します。未定義の場合は nil を返します。
    * `#if defined_value(:version) < 20` などのように演算子とともに使用することも可能です。

#### フラグ

rv2sa を実行する際に指定したフラグは、自動的に `#define` され、値は true に設定されます。

#### 文字列置換

プリプロセスを行う際に、ソースコード上に_[A-Z]_ではじまり、_[A-Z0-9__]_だけで構成される文字列があり、それが `#define` で定義されていれば、その値に置換します。

* `#define :VERSION, 10` としておくと、ソースコード上の `VERSION` は `10` に置換されます。
* ソースコード上の式、コメント、文字列 などを問わず、すべてを機械的に置換します。
* C/C++の `#define JOIN(a, b) a##b` のような引数を必要とする置換は行えません。

## rv2saの想定する運用方法

### 初回
* デフォルトで生成されるScripts.rvdata2を分解し、好きなフォルダに展開しておく。

### 更新時
* ファイラー上でソースコードを追加/編集する。
* Scripts.rvdata2 を生成してからゲームを起動する。


# 参考情報

# 注意点
* ファイルの中身はUTF-8で記述してください。
* Game.exeの起動時にScripts.rvdata2が読み込まれます。エディター起動後にScripts.rvdata2を生成しても問題ありません。(rpgvxace1.02a時点)
* エディタは起動時にScripts.rvdata2を読み込むと、それ以降はScripts.rvdata2を読み直しません。エディタのスクリプトエディタでスクリプトを編集したい場合は、エディタを起動しなおしてください。(rpgvxace1.02a時点)
* エディタ上でスクリプトエディタやデータベースなどを開くと、Scripts.rvdata2が再生成されます。このとき生成されるScripts.rvdata2の中身は、エディタが起動時にロードした中身になります。エディタ起動後に外部からScripts.rvdata2を生成し、その後エディタ上でスクリプトエディタを開いた場合、外部から生成したScripts.rvdata2は破棄され、エディタを起動した時点の中身に戻ってしまいます。(rpgvxace1.02a時点)  
※この問題を回避するには、rvhookを使いGame.exeを起動するたびにrv2saを呼び出すという方法があります。

# 更新履歴
* 2.2.0 プリプロセッサを追加。
* 2.1.0 `import`を追加。
* 2.0.0 定義ファイルをScripts.conf.rbに変更すると共にスクリプトの内容を刷新。
* 1.3.0 -l オプションを設けた。
* 1.2.0	ファイル名を　ファイル名_index_id.rb　に変更した。
* 1.1.0	生成時のスクリプトごとのIDを通し番号に変更した。
* 1.0.0	最初のバージョン

