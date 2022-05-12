#!/bin/bash
# author: dingtong
# date: 2019-10-11
# 服务器基础资源检查
# 获取系统信息
# 获取cpu使用信息
# 获取内存使用信息
# 获取磁盘使用信息
# 获取网络信息
# 返回
# check_facts = {
#    "system": {
#        "hostname": "dy223", "default_ipv4": "192.168.31.223", "distribution": "centos",
#        "distribution_version": "7.9.2009", "os_pretty_name": "CentOS Linux 7 (Core)",
#        "kernel": "3.10.0-1160.el7.x86_64", "os_time": "2022-05-12 11:05:02", "uptime": "1"},
#    "cpu": {
#        "cpu_usedutilization": "0", "cpu_loadavg1": "0.03", "cpu_loadavg5": "0.02", "cpu_loadavg15": "0.05"},
#    "mem": {
#        "memtotal": "16039416", "memfree": "246764", "memavailable": "12320384", "memcache": "12113828",
#        "membuffer": "0", "mem_usedutilization": "22.94", "swaptotal": "7167996", "swapfree": "7029244",
#        "swap_usedutilization": "1.94"},
#    "disk": [
#        {"mount": "/", "size_total": "50G", "size_use": "11G", "size_available": "40G", "size_usedutilization": "21",
#         "block_total": "51175M", "block_use": "10338M", "block_available": "40838M", "block_usedutilization": "21",
#         "inode_total": "25M", "inode_use": "227K", "inode_available": "25M", "inode_usedutilization": "1"},
#        {"mount": "/boot", "size_total": "1014M", "size_use": "150M", "size_available": "865M",
#         "size_usedutilization": "15", "block_total": "1014M", "block_use": "150M", "block_available": "865M",
#         "block_usedutilization": "15", "inode_total": "512K", "inode_use": "327", "inode_available": "512K",
#         "inode_usedutilization": "1"},
#        {"mount": "/home", "size_total": "3.6T", "size_use": "1.7T", "size_available": "2.0T",
#         "size_usedutilization": "47", "block_total": "3752399M", "block_use": "1754779M",
#         "block_available": "1997621M", "block_usedutilization": "47", "inode_total": "367M", "inode_use": "697K",
#         "inode_available": "366M", "inode_usedutilization": "1"}],
#    "network": {"tcpconnection": {"LISTEN": 26, "ESTABLISHED": 21, "TIME_WAIT": 1}, "conn": "True"},
#    "bad": [],
#    "critical": []
#}


######################################################################################################
# Environmental configuration
######################################################################################################

# export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin


######################################################################################################
# Define globle variable
######################################################################################################

system_facts=''
cpu_facts=''
mem_facts=''
disk_facts=''
network_facts=''

bad=''
critical=''

# 阈值
bad_threshold=80
critical_threshold=90


######################################################################################################
# Define function
######################################################################################################

function check_used() {
  # 依据阀值设置,进行标记严重程度

  item=$1
  value=${2:-0}

  [[ ! "$value" =~ ^|0-9|+$ ]] && return

  if [[ ${value%.*} -ge ${critical_threshold%.*} ]]; then
    critical=${critical}'"'${item}'",'
  elif [[ ${value%.*} -ge ${bad_threshold%.*} ]]; then
    bad=${bad}'"'${item}'",'
  fi

}

