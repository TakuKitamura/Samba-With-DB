#!/bin/bash

log() {
  # 外部変数読み込み
  gitRootDirectoryPath=$1
  . $gitRootDirectoryPath/src/sql/createTable/db.conf
  tableName=$2
  createFileUserName=$3
  updatedAt=$4
  operation=$5
  filePath=$6

  fileName=`basename $filePath`

  createTableSQL=$gitRootDirectoryPath/src/sql/createTable/$tableName.sql
  createdTableSQL=$gitRootDirectoryPath/src/sql/createTable/${tableName}_created.sql

  sha256=`shasum -a 256 $filePath | cut -c 1-64`

  if [ -f $createTableSQL ]; then
    psql -U $USER -h $HOST -d $DBNAME < $createTableSQL
    mv $createTableSQL $gitRootDirectoryPath/src/sql/createTable/${tableName}_created.sql
  fi

  if [ ! -f $createdTableSQL ]; then
    cat $createdTableSQL
    echo
  fi

  case $operation in
    "pwrite" ) psql -U $USER -h $HOST -d $DBNAME -c " \
      INSERT INTO $tableName \
        (create_file_user_name, file_name, file_path, sha256, created_at, updated_at) \
          VALUES ('$createFileUserName', '$fileName', '$filePath', '$sha256', '$updatedAt', '$updatedAt');
    " ;;

    "unlink" ) psql -U $USER -h $HOST -d $DBNAME -c " \
      DELETE FROM $tableName WHERE file_path = '$filePath';
    " ;;

    "rename" )
      updatedAt=`date +"%Y/%m/%d %I:%M:%S"`
      psql -U $USER -h $HOST -d $DBNAME -c " \
        UPDATE $tableName SET file_name='$fileName', file_Path='$filePath', updated_at='$updatedAt' \
          WHERE sha256 = '$sha256'
    " ;;
  esac


}
