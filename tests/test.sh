#!/bin/bash

# $? は、直前のコマンドの終了ステータスが入った環境変数
#        ------
#          ↑ これ超大事
# 			 parse.shにて成功時（tableName関数が呼び出せるとき ）、0

# parse.shに渡す文字列に誤りがないとき
# このテストは成功しなければそもそもに誤りがある
testCorrectFormat()
{
	echo ""
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ok|test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 0 $result
	echo ""
}

#以下は文字列に何らかの間違いがある

# ファイル操作の成否に関するテスト
# "ok" -> "ng"
testSuccess1()
{
	echo ""
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ng|test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# "ok" -> ""
testSuccess2()
{
	echo ""
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# "ok" -> "vaokva"
testSuccess3()
{
	echo ""
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite| ok |test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# 隠しファイルを弾くテスト
# "test.pdf" -> ".test.pdf"
testNotHidden()
{
	echo ""
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ok|.test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# 以下のようにすると何故か成功してしまう( おそらく正規表現がおかしい？？
# 成否を正しくない形にして、隠しファイルを操作しようとしている
# "ok" -> "ng" , "test.pdf" -> ".test.pdf"
testWhy(){
	echo ""
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ng|.test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# tagに関するテスト
# "smbd_audit:" -> ""
testTag1()
{
	echo ""
	echo "Feb 10 12:19:47 debian |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ok|test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# "smbd_audit:" -> "smdb_audit:"
testTag2()
{
	echo ""
	echo "Feb 10 12:19:47 debian smdb_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ok|test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# "smbd_audit:" -> "vasmbd_audit:va"
testTag3()
{
	echo ""
	echo "Feb 10 12:19:47 debian vasmbd_audit:va |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ok|test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

# "smbd_audit:" -> "s m b d _ a u d i t :"
testTag4()
{
	echo ""
	echo "Feb 10 12:19:47 debian s m b d _ a u d i t : |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ok|test.pdf" | . ../parse.sh -t
	result=$?
	echo ""
	assertEquals 1 $result
	echo ""
}

. ./shunit2-2.1.6/src/shunit2
