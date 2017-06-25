#!/bin/bash

set -e

IPADDR=$1

ssh -t -t -i ~/.ssh/isucon4-qualifier.pem ec2-user@$IPADDR sh <<SHELL
  echo ===== Deploying... =====

  sudo su - isucon

  cd /home/isucon/webapp

  echo ===== Move... =====

  CURRENT_COMMIT=`git rev-parse HEAD`

  git pull --rebase origin master

  cd ruby

  echo ===== Rotate log files =====
  if sudo test -f "/var/lib/mysql/mysqld-slow.log"; then
    echo == Roatate mysqld-slow.log ==
    sudo mv /var/lib/mysql/mysqld-slow.log /var/lib/mysql/mysqld-slow.log.$(date "+%Y%m%d_%H%M%S").$CURRENT_COMMIT
  fi

  if sudo test -f "/var/log/nginx/access.log"; then
    echo == Roatate access.log ==
    sudo mv /var/log/nginx/access.log /var/log/nginx/access.log.$(date "+%Y%m%d_%H%M%S").$CURRENT_COMMIT
  fi

  echo ===== Bundle Install =====
  ~/.local/ruby/bin/bundle install

  echo ===== Copy sysctl.conf  =====
  if [ -f /etc/sysctl.conf ]; then
    sudo rm /etc/sysctl.conf
  fi

  sudo cp config/sysctl.conf /etc/sysctl.conf
  sudo chmod 0644 /etc/sysctl.conf

  sudo sysctl -p

  echo ===== Copy my.cnf  =====
  if [ -f /etc/my.cnf ]; then
    sudo rm /etc/my.cnf
  fi

  sudo cp config/my.cnf /etc/my.cnf
  sudo chmod 0400 /etc/my.cnf

  echo ===== Restart MySQL =====
  sudo service mysqld restart

  echo ===== Copy nginx.conf  =====
    if [ -f /etc/nginx/nginx.conf ]; then
    sudo rm /etc/nginx/nginx.conf
  fi

  sudo cp config/nginx.conf /etc/nginx/nginx.conf

  echo ===== Restart nginx =====
  sudo /etc/init.d/nginx restart

  echo ===== Copy redis.conf  =====
  if [ -f /etc/redis.conf ]; then
    sudo rm /etc/redis.conf
  fi

  sudo cp config/redis.conf /etc/redis.conf
  sudo chmod 0640 /etc/redis.conf
  sudo chown isucon:isucon /etc/redis.conf

  echo ===== Copy supervisord.conf  =====
  if [ -f /etc/supervisord.conf ]; then
    sudo rm /etc/supervisord.conf
  fi

  sudo cp config/supervisord.conf /etc/supervisord.conf
  sudo chmod 0644 /etc/supervisord.conf

  echo ===== Restart supervisord =====
  sudo /etc/init.d/supervisord stop

  # unicorn 死なないみたいなので...
  pkill -QUIT -f unicorn

  sudo /etc/init.d/supervisord start

  echo ===== Copy init.sh  =====
  if [ -f /home/isucon/init.sh ]; then
    rm /home/isucon/init.sh
  fi

  cp config/init.sh /home/isucon/init.sh
  chmod 755 /home/isucon/init.sh

  echo ===== FINISHED =====

  exit
  exit
SHELL
