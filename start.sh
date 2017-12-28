#!/bin/bash

tableName=$1

# コマンドライン引数が渡されているか確認
if [ $# -ne 1]; then
  echo "第一引数にテーブル名が必要です。"
  echo "詳しくは、README を確認してください。"
  exit 1
fi

gitRootDirectoryPath=`git rev-parse --show-toplevel`
outsideFunctionAbsolutePath=$gitRootDirectoryPath/src/bin/$tableName.sh

# 外部ファイル読み込み
. $outsideFunctionAbsolutePath

# syslog のシンボリックリンクのファイルパス
syslogSymbolicLink='./syslog'
if [ ! -f $syslogSymbolicLink ]; then
  # syslog 絶対パス
  sysLogPath='/var/log/syslog'
  # 既にsyslog のシンボリックリンクが存在していなかったら、念のためシンボリックを作成
  ln -s $sysLogPath $syslogSymbolicLink
fi

sudo tail --follow=name --retry -n 0 $syslogSymbolicLink | parseSambaLog

parseSambaLog() {
  while IFS=' \t\n' read line
  do
    if [[ $line =~ smbd_audit: && ! $line =~ \|ok\|\.|.+\/\. ]] ;
    then
      echo $line | \
      while IFS='|' read header netBIOSName topDirecoryPath updatedTime \
        operation operationResult operatedPath; do

        operationAbsolutePathTemp=mktemp

        echo topDirecoryPath, $topDirecoryPath
        echo operatedPath, $operatedPath

        if [ $operation = "rename" ]; then
          echo $operatedPath | \
            while IFS='|' read oldFilePath newFilePath; do
              echo $topDirecoryPath/$newFilePath > operationAbsolutePathTemp
            done
        else
          echo $topDirecoryPath/$operatedPath > operationAbsolutePathTemp
        fi

        echo tableName, $tableName
        echo netBIOSName, $netBIOSName
        echo updatedTime, $updatedTime
        echo operation, $operation

        operationAbsolutePath=`cat $operationAbsolutePathTemp`

        echo operationAbsolutePath, $operationAbsolutePath
        rm $operationAbsolutePath

        # 外部関数呼び出し
        log $gitRootDirectoryPath \
          $tableName $netBIOSName $updatedTime $operation $operationAbsolutePath
      done
    fi
  done
}
