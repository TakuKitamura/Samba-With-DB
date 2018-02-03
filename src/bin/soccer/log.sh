#!/bin/bash

sendAbsolutePathListOfFileServer() {
  # 鍵のパス
  identifyFilePath="$HOME/.ssh/ri-oneFileServerRelayPoint.pem"

  # 鍵が存在しない時
  if [ ! -f $identifyFilePath ]; then
    echo ${identifyFilePath} が存在しません。
    echo "詳しくは、README を確認してください。"
    exit 2
  fi

  relayPointUser="ec2-user"

  host="13.231.55.13"

  baseDirectory=$Home/share

  absolutePathListOfFileServer=`find $baseDirectory | sed -e "s/$baseDirectory//g" | sed '1d'`

  ssh -i  $identifyFilePath "echo $absolutePathListOfFileServer > .absolutePathListOfFileServer"
}

# log 関数は、引数に格納されたデータをもとに、DBへSQLを発行する
log() {

  # log 関数へ渡された第一引数
  # ex. /home/hoge/keep-watch-on-samba
  gitRootDirectoryPath=$1

  dataBaseName=$2

  # 外部変数読み込み
  # 例えば、以下の変数が利用できるようになる
  # HOST=192.168.11.5
  # dataBaseName=soccer
  # USER=ri-one
  dbConfPath=$gitRootDirectoryPath/src/sql/$dataBaseName/db.conf

  # db.conf ファイルが指定ディレクトリに存在するか確認
  if [ ! -f $dbConfPath ]; then
    echo "keep-watch-on-samba/src/sql/(データベース名)/db.conf という設定ファイルを作成する必要があります。"
    echo "詳しくは、README を確認してください。"
    exit 2
  fi

  . $dbConfPath

  # log 関数へ渡された第八引数
  # ex. /home/hoge/share/hoge/test.txt
  afterFilePath=$8

  # shasum -a 256 $afterFilePath で、sha256 を生成
  # $shasum -a 256 hoge.txt
  # 389ffd6c02fcb8aeb0e24501822253bf3f13fccdc3d7a98a65da51d1f884701f  hoge.txt
  # 余分なファイル名が存在するのでパイプで出力を渡し
  # 1文字目から、64文字目(sha256は64文字)までを $sha256 に格納
  sha256=`shasum -a 256 $afterFilePath | cut -c 1-64`

  # log 関数へ渡された第三引数
  # ex. user
  tableName=$3

  # テーブルを作成するための sqlファイル へのパス
  # ex. /home/hoge/keep-watch-on-samba/src/sql/$dataBaseName/user.sql
  createTableSQL=$gitRootDirectoryPath/src/sql/$dataBaseName/$tableName.sql

  # $createTableSQL のパスが存在するとき true
  # true のときテーブルを作成する
  if [ -f $createTableSQL ]; then

    # $tableNameという、テーブルが存在する場合は、$tableNameが、存在しない場合はNullが格納
    existTableName=`psql -U $USER -h $HOST -d $dataBaseName -t -c " \
    SELECT relname FROM pg_class WHERE relkind = 'r' AND relname = '$tableName' ;
    " | tr -d ' \n'`

    # テーブルが存在する時
    if [ $existTableName ]; then
      echo "テーブル定義"
      cat $createTableSQL

    # テーブルが存在しない時
    else
      # テーブル作成
      # ex. psql -U ri-one -h 192.168.11.5 -d soccer < /home/ri-one/keep-watch-on-samba/src/sql/$dataBaseName/user.sql
      psql -U $USER -h $HOST -d $dataBaseName < $createTableSQL
    fi

  else
    echo $createTableSQL
    echo "keep-watch-on-samba/src/sql/(データベース名)/(テーブル名).sql というファイルを作成する必要があります。"
    echo "詳しくは、README を確認してください。"
    exit 2
  fi

  # log 関数へ渡された第六引数
  # ex. pwrite
  operation=$6

  # C言語的には SWITCH文
  echo ope=$operation
  case $operation in

    # $operation が pwriteのときに行われたファイル操作は新規作成
    "pwrite" )
    echo 実行:$operation

    # log 関数へ渡された第五引数
    # ex. 2017/12/27 11:05:00
    updatedAt=$5

    echo "SELECT COUNT(file_path) FROM $tableName as count WHERE file_path = '$afterFilePath' ;"

    # file_pathの行をカウントし、その数を格納
    afterFilePathCount=`psql -U $USER -h $HOST -d $dataBaseName -t -c " \
    SELECT COUNT(file_path) FROM $tableName as count WHERE file_path = '$afterFilePath' ;
    " | tr -d ' \n'`

    echo $afterFilePathCount
    # ファイルを新規作成する時
    if [ $afterFilePathCount = "0" ]; then

      # log 関数へ渡された第四引数
      # ex. hogetaro
      createFileUserName=$4

      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!

      echo "INSERT INTO $tableName \
      (create_file_user_name, file_path, sha256, created_at, updated_at) \
      VALUES ('$createFileUserName', '$afterFilePath', '$sha256', '$updatedAt', '$updatedAt') ;"

      # ファイルを新規作成
      psql -U $USER -h $HOST -d $dataBaseName -c " \
      INSERT INTO $tableName \
      (create_file_user_name, file_path, sha256, created_at, updated_at) \
      VALUES ('$createFileUserName', '$afterFilePath', '$sha256', '$updatedAt', '$updatedAt') ;
      "

      sendAbsolutePathListOfFileServer

      # 既に存在するファイルを更新した時
    else

      echo "UPDATE $tableName SET sha256='$sha256', updated_at='$updatedAt' \
      WHERE file_path='$afterFilePath' ;"

      # ファイルを編集
      psql -U $USER -h $HOST -d $dataBaseName -c " \
      UPDATE $tableName SET sha256='$sha256', updated_at='$updatedAt' \
      WHERE file_path='$afterFilePath' ;
      "
    fi

    ;;


    # $operation が unlinkのときに行われたファイル操作は削除
    "unlink" )
    # psql についての詳細は → Google!
    # SQL についての詳細は → Google!

    echo "DELETE FROM $tableName WHERE file_path = '$afterFilePath' ;"

    # ファイルを削除
    psql -U $USER -h $HOST -d $dataBaseName -c " \
    DELETE FROM $tableName WHERE file_path = '$afterFilePath' ;
    "

    sendAbsolutePathListOfFileServer

    ;;

    "rename" )
    # log 関数へ渡された第七引数
    # ex. /home/hoge/share/hoge/test.txt
    beforeFilePath=$7

    # ファイル、シンボリックリンクの場合
    if [ -f $afterFilePath ]; then

      # log 関数へ渡された第四引数
      # ex. 2017/12/27 11:05:00
      # updatedAt=`date +"%Y/%m/%d %I:%M:%S"`

      # log 関数へ渡された第五引数
      # ex. 2017/12/27 11:05:00
      updatedAt=$5

      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!

      echo "UPDATE $tableName SET file_Path='$afterFilePath', updated_at='$updatedAt' \
      WHERE file_path='$beforeFilePath' AND sha256 = '$sha256' ;"

      # ファイル名を変更
      psql -U $USER -h $HOST -d $dataBaseName -c " \
      UPDATE $tableName SET file_Path='$afterFilePath', updated_at='$updatedAt' \
      WHERE file_path='$beforeFilePath' AND sha256 = '$sha256' ;
      "

      # ディレクトリの場合
    elif [ -d $afterFilePath ]; then
      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!
      # ディレクトリ名変更前のパス
      beforeDirPath=$beforeFilePath/

      # ディレクトリ名変更後のパス
      dirPath=$afterFilePath/

      echo "UPDATE $tableName SET file_Path=replace(file_Path, '$beforeDirPath', '$dirPath') \
      WHERE file_path LIKE '$beforeDirPath%' ;"

      # ディレクトリ名を変更
      psql -U $USER -h $HOST -d $dataBaseName -c " \
      UPDATE $tableName SET file_Path=replace(file_Path, '$beforeDirPath', '$dirPath') \
      WHERE file_path LIKE '$beforeDirPath%' ;
      "

    else
      echo "rename エラー"
    fi

    sendAbsolutePathListOfFileServer
    ;;
  esac
}
