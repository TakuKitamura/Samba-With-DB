#!/bin/bash

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
  while IFS='|' read header netBIOSName topDirecoryPath updatedTime operation operationResult operatedPath
  do
    echo netBIOSName, $netBIOSName
    echo updatedTime, $updatedTime
    echo operation, $operation
    echo operationAbsolutePath, $topDirecoryPath/$operatedPath
    echo
  done
  fi
done
}
echo $syslogSymbolicLink
sudo tail --follow=name --retry -n 0 $syslogSymbolicLink | parseSambaLog
