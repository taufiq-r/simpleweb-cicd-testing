#!/bin/bash
# Generate correct MD5 password hash for pgbouncer userlist.txt

if [ -z "$1" ]; then
  echo "Usage: $0 <password>"
  exit 1
fi

PASSWORD="$1"
MD5_HASH=$(echo -n "$PASSWORD" | md5sum | awk '{print $1}')
echo "\"app\" \"md5$MD5_HASH\""
echo ""
echo "Add the above line to pgbouncer/userlist.txt"
