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

#### デバッグ情報

* -i オプションを指定すると、rv2saが自動的に変数の定義を行います。
    * `$rv2sa_path`: rv2saを実行した際のワークディレクトリが代入されます。
    * `$LOAD_PATH`: rv2saを実行した際の`$LOAD_PATH`が追加されます。

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

* `#define :NAME`
* `#define :NAME, value`

定数を定義します。後述する分岐用のディレクティブや、文中の文字列置換に使用できます。

value を省略した場合は nil を値として設定します。通常は、数値や文字列などのリテラルを記述することを想定しています。value に変数やメソッド名を記述した場合、rv2saの実行環境内で評価されるので注意してください。

文中の文字列を置換する際の具体的な挙動については後述します。

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

この行に filename の中身を挿入します。

##### その他

ディレクティブのargumentsとして指定可能な表記を示します。

* `defined(:name)` :name が #defined されていれば true そうでなければ false になります。
* `defined(:name, value)` name が #defined されていれば、その値を value === で比較した結果を返します。
* `defined_value(:name)` #defined された値を返します。未定義の場合は nil を返します。
    * `#if defined_value(:version) < 20` などのように演算子とともに使用することも可能です。

#### フラグ

rv2sa を実行する際に指定したフラグは、自動的に `#define` され、値は true に設定されます。

#### 文字列置換

プリプロセスを行う際に、ソースコード上に`[A-Z]`ではじまり、`[A-Z0-9_]`だけで構成される文字列があり、それが `#define` で定義されていれば、その値に置換します。

* `#define :VERSION, 10` としておくと、ソースコード上の `VERSION` は `10` に置換されます。
* メソッド名などを置き換える場合は、`#define :TEST_FUNC, "test_func"`のように、文字リテラルを与えます。`"test_func"`を`test_func`と書いてしまうと、rv2saの環境で`test_func`をcallしてしまいます。
* ソースコード上の式、コメント、文字列 などを問わず、すべてを機械的に置換します。`#define`する名称には独特のprefixをつけるなどすることをお勧めします。
* 文中の文字列置換をする際、定義された文字列に括弧`( )`が続いていると、メソッド名であると解釈されます。
    1. 凡例: `文中の表記` → `置換後` (`#define :NAME, "func"` と定義した場合)
    1. `NAME` → `func`
    1. `NAME(a,b,c)` → `(func a, b, c)`
    1. `NAME a, b, c` → `func a, b, c`
    1. `NAME(a, b, c) or something` → `(func a, b, c) or something`
	1. 3 と 5 のようなケースで、単純な文字列置換とは異なる挙動を示すので、注意してください。

また、value に次のシンボルを設定すると、特殊な挙動をします。

* `:NOP`
    * :NAME の部分を除去します。
    * `head NAME tail` → `head  tail` になります。
    * `head NAME(a,b,c) tail` → `head  tail` になります。
* `:NOP_LINE`
    * :NAME の書かれた行の、それ以降をすべて削除します。
    * `head NAME tail` → `head ` になります。
    * `head NAME(a,b,c) tail` → `head ` になります。
* `:NOP_LINES`
    * :NAME の書かれた行の、それ以降を実行されなくします。ブロックの定義が次の行にまたがる場合、それも無視されます。
    * `head NAME(a,b,c).tail { ...` → `head nil if false && dummy.tail { ...` となり、翌行以降のブロック定義も実行時に無視されるようになります。

 C/C++の `#define JOIN(a, b) a##b` のような引数を必要とする置換は行えません。

## rv2saの想定する運用方法

### 初回
* デフォルトで生成されるScripts.rvdata2を分解し、好きなフォルダに展開しておく。

### 更新時
* ファイラー上でソースコードを追加/編集する。
* Scripts.rvdata2 を生成してからゲームを起動する。

# 注意点
* ファイルの中身はUTF-8で記述してください。
* Game.exeの起動時にScripts.rvdata2が読み込まれます。エディター起動後にScripts.rvdata2を生成しても問題ありません。(rpgvxace1.02a時点)
* エディタは起動時にScripts.rvdata2を読み込むと、それ以降はScripts.rvdata2を読み直しません。エディタのスクリプトエディタでスクリプトを編集したい場合は、エディタを起動しなおしてください。(rpgvxace1.02a時点)
* エディタ上でスクリプトエディタやデータベースなどを開くと、Scripts.rvdata2が再生成されます。このとき生成されるScripts.rvdata2の中身は、エディタが起動時にロードした中身になります。エディタ起動後に外部からScripts.rvdata2を生成し、その後エディタ上でスクリプトエディタを開いた場合、外部から生成したScripts.rvdata2は破棄され、エディタを起動した時点の中身に戻ってしまいます。(rpgvxace1.02a時点)  
※この問題を回避するには、rvhookを使いGame.exeを起動するたびにrv2saを呼び出すという方法があります。

# 更新履歴
* 2.3.3 add/importする際のflagsを配列でなく引数で渡すようにした。
* 2.3.2 defineされたものを置換する際にメソッド名として解釈するようにした。
* 2.3.1 `exclude`を追加。
* 2.3.0 -i オプションでデバッグ情報を追加できるようにした。
* 2.2.0 プリプロセッサを追加。
* 2.1.0 `import`を追加。
* 2.0.0 定義ファイルをScripts.conf.rbに変更すると共にスクリプトの内容を刷新。
* 1.3.0 -l オプションを設けた。
* 1.2.0	ファイル名を　ファイル名_index_id.rb　に変更した。
* 1.1.0	生成時のスクリプトごとのIDを通し番号に変更した。
* 1.0.0	最初のバージョン


# LICENSE

## rv2sa

rv2saのrubyスクリプトは[NYSL](https://github.com/ctmk/rv2sa/blob/master/LICENSE)で公開されています。

## rv2sa.exe

rv2sa.exeはrv2saをocraでexe化したものです。
内包する全てのソフトウェアのライセンス条件に従って使用できます。

### Ruby

Ruby は Ruby'sライセンス で公開されています。

https://www.ruby-lang.org/ja/

### ocra

ocra は MIT License で公開されています。 

https://github.com/larsch/ocra

Copyright c 2009-2010 Lars Christensen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

