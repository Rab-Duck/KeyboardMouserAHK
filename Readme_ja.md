# Keyboard Mouser AHK

このソフトウェア(AHK Script)で、次の操作をキーボードから行うことができます

- 再帰的に画面を分割していくマップ的なマウスカーソル移動
- ４方向のマウスカーソル移動
- クリック動作

キー設定等はカスタマイズ可能

![MainDisplay](https://raw.githubusercontent.com/Rab-Duck/KeyboardMouserAHK/master/image/MainDisplay.PNG)
![SettingDialog](https://raw.githubusercontent.com/Rab-Duck/KeyboardMouserAHK/master/image/SettingDialog.PNG)

[Vector](http://www.vector.co.jp/soft/screen/winnt/util/se506667.html) や[関連サイト](http://hp.vector.co.jp/authors/VA022068/soft/bin/km/KeyboardMouser.htm)で公開していたものを GitHub でも公開しました。

## Description

キーボード全体のキー配列を活かしてマウス操作が出来るマウスユーティリティーです。

もともとの発想は、
キーボードのキー配列をそのままディスプレイにマッピングできないか、
というところにあります。
つまり、いわゆるマウスカーソルをキーで動かすというよりは、
画面の位置をキーボード上でタッチするような、ペンタブレット的インタフェースを意識しています。

では、その特色は．．．

- キーボードの一部を画面に対応させたマップ的な移動と４方向移動の組み合わせで、  
ホームポジションを中心としたキーの範囲内だけでマウスカーソルを自由に移動させることが可能。  
加えて、クリック、ドラッグ操作もキーボードから可能。  
（キー設定は変更可能）

- クリック操作で操作を終了するのと、連続して操作をし続ける２つのモードが存在（ホットキーで切替）

- マルチディスプレイ環境にも対応

- AutoHotKey のスクリプトで作成・提供しているため、AutoHotKey/AutoHotoKeky_L 環境があれば、プログラム部分を含め任意にカスタマイズ可能（AHK_L を推奨）。 

詳しい機能説明は[こちらのページ](http://hp.vector.co.jp/authors/VA022068/soft/bin/km/KeyboardMouser.htm)を参照して下さい。

## Requirement & Install

- AHK/AHK_L 環境がある場合 → KeyboardMouser.ahk のスクリプトでそのまま実行可能です（AutoHotoKeky_L を推奨）
- AHK/AHK_L 環境がない場合 → AHK スクリプトをコンパイルした実行形式 KeyboardMouser.exe(32bit版)、KeyboardMouser_64.exe(64bit版) で利用可能です 

## Usage

KeyboardMouser.ahk/.exe を起動すると、タスクトレイにアイコンが表示されます。
そうすれば正常に起動しています。 

操作を開始するには、まず、

- ホットキーの Ctrl + Shift + 'm' キーを同時に押す（この設定は変更可能） 

すると、設定してあるキーボードのキーに対応してディスプレイを分割した画面がでてきます。 

- ディスプレイ上に表示されている対応するキーを押す
- tab/shift-tab でフォーカスを移した場所でスペース押し 

の操作で、そのエリアにマウスカーソルが移動します。
その選んだエリア内に対してこの動作を再帰的に行っていくことで、さらに詳細にマウスの位置決めができます。

また、カーソル移動用のキーで４方向の移動もできます。 

キーの

## Licence

GPL 2.0

## Author

[Rab-Duck](https://github.com/Rab-Duck/)
