#!/bin/bash

# 内容理解をすべて理解するには bashの最低限の知識が必要
# bash について詳しくは → Google!

# ただ、処理の流れは理解できるようにコメントはきちんと書きます

# コマンドライン引数が渡されているか確認

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

# $sysLogPath のファイルの末尾行の文字列を必要な形に整形する関数
parseSambaLog() {

  # $sysLogPath の末尾の行を $line として読み込む。
  # IFS 環境変数は、sh や bash でコマンドラインの引数を 分割するために使用するキャラクタ
  # IFS について詳しくは → Google!
  while IFS=' \t\n' read line
  do

    # $line =~ smbd_audit:
    # sysLogから、 sambaのファイル操作に関する情報のみにしぼる正規表現
    # smbd_audit について
    # http://www.samba.gr.jp/project/translation/3.5/htmldocs/manpages-3/vfs_full_audit.8.html

    # $line =~ \|ok\|\.|.+\/\.
    # sysLogから、 ファイル操作が成功('ok')であり、隠しファイル('.'から始まる)に対するファイル操作に関する情報のみにしぼる正規表現
    # 'ok' は smbd_auditの RESULT フィールド(上のsmbd_audit について を参照)

    # 'smbd_audit:'という文字列を含む かつ ファイル操作が成功で隠しファイル以外('!' で否定)のファイル操作に関する情報のとき true
    if [[ $line =~ smbd_audit: && ! $line =~ \|ok\|\.|.+\/\. ]] ;
    then

      # プログラムに必要な情報が存在する行から、必要なデータのみ読み込み、データを処理する
      echo $line | \

      # '|' 区切りで、sysLog の行をそれぞれの変数に読み取り
      # 実際のデータは、ex. $ cat /home/ri-one/keep-watch-on-samba/sysLog などで要確認
      while IFS='|' read header netBIOSName topDirecoryPath updatedTime \
        operation operationResult operatedPath; do

        # mktemp: 適当なファイル名の空ファイルを作成する
        # 一時的に、データを保存したいので使用する
        # ex. $ mktemp
        #     /tmp/tmp.dpgp9A7UxD

        # $[before|after]OperationAbsolutePathTemp には、 /tmp/tmp.dpgp9A7UxD などが格納される
        # 下記の処理で、一時ファイルを利用しているかは、(もっとスマートな実装ができる気がする)
        # http://www.atmarkit.co.jp/ait/articles/1209/14/news147.html などを参照

        afterOperationAbsolutePathTemp=`mktemp`
        beforeOperationAbsolutePathTemp=`mktemp`

        echo topDirecoryPath, $topDirecoryPath
        echo operatedPath, $operatedPath

        # OPERATION がrenameのとき
        # OPERATION は、 smbd_audit についてを参照
        if [ $operation = "rename" ]; then
          echo $operatedPath | \
            # ex. operatedPathには、 (ファイル操作前のファイルパス)|(ファイル操作後のファイルパス)
            # という、パスが渡されるので '|' で区切り、それぞれの変数に格納
            while IFS='|' read beforeFilePath afterFilePath; do

              # $[before|after]OperationAbsolutePathTemp それぞれに、ファイル操作を行う前、行った後のファイルパスを書き込み
              # ex. $beforeOperationAbsolutePath: /home/hoge/share/hoge/test.txt
              # ex. $afterOperationAbsolutePath: /home/hoge/share/hoge/test.txt
              echo $topDirecoryPath/$beforeFilePath > beforeOperationAbsolutePathTemp
              echo $topDirecoryPath/$afterFilePath > afterOperationAbsolutePathTemp
            done
        else
          # $[before|after]OperationAbsolutePathTemp それぞれに、空文字、ファイル操作を行った後のファイルパスを書き込み
          # ex. $beforeOperationAbsolutePath:
          # ex. $afterOperationAbsolutePath: /home/hoge/share/hoge/test.txt
          echo "" > beforeOperationAbsolutePathTemp
          echo $topDirecoryPath/$operatedPath > afterOperationAbsolutePathTemp
        fi

        # $beforeOperationAbsolutePathTempには、 /home/hoge/share/hoge/newTest.txt もしくは空文字 などが書き込まれている
        # $afterOperationAbsolutePathTempには、 /home/hoge/share/hoge/test.txt などが書き込まれている

        echo tableName, $tableName
        echo netBIOSName, $netBIOSName
        echo updatedTime, $updatedTime
        echo operation, $operation

        # $beforeOperationAbsolutePathTemp の内容を $beforeOperationAbsolutePath へ格納
        beforeOperationAbsolutePath=`cat beforeOperationAbsolutePathTemp`
        echo beforeOperationAbsolutePath, $beforeOperationAbsolutePath

        # 以降の処理では必要ない一時ファイルなので削除
        rm beforeOperationAbsolutePathTemp

        # $afterOperationAbsolutePathTemp の内容を $afterOperationAbsolutePath へ格納
        afterOperationAbsolutePath=`cat afterOperationAbsolutePathTemp`
        echo afterOperationAbsolutePath, $afterOperationAbsolutePath

        # 以降の処理では必要ない一時ファイルなので削除
        rm afterOperationAbsolutePathTemp

        # 外部関数呼び出し(上記の以下の処理)
        # outsideFunctionAbsolutePath=$gitRootDirectoryPath/src/bin/$tableName.sh
        # . $outsideFunctionAbsolutePath

        # $tableName という名前が付けられた外部関数を呼び出し
        # c言語的に書くと
        # tableName($gitRootDirectoryPath, $tableName, $netBIOSName, $updatedTime, $operation, $beforeOperationAbsolutePath, $afterOperationAbsolutePath);

        # tableName　関数は、引数に格納されたデータをもとに、DBへSQLを発行する
        # SQL については → Google
	echo $tableName, $gitRootDirectoryPath, $dataBaseName, $tableName, \
			          $netBIOSName, $updatedTime, $operation, $beforeOperationAbsolutePath, $afterOperationAbsolutePath
        $tableName "$gitRootDirectoryPath" "$dataBaseName" "$tableName" \
          "$netBIOSName" "$updatedTime" "$operation" "$beforeOperationAbsolutePath" "$afterOperationAbsolutePath"
      done
    fi
  done
}

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
sudo tail --follow --retry -n 0 $syslogSymbolicLink | parseSambaLog

echo "何かしらが原因で tail コマンドの実行が終了しました。"
echo "何が原因で、 tail コマンドが終了したか調べてください。"
exit 1
