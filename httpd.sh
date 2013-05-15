date=`date`
size=`ls -l ks.cfg | awk '{ print $5 }'`

cat <<EOF
HTTP/1.0 200 OK
Date: $date
Content-Type: text/plain
Content-Length: $size

EOF

cat ks.cfg
