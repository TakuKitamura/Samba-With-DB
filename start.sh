#!/bin/bash

# 内容理解をすべて理解するには bashの最低限の知識が必要
# bash について詳しくは → Google!

# ただ、処理の流れは理解できるようにコメントはきちんと書きます

# コマンドライン引数が渡されているか確認

option=$1

if [ $option != '-t']; then


  if [ $# -ne 2 ]; then
    echo "第一引数にデータベース名、第二引数にテーブル名が必要です。"
    echo "詳しくは、README を確認してください。"
    exit 2
  fi

  # コマンドライン引数の第一引数を取得
  # ex $ /home/hoge/keep-watch-on-samba/start.sh soccer log
  # この場合 $dataBaseName は soccer $tableName は log

  dataBaseName=$1
  tableName=$2

  # gitのルートパスを取得
  # ex. /home/hoge/keep-watch-on-samba
  gitRootDirectoryPath=`git rev-parse --show-toplevel`

  # 実行ファイルを git root で実行しているか確認
  if [ ! -d $gitRootDirectoryPath ]; then
    echo "git root ディレクトリで $ ./start.sh と実行してください。"
    echo "詳しくは、README を確認してください。"
    exit 2
  fi

  # src/bin/(テーブル名).sh というファイルの絶対パスを取得し、その外部ファイルを読み込み
  # ex. /home/hoge/keep-watch-on-samba/src/bin/soccer/user.sh
  outsideFunctionAbsolutePath=$gitRootDirectoryPath/src/bin/$dataBaseName/$tableName.sh

  # 正しい第一引数のデータベース名 もしくは、第二引数のテーブル名 かを確認
  if [ ! -f $outsideFunctionAbsolutePath ]; then
    echo "第一引数のデータベース名 もしくは、第二引数のテーブル名が誤っています。"
    echo "詳しくは、README を確認してください。"
    exit 2
  fi

  . $outsideFunctionAbsolutePath

  syslogSymbolicLink='./syslog'

  # syslog のシンボリックリンクが存在しなかったら、シンボリックリンクを作成
  if [ ! -f $syslogSymbolicLink ]; then
    sysLogPath='/var/log/syslog'

    # 正しい第一引数のデータベース名 もしくは、第二引数のテーブル名 かを確認
    if [ ! -f $sysLogPath ]; then
      echo "デフォルトではsysLogの絶対パスは、$sysLogPath に設定されています。"
      echo "sysLogの絶対パスが違う場合は、 start.sh の sysLogPath を修正してください。"
      echo "詳しくは、README を確認してください。"
      exit 2
    fi
    ln -s $sysLogPath $syslogSymbolicLink
  fi
fi


# retry オプション
# ファイルを名前で追跡していて、ファイルがなくなったことを検知したら、 再オープンを成功するまで繰り返す

# n LINES オプション
# 末尾の LINES 行を表示する。 この場合、末尾の出力は必要ないので 0を指定

# syslog のシンボリックが指す先、 $sysLogPath のファイルに変更があると関数 parseSambaLog呼び出し
# C言語的に書くと
# while(1) {
#   if(ファイル変更が起きた)
#     変更が起きた文字列に対しての処理;
# }

# main 処理
sudo tail --follow --retry -n 0 $syslogSymbolicLink | . ./parse.sh option

echo "何かしらが原因で tail コマンドの実行が終了しました。"
echo "何が原因で、 tail コマンドが終了したか調べてください。"
exit 1
