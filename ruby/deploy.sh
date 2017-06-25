#!/bin/bash

set -e

IPADDR=$1

ssh -t -t -i ~/.ssh/isucon4-qualifier.pem ec2-user@$IPADDR sh <<SHELL
  echo ===== Deploying... =====

  sudo su - isucon

  cd /home/isucon/webapp

  echo ===== Move... =====

  # CURRENT_COMMIT=`git rev-parse HEAD`

  git pull --rebase origin master

  cd ruby

  echo ===== Rotate log files =====
  if sudo test -f "/var/lib/mysql/mysqld-slow.log"; then
    echo == Roatate mysqld-slow.log ==
    sudo mv /var/lib/mysql/mysqld-slow.log /var/lib/mysql/mysqld-slow.log.$(date "+%Y%m%d_%H%M%S").$CURRENT_COMMIT
  fi

  # if sudo test -f "/var/log/nginx/access.log"; then
  # echo == Roatate access.log ==
  # sudo mv /var/log/nginx/access.log /var/log/nginx/access.log.$(date "+%Y%m%d_%H%M%S").$CURRENT_COMMIT
  # fi

  echo ===== Bundle Install =====
  ~/.local/ruby/bin/bundle install

  echo ===== Copy my.cnf  =====
  if [ -f /etc/my.cnf ]; then
    sudo rm /etc/my.cnf
  fi

  sudo cp config/my.cnf /etc/my.cnf
  sudo chmod 0400 /etc/my.cnf

  echo ===== Restart MySQL =====
  sudo service mysqld restart

  # echo ===== Copy nginx.conf  =====
  # if [ -f /etc/nginx/nginx.conf ]; then
  # sudo rm /etc/nginx/nginx.conf
  # fi

  # sudo cp ../config/nginx.conf /etc/nginx/nginx.conf

  echo ===== Restart supervisord =====
  sudo /etc/init.d/supervisord stop

  # unicorn 死なないみたいなので...
  pkill -QUIT -f unicorn

  sudo /etc/init.d/supervisord start

  echo ===== FINISHED =====
SHELL
