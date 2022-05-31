#!/bin/bash
# created by dingtong on 20220512
# 脚本说明：检查应用日志文件
# sudo cat `sudo find /var/log/ -type f -name 'mysql*' -newermt $(date +%Y-%m-01) ! -newermt $(date -d next-day +%Y-%m-%d)` | awk '/Access denied/{print $8}' | grep '@' | tr -d "'" | sort | uniq -c | sort -nr | awk '{print "'\''"$2"'\''"":""'\''"$1"'\''"","}'


function check_log_mysql() {
  # 9463 127.0.0.1 6 192.168.31.203
  #log_failed_ssh=$(sudo cat `sudo find /var/log/ -name 'secure*' -newermt 2022-04-01 ! -newermt $(date -d next-day +%Y-%m-%d)` | awk '/Failed password/{print $(NF-3)}' | grep "^[0-9]" | sort | uniq -c | sort -nr | awk '{print "'\''"$2"'\''"":""'\''"$1"'\''"","}')
  log_failed_mysql=$(sudo cat `sudo find /var/log/ -type f -name 'mysql*' -newermt $(date +%Y-%m-01) ! -newermt $(date -d next-day +%Y-%m-%d)` | grep $(date +%Y-%m-) | grep '@' | awk -F'@| ' '/Access denied/{print $9}' | tr -d "'" | sort | uniq -c | sort -nr | awk '{print "'\''"$2"'\''"":""'\''"$1"'\''"","}')
  mysql_facts=$(
  cat <<EOF
  {
    "failed_mysql": "${log_failed_mysql:-}"
  }
EOF
  )
}


function main() {
  check_log_mysql

  check_facts=$(
    cat <<EOF
  {
    "log_mysql": ${mysql_facts:-[]}
  }
EOF
  )
    echo ${check_facts:-[]}
}


main

