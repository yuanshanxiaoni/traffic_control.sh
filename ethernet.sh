#!/bin/bash - 
#===============================================================================
#
#          FILE:  etherInfo.sh
# 
#         USAGE:  ./etherInfo.sh 
# 
#   DESCRIPTION:  获取系统网卡状态,驱动,型号等信息
# 
#       OPTIONS:  
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  
#        AUTHOR:  bigdog
#       COMPANY:  
#       CREATED:  2011年04月27日 10时44分45秒 CST
#      REVISION:  0.1
#===============================================================================
set -o nounset                              # Treat unset variables as an error


usage () {
    echo -ne "\n\tUsage : \n"
    echo -ne "\n\t\t$0  ether   [status|driver|info]\n"
    echo -ne "\n\t\t\t$0  ethx  s|status\n"
    echo -ne "\n\t\t\t$0  ethx  d|driver\n"
    echo -ne "\n\t\t\t$0  ethx  i|info\n"

    echo -ne "\n\n\t\t\tether :  must be in br0, br1, eth0, eth1, eth2, eth3, eth4\n"
    echo -ne "\n"
}


get_ether_driver () {
    echo -ne "\n\tEther Driver : "

    while read name value; do
        if [ "$name" = 'version:' ] ; then
            echo -ne "$value"
            break;
        else
            echo -ne "$value-"
        fi
    done < <(ethtool -i $1)

    echo -ne "\n\n"
}

get_ether_info () {
    echo -ne "\n\tEther Info : "
    rt=`lspci -m | grep "Ethernet controller" | head -n1 | sed 's/ /-/g' | sed 's/"-"/ /g' | awk '{ print $3}' | sed 's/"/ /g' | awk '{ print $1 }'`
    echo -ne "$rt\n\n"
}

get_ether_status () {
    echo -ne "\n\tEther Status : "
    rt=`ethtool $1 | grep "Link detected:" | awk '{print $3}'`
    echo -ne "$rt\n\n"
}

######################### 
if [ $# -ne 2 ]; then
    usage  ;
    exit 1 ;
fi

ethx=$1
cmd=$2

if [ ${#ethx} -lt 3 -a ${#ethx} -gt 4 -a "${ethx:0:2}" != "br" -a "${ethx:0:3}" != "eth" ]; then
    echo -ne "\n\nethernet must be in eth0, eth1, eth2, eth3 or br0, br1\n\n"
    exit 1;
fi

case $cmd in
    "i" | "info")
        get_ether_info $ethx;
    ;;
    "d" | "driver" )
        get_ether_driver $ethx;
    ;;
    "s" | "status" )
        get_ether_status $ethx;
    ;;
    *)
        usage
        ;;
esac

echo -ne "\nStatus : [OK]\n\n"

exit 0;
