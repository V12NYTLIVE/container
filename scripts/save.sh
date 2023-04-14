#!/bin/bash

shopt -s dotglob

# Save all artifacts to temporary directory
# So when we run, if one mount is empty,
# it will be filled from the artifact

save () {
  mkdir -p /tmp/artifacts$1
  cp -a $1/* /tmp/artifacts$1/
  rm -rf $1/* ||:
}

# apply templates
cp -a /tmp/artifacts/templates/nginx.conf /etc/nginx/nginx.conf

# save artifacts
save /etc
save /var/log
save /var/lib/mysql
save /var/lib/postgresql
