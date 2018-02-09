#!/bin/bash

testPermission()
{
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ng|test.pdf" | . ../parse.sh -t
	ret=$?
	assertEquals $ret 1
}

. ./shunit2-2.1.6/src/shunit2
