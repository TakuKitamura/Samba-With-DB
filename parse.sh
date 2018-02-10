#!/bin/bash

# $sysLogPath のファイルの末尾行の文字列を必要な形に整形するシェルスクリプト

# if [ ! $# = 0 ] ; then
# 	if [ ! $# = 1 -o ! "$1" = "-t" ] ; then
# 		echo "不明な引数です。テストモードで起動するには、"
# 		echo "./parse.sh -t"
# 		echo "以上のように端末に入力してください。"
# 		exit 2
# 	#else
# 		#echo "テストモードで起動しました。"
# 	fi
# #else
# 	#echo "通常モードで起動しました。"
# fi
#
# testMode=( $# = 1 -a "$1" = "-t" )

option=$1

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


			if [ -z "$option" ]; then
				echo $tableName, $gitRootDirectoryPath, $dataBaseName, $tableName, \
				$netBIOSName, $updatedTime, $operation, $beforeOperationAbsolutePath, $afterOperationAbsolutePath
				$tableName "$gitRootDirectoryPath" "$dataBaseName" "$tableName" \
				"$netBIOSName" "$updatedTime" "$operation" "$beforeOperationAbsolutePath" "$afterOperationAbsolutePath"
			fi
		done
		exit 0
	fi
done
exit 1
