#!/bin/bash

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
  filePath=$8

  # shasum -a 256 $filePath で、sha256 を生成
  # $shasum -a 256 hoge.txt
  # 389ffd6c02fcb8aeb0e24501822253bf3f13fccdc3d7a98a65da51d1f884701f  hoge.txt
  # 余分なファイル名が存在するのでパイプで出力を渡し
  # 1文字目から、64文字目(sha256は64文字)までを $sha256 に格納
  sha256=`shasum -a 256 $filePath | cut -c 1-64`

  # log 関数へ渡された第三引数
  # ex. user
  tableName=$3

  # テーブルを作成するための sqlファイル へのパス
  # ex. /home/hoge/keep-watch-on-samba/src/sql/$dataBaseName/user.sql
  createTableSQL=$gitRootDirectoryPath/src/sql/$dataBaseName/$tableName.sql

  # $createTableSQL のパスが存在するとき true
  # true のときテーブルを作成する
  if [ -f $createTableSQL ]; then

    # ex. psql -U ri-one -h 192.168.11.5 -d soccer < /home/ri-one/keep-watch-on-samba/src/sql/$dataBaseName/user.sql
    # psql についての詳細は → Google!
    # psql -U $USER -h $HOST -d $dataBaseName < $createTableSQL

    # テーブルを作成後のsqlファイル へのパス
    # ex. /home/hoge/keep-watch-on-samba/src/sql/$dataBaseName/user_created.sql
    createdTableSQL=$gitRootDirectoryPath/src/sql/$dataBaseName/${tableName}_created.sql

    # /home/hoge/keep-watch-on-samba/src/sql/$dataBaseName/user.sql から
    # へファイル名変更 /home/hoge/keep-watch-on-samba/src/sql/$dataBaseName/user_created.sql
    # cp $createTableSQL $createdTableSQL

    # $createdTableSQL のパスが存在するとき true
    # true のとき、既にテーブルが作成されているので、テーブルを作成したsqlファイルを標準出力
    cat $createdTableSQL
    if [ -f $createdTableSQL ]; then
      echo "テーブルを作成したSQL"
      cat $createdTableSQL
      echo
    else
      echo "ああああああああああああああああああ"
      cp $createTableSQL $createdTableSQL
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

      # file_pathの行をカウントし、その数を格納
      filePathCount=`psql -U $USER -h $HOST -d $dataBaseName -c " \
        SELECT COUNT(file_path) FROM $tableName as count WHERE file_path = '$filePath' ;
        " | tr -d '\n' | tr -d ' ' | cut -c 13`

      echo $filePathCount
      # ファイルを新規作成する時
      if [ $filePathCount = "0" ]; then

        # log 関数へ渡された第四引数
        # ex. hogetaro
        createFileUserName=$4

        # クライアントが操作を行ったファイル名
        # ex. $ basename /home/hoge/share/hoge/test.txt
        #       test.txt
        fileName=`basename $filePath`

        # psql についての詳細は → Google!
        # SQL についての詳細は → Google!
        psql -U $USER -h $HOST -d $dataBaseName -c " \
        INSERT INTO $tableName \
          (create_file_user_name, file_name, file_path, sha256, created_at, updated_at) \
            VALUES ('$createFileUserName', '$fileName', '$filePath', '$sha256', '$updatedAt', '$updatedAt') ;
        "

      # 既に存在するファイルを更新した時
      else
        psql -U $USER -h $HOST -d $dataBaseName -c " \
          UPDATE $tableName SET sha256='$sha256', updated_at='$updatedAt' \
            WHERE file_path='$filePath' ;
        "
      fi

      ;;


    # $operation が unlinkのときに行われたファイル操作は削除
    "unlink" )
      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!
      psql -U $USER -h $HOST -d $dataBaseName -c " \
      DELETE FROM $tableName WHERE file_path = '$filePath' ;
    " ;;

    "rename" )
      # クライアントが操作を行ったファイル名
      fileName=`basename $filePath`

      # log 関数へ渡された第四引数
      # ex. 2017/12/27 11:05:00
      updatedAt=`date +"%Y/%m/%d %I:%M:%S"`

      # log 関数へ渡された第七引数
      # ex. /home/hoge/share/hoge/test.txt
      beforeFilePath=$7

      # psql についての詳細は → Google!
      # SQL についての詳細は → Google!
      psql -U $USER -h $HOST -d $dataBaseName -c " \
        UPDATE $tableName SET file_name='$fileName', file_Path='$filePath', updated_at='$updatedAt' \
          WHERE file_path='$beforeFilePath' AND sha256 = '$sha256' ;
    " ;;
  esac
}
