#!/bin/bash
# created by dingtong on 20220512
# 脚本说明：检查应用日志文件
# sudo cat `sudo find /var/log/ -name 'secure*' -newermt $(date +%Y-%m-01) ! -newermt $(date +%Y-%m-%d)` | awk '/Failed password/{print $(NF-3)}' | grep "^[0-9]" | sort | uniq -c | sort -nr | awk 'BEGIN{FS=" ";print "IP""\t\t\t""SSH失败次数"}{print $2"\t\t"$1}'


function check_log_ssh() {
  # 9463 127.0.0.1 6 192.168.31.203
  log_failed_ssh=$(sudo cat `sudo find /var/log/ -name 'secure*' -newermt 2022-04-01 ! -newermt $(date -d next-day +%Y-%m-%d)` | awk '/Failed password/{print $(NF-3)}' | grep "^[0-9]" | sort | uniq -c | sort -nr | awk '{print "'\''"$2"'\''"":""'\''"$1"'\''"","}')

  ssh_facts=$(
  cat <<EOF
  {
    "failed_ssh": "${log_failed_ssh:-}"
  }
EOF
  )
}


function main() {
  check_log_ssh

  check_facts=$(
    cat <<EOF
  {
    "log_ssh": ${ssh_facts:-[]}
  }
EOF
  )

    echo ${check_facts:-[]}
}


main