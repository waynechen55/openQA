#!/bin/bash
#set -e
set -exv

function wait_for_db_creation() {
  echo "Waiting for DB creation"
  #while ! su geekotest -c 'PGPASSWORD=openqa psql -h db -U openqa --list | grep -qe openqa'; do sleep .1; done
  #while ! su geekotest -c 'PGPASSWORD=openqa psql -h localhost -U geekotest --list | grep -qe openqa'; do sleep .1; done
  while ! su geekotest -c 'PGPASSWORD=openqa psql -h localhost -U geekotest --list | grep -qe openqa'; do sleep .1; done
}

function upgradedb() {
  wait_for_db_creation
  su geekotest -c '/usr/share/openqa/script/upgradedb --upgrade_database'
}

function scheduler() {
  su geekotest -c /usr/share/openqa/script/openqa-scheduler-daemon
}

function websockets() {
  su geekotest -c /usr/share/openqa/script/openqa-websockets-daemon
}

function gru() {
  wait_for_db_creation
  su geekotest -c /usr/share/openqa/script/openqa-gru
}

function livehandler() {
  wait_for_db_creation
  su geekotest -c /usr/share/openqa/script/openqa-livehandler-daemon
}

function webui() {
  wait_for_db_creation
  su geekotest -c /usr/share/openqa/script/openqa-webui-daemon
}

function apache2() {
  thishost=`hostname`
  sed -i -r  "s/SERVERPLACEHOLDER/$thishost/g" /etc/apache2/vhosts.d/openqa.conf 
  for i in headers proxy proxy_http proxy_wstunnel rewrite ; do a2enmod $i ; done
  apache2ctl start
}

function all_together_apache() {
  # run services
  su geekotest -c /usr/share/openqa/script/openqa-scheduler-daemon &
  su geekotest -c /usr/share/openqa/script/openqa-websockets-daemon &
  wait_for_db_creation
  su geekotest -c /usr/share/openqa/script/openqa-gru &
  su geekotest -c /usr/share/openqa/script/openqa-livehandler-daemon &
  ps axu | grep daemon
  apache2
  su geekotest -c /usr/share/openqa/script/openqa-webui-daemon
}

usermod --shell /bin/sh geekotest
all_together_apache
# run services
#case "$MODE" in
#  upgradedb ) upgradedb;;
#  scheduler ) scheduler;;
#  websockets ) websockets;;
#  gru ) gru;;
#  livehandler ) livehandler;;
#  webui ) webui;;
#  * ) all_together_apache;;
#esac
