#!/bin/bash

# 外部変数読み込み
  . $gitRootDirectoryPath/src/sql/createTable/db.conf

log() {
  tableName=$2
  createFileUserName=$3
  updatedAt=$4
  operation=$5
  filePath=$6

  fileName=`basename filePath`

  createTableSQL=../sql/createTable/$tableName.sql
  createdTableSQL=../sql/createTable/${tableName}_created.sql

  sha256=`shasum -a 256 $filePath | cut -c 1-64`

  if [ ! -f $createTableSQL ]; then
    psql -U $USER -h $HOST -d $DBNAME < createTableSQL
    mv createTableSQL ../sql/createTable/${tableName}_created.sql
  fi

  if [ ! -f $createdTableSQL ]; then
    cat $createdTableSQL
    echo
  fi

  psql psql -U $USER -h $HOST -d $DBNAME -c " \
  INSERT INTO $tableName \
    (create_file_user_name, file_name, file_path, sha256, created_at, updated_at)
      VALUES ($createFileUserName, $fileName, $filePath, $sha256, $updatedAt, $updatedAt)
  "
}
