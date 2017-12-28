#!/bin/bash

# log 関数は、引数に格納されたデータをもとに、DBへSQLを発行する
log() {

  # log 関数へ渡された第一引数
  # ex. /home/hoge/keep-watch-on-samba
  gitRootDirectoryPath=$1

  # 外部変数読み込み
  # 例えば、以下の変数が利用できるようになる
  # HOST=192.168.11.5
  # DBNAME=soccer
  # USER=ri-one
  . $gitRootDirectoryPath/src/conf/db.conf

  # log 関数へ渡された第七引数
  # ex. /home/hoge/share/hoge/test.txt
  filePath=$7

  # shasum -a 256 $filePath で、sha256 を生成
  # $shasum -a 256 hoge.txt
  # 389ffd6c02fcb8aeb0e24501822253bf3f13fccdc3d7a98a65da51d1f884701f  hoge.txt
  # 余分なファイル名が存在するのでパイプで出力を渡し
  # 1文字目から、64文字目(sha256は64文字)までを $sha256 に格納
  sha256=`shasum -a 256 $filePath | cut -c 1-64`

  # log 関数へ渡された第二引数
  # ex. user
  tableName=$2

  # テーブルを作成するための sqlファイル へのパス
  # ex. /home/hoge/keep-watch-on-samba/src/sql/createTable/user.sql
  createTableSQL=$gitRootDirectoryPath/src/sql/createTable/$tableName.sql

  # $createTableSQL のパスが存在するとき true
  # true のときテーブルを作成する
  if [ -f $createTableSQL ]; then

    # ex. psql -U ri-one -h 192.168.11.5 -d soccer < /home/ri-one/keep-watch-on-samba/src/sql/createTable/user.sql
    # psql についての詳細は → Google!
    psql -U $USER -h $HOST -d $DBNAME < $createTableSQL

    # /home/hoge/keep-watch-on-samba/src/sql/createTable/user.sql から
    # へファイル名変更 /home/hoge/keep-watch-on-samba/src/sql/createTable/user_created.sql
    mv $createTableSQL $gitRootDirectoryPath/src/sql/createTable/${tableName}_created.sql
  fi

  # ex. /home/hoge/keep-watch-on-samba/src/sql/createTable/user_created.sql
  createdTableSQL=$gitRootDirectoryPath/src/sql/createTable/${tableName}_created.sql

  # $createdTableSQL のパスが存在するとき true
  # true のとき、既にテーブルが作成されているので、テーブルを作成したsqlファイルを標準出力
  if [ -f $createdTableSQL ]; then
    echo "テーブルを作成したSQL"
    cat $createdTableSQL
    echo
  fi

  # log 関数へ渡された第五引数
  # ex. pwrite
  operation=$5

  # C言語的には SWITCH文
  case $operation in

    # $operation が pwriteのときに行われたファイル操作は新規作成
    "pwrite" )

      # log 関数へ渡された第三引数
      # ex. hogetaro
      createFileUserName=$3

      # クライアントが操作を行ったファイル名
      # ex. $ basename /home/hoge/share/hoge/test.txt
      #       test.txt
      fileName=`basename $filePath`

      # log 関数へ渡された第四引数
      # ex. 2017/12/27 11:05:00
      updatedAt=$4

      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!
      psql -U $USER -h $HOST -d $DBNAME -c " \
      INSERT INTO $tableName \
        (create_file_user_name, file_name, file_path, sha256, created_at, updated_at) \
          VALUES ('$createFileUserName', '$fileName', '$filePath', '$sha256', '$updatedAt', '$updatedAt');
    " ;;

    # $operation が unlinkのときに行われたファイル操作は削除
    "unlink" )
      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!
      psql -U $USER -h $HOST -d $DBNAME -c " \
      DELETE FROM $tableName WHERE file_path = '$filePath';
    " ;;

    "rename" )
      # クライアントが操作を行ったファイル名
      fileName=`basename $filePath`

      # log 関数へ渡された第四引数
      # ex. 2017/12/27 11:05:00
      updatedAt=`date +"%Y/%m/%d %I:%M:%S"`

      # log 関数へ渡された第六引数
      # ex. /home/hoge/share/hoge/test.txt
      beforeFilePath=$6

      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!
      psql -U $USER -h $HOST -d $DBNAME -c " \
        UPDATE $tableName SET file_name='$fileName', file_Path='$filePath', updated_at='$updatedAt' \
          WHERE file_path='$beforeFilePath' AND sha256 = '$sha256';
    " ;;
  esac
}
