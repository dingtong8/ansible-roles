#!/bin/bash
# created by dingtong on 20220601
# 脚本说明：检查应用日志文件
# ls -all -lh --time-style=long-iso /tmp/ | tail -n +4 | grep $(date +%Y-%m-) | awk '{print $NF}' | sort | uniq -c | sort -nr


function check_dir_virus() {
  tmp_ls=$(ls -all -lh --time-style=long-iso /tmp | tail -n +4 | grep $(date +%Y-%m-) | awk '{print $NF}' | sort | awk '{print "'\''"$1"'\''"","}')
  opt_ls=$(ls -all -lh --time-style=long-iso /dev | tail -n +4 | grep $(date +%Y-%m-) | awk '{print $NF}' | sort | awk '{print "'\''"$1"'\''"","}')

  dir_ls_facts=$(
  cat <<EOF
  {
    "tmp_ls": "${tmp_ls:-}",
    "opt_ls": "${opt_ls:-}"
  }
EOF
  )
}


function main() {
  check_dir_virus


  check_facts=$(
    cat <<EOF
  {
    "dir_ls_virus": ${dir_ls_facts:-[]}
  }
EOF
  )

  echo ${check_facts:-[]}
}


main