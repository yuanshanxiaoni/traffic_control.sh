#!/bin/bash - 
#===============================================================================
#
#          FILE:  main.sh
# 
#         USAGE:  ./main.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: bigdog 
#       COMPANY: 
#       CREATED: 2011年04月27日 16时15分03秒 CST
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error

etherconf="./br.config"
tcconfig="./tc.config"

while read brname  inner  outer  status ; do
    echo "br = $brname"
    echo "inner = $inner"
    echo "outer = $outer"
    echo "status= $status"
done < <(cat $etherconf  | tail -n1)

# download --> inner 
# upload   --> outer

policy_num=`cat $tcconfig | wc -l `

echo "num = $policy_num"

while read up down mark ; do
    echo -ne "up = $up, down = $down, mark = $mark\n"
done < <(cat $tcconfig )

#######################################################################################################
## rate    : 限制的传输速率 用位来计算
## latency : 确定了一个包在TBF中等待传输的最长等待时间
## burst   : 桶的大小,以字节计.指定了最多可以有多少个令牌能够即刻被使用
##           注:管理的带宽越大,需要的缓冲器就越大.在Intel体系上,10兆bit/s的速率需要至少10k字节的缓冲区
#######################################################################################################

start_tc_up () {
    # delete the old tc queue ;
    tc qdisc del dev $dev_up root >/dev/null 2>&1
    # add root
    tc qdisc add dev $dev_up root handle 1: htb r2q 1

    tc class add dev $dev_up parent 1: classid 1:$num htb rate ${UP1}kbit ceil ${UP1}kbit burst 15k prio $num
    tc class add dev $dev_up parent 1: classid 1:$num htb rate ${UP2}kbit ceil ${UP2}kbit burst 15k prio $num
    tc class add dev $dev_up parent 1: classid 1:$num htb rate ${UP3}kbit ceil ${UP3}kbit burst 15k prio $num

    tc qdisc add dev $dev_up parent 1:$num handle ${num}0: sfq perturb 10
    tc qdisc add dev $dev_up parent 1:$num handle ${num}0: sfq perturb 10
    tc qdisc add dev $dev_up parent 1:$num handle ${num}0: sfq perturb 10

    tc filter add dev eth0 parent 1: protocol ip prio $mark handle $mark fw flowid 1:1
    tc filter add dev eth0 parent 1: protocol ip prio $mark handle $mark fw flowid 1:2
    tc filter add dev eth0 parent 1: protocol ip prio $mark handle $mark fw flowid 1:3
}

start_tc_down () {
    tc qdisc del dev $dev_down root >/dev/null 2>&1
}
stop_tc ()  {
    exit 
}

