#!/bin/bash

testPermission()
{
	echo "Feb 10 12:19:47 debian smbd_audit: |kitamurataku|/home/ri-one/share|2018/02/10 12:19:47|pwrite|ng|test.pdf" | . ~/samba-with-db/parse.sh
}



. ./shunit2-2.1.6/src/shunit2
