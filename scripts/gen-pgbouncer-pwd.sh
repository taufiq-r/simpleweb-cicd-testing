#!/bin/bash
# Script to generate MD5 password hash for pgbouncer userlist

PASSWORD="changeme"
MD5_HASH=$(echo -n "$PASSWORD" | md5sum | awk '{print $1}')
echo "\"app\" \"md5$MD5_HASH\""