function get_system() {
  # 获取系统信息

  hostname=$(hostname 2>/dev/null)
  default_ipv4=$(ip -4 route get 8.8.8.8 2>/dev/null | head -1 | awk '{print $7}')
  distribution=$(awk '/^ID=/' /etc/*-release 2>/dev/null | awk -F'=' '{gsub("\"","");print $2}')
  distribution_version=$(python -c 'import platform; print platform.linux_distribution()[1]' 2>/dev/null)
  [ -z $distribution_version ] && distribution_version=$(awk '/^VERSION_ID=/' /etc/*-release 2>/dev/null | awk -F'=' '{gsub("\"","");print $2}')
  os_pretty_name=$(awk '/^PRETTY_NAME=/' /etc/*-release 2>/dev/null | awk -F'=' '{gsub("\"","");print $2 }')
  kernel=$(uname -r 2>/dev/null)
  os_time=$(date +"%F %T" 2>/dev/null)
  uptime=$(uptime 2>/dev/null | awk '{print $3}' | awk -F, '{print $1}')

  system_facts=$(
    cat <<EOF
  {
    "hostname": "${hostname:-}",
    "default_ipv4": "${default_ipv4:-}",
    "distribution": "${distribution:-}",
    "distribution_version": "${distribution_version:-}",
    "os_pretty_name": "${os_pretty_name:-}",
    "kernel": "${kernel:-}",
    "os_time": "${os_time:-}",
    "uptime": "${uptime:-}"
  }
EOF
  )

}

function get_cpu() {
  # 获取cpu使用信息

  cpu_usedutilization=$(cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | awk -v RS="" '{printf ("%.2f\n", ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5))}')
  cpu_loadavg1=$(awk '{print $1}' /proc/loadavg)
  cpu_loadavg5=$(awk '{print $2}' /proc/loadavg)
  cpu_loadavg15=$(awk '{print $3}' /proc/loadavg)

  cpu_facts=$(
    cat <<EOF
  {
    "cpu_usedutilization": "${cpu_usedutilization:-0}",
    "cpu_loadavg1": "${cpu_loadavg1:-0}",
    "cpu_loadavg5": "${cpu_loadavg5:-0}",
    "cpu_loadavg15": "${cpu_loadavg15:-0}"
  }
EOF
  )

  check_used 'cpu_usedutilization' ${cpu_usedutilization}
  check_used 'cpu_loadavg1' ${cpu_loadavg1}
  check_used 'cpu_loadavg5' ${cpu_loadavg5}
  check_used 'cpu_loadavg15' ${cpu_loadavg15}

}

function get_mem() {
  # 获取内存使用信息

  memfree=$(awk -F":|kB" '$1~/^MemFree/{gsub(/ +/,"",$0);print $2}' /proc/meminfo)
  memavailable=$(awk -F":|kB" '$1~/^MemAvailable/{gsub(/ +/,"",$0);print $2}' /proc/meminfo)
  memtotal=$(awk -F":|kB" '$1~/^MemTotal/{gsub(/ +/,"",$0);print $2}' /proc/meminfo)
  memcache=$(awk -F":|kB" '$1~/^Cached/{gsub(/ +/,"",$0);print $2}' /proc/meminfo)
  membuffer=$(awk -F":|kB" '$1~/^Buffers/{gsub(/ +/,"",$0);print $2}' /proc/meminfo)
  swaptotal=$(awk -F":|kB" '$1~/^SwapTotal/{gsub(/ +/,"",$0);print $2}' /proc/meminfo)
  swapfree=$(awk -F":|kB" '$1~/^SwapFree/{gsub(/ +/,"",$0);print $2}' /proc/meminfo)

  [ "${memtotal:-0}" != "0" ] && mem_usedutilization=$(echo "${memtotal:-0} ${memfree:-0} ${memcache:-0} ${membuffer:-0}" | awk '{printf ("%.2f\n", ($1-$2-$3-$4)*100/$1)}')
  [ "${swaptotal:-0}" != "0" ] && swap_usedutilization=$(echo "${swaptotal:-0} ${swapfree:-0}" | awk '{printf ("%.2f\n", ($1-$2)*100/$1)}')

  mem_facts=$(
    cat <<EOF
  {
    "memtotal": "${memtotal:-}",
    "memfree": "${memfree:-}",
    "memavailable": "${memavailable:-}",
    "memcache": "${memcache:-}",
    "membuffer": "${membuffer:-}",
    "mem_usedutilization": "${mem_usedutilization:-0}",
    "swaptotal": "${swaptotal:-}",
    "swapfree": "${swapfree:-}",
    "swap_usedutilization": "${swap_usedutilization:-0}"
  }
EOF
  )

  check_used 'mem' ${mem_usedutilization}
  check_used 'swap' ${swap_usedutilization}

}

function get_disk() {
  # 获取磁盘使用信息

  mount=$(grep '^/dev/' /proc/mounts | grep -v -E 'docker|containers|iso9660|kubelet' | awk '{print $2}')

  for m in ${mount:-}; do
    size_total=$(df -hP $m 2>/dev/null | awk 'END{print $2}')
    size_use=$(df -hP $m 2>/dev/null | awk 'END{print $3}')
    size_available=$(df -hP $m 2>/dev/null | awk 'END{print $4}')
    size_usedutilization=$(df -hP $m 2>/dev/null | awk 'END{sub(/'%'/,"");print $5}')
    block_total=$(df -hPBM $m 2>/dev/null | awk 'END{print $2}')
    block_use=$(df -hPBM $m 2>/dev/null | awk 'END{print $3}')
    block_available=$(df -hPBM $m 2>/dev/null | awk 'END{print $4}')
    block_usedutilization=$(df -hPBM $m 2>/dev/null | awk 'END{sub(/'%'/,"");print $5}')
    inode_total=$(df -hPi $m 2>/dev/null | awk 'END{print $2}')
    inode_use=$(df -hPi $m 2>/dev/null | awk 'END{print $3}')
    inode_available=$(df -hPi $m 2>/dev/null | awk 'END{print $4}')
    inode_usedutilization=$(df -hPi $m 2>/dev/null | awk 'END{sub(/'%'/,"");print $5}')

    mount_facts=${mount_facts:-''}$(
      cat <<EOF
    {
      "mount": "${m:-}",
      "size_total": "${size_total:-}",
      "size_use": "${size_use:-}",
      "size_available": "${size_available:-}",
      "size_usedutilization": "${size_usedutilization:-0}",
      "block_total": "${block_total:-}",
      "block_use": "${block_use:-}",
      "block_available": "${block_available:-}",
      "block_usedutilization": "${block_usedutilization:-0}",
      "inode_total": "${inode_total:-}",
      "inode_use": "${inode_use:-}",
      "inode_available": "${inode_available:-}",
      "inode_usedutilization": "${inode_usedutilization:-0}"
    },
EOF
    )

    check_used 'mount_size_'${m} ${size_usedutilization}
    check_used 'mount_block_'${m} ${block_usedutilization}
    check_used 'mount_inode_'${m} ${inode_usedutilization}
  done

  disk_facts="["${mount_facts%?}"]"

}

function get_network() {
  # 获取网络信息

  stat=$(netstat -nat 2>/dev/null | awk '/^tcp/{++S[$NF]}END{for(m in S) print "\"" m "\":",S[m] ","}')

  conn="None"
  curl -V >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    curl -sI http://www.baidu.com 2>/dev/null | grep '200 OK' >/dev/null 2>&1
    [ $? -eq 0 ] && conn="True"
  fi
  network_facts=$(
    cat <<EOF
  {
    "tcpconnection": {${stat%?}},
    "conn": "${conn}"
  }
EOF
  )

}

function main() {
  # 脚本主要流程

  get_system
  get_cpu
  get_mem
  get_disk
  get_network

  [ ! -z $bad ] && bad='['${bad%?}']'
  [ ! -z $critical ] && critical='['${critical%?}']'

  check_facts=$(
    cat <<EOF
  {
    "system": ${system_facts:-[]},
    "cpu": ${cpu_facts:-[]},
    "mem": ${mem_facts:-[]},
    "disk": ${disk_facts:-[]},
    "network": ${network_facts:-[]},
    "bad": ${bad:-[]},
    "critical": ${critical:-[]}
  }
EOF
  )

  echo ${check_facts:-[]}

}


######################################################################################################
# main
######################################################################################################

main

