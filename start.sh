#!/bin/bash

tableName=$1
user=ri-one
host=192.168.11.5

gitRootDirectoryPath=`git rev-parse --show-toplevel`
outsideFunctionAbsolutePath=$gitRootDirectoryPath/src/bin/$tableName.sh

# 外部ファイル読み込み
. $outsideFunctionAbsolutePath

# syslog 絶対パス
sysLogPath='/var/log/syslog'

# syslog のシンボリックリンクのファイルパス
syslogSymbolicLink='./syslog'
if [ ! -f $syslogSymbolicLink ]; then
  # 既にsyslog のシンボリックリンクが存在していなかったら、念のためシンボリックを作成
  ln -s $sysLogPath $syslogSymbolicLink
fi

parseSambaLog() {
  while IFS=' \t\n' read line
  do
    if [[ $line =~ smbd_audit: && ! $line =~ \|ok\|\.|.+\/\. ]] ;
    then
      echo $line | \
      while IFS='|' read header netBIOSName topDirecoryPath updatedTime operation operationResult operatedPath; do
        echo netBIOSName, $netBIOSName
        echo updatedTime, $updatedTime
        echo operation, $operation

        if [ operation = "rename" ]; then
          while IFS='|' read oldFilePath newFilePath; do
            operationAbsolutePath=$topDirecoryPath/$newFilePath
          done
        else
          operationAbsolutePath=$topDirecoryPath/$operatedPath
        fi
        echo operationAbsolutePath, $operationAbsolutePath
        echo

        IFS=''

        # 外部関数呼び出し
        log $gitRootDirectoryPath \
          $tableName $netBIOSName $updatedTime $operation $operationAbsolutePath
      done
    fi
  done
}
echo $syslogSymbolicLink
sudo tail --follow=name --retry -n 0 $syslogSymbolicLink | parseSambaLog
