#!/bin/bash - 
#===============================================================================
#
#          FILE:  tc.sh
# 
#         USAGE:  ./tc.sh  start|stop
# 
#   DESCRIPTION:  下tc策略, 包括上行,下行限速
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  bigdog
#       COMPANY:  
#       CREATED:  2011年04月28日 15时38分42秒 CST
#      REVISION:  0.1
#===============================================================================
set -o nounset                              # Treat unset variables as an error

# tc规则文件
tc_conf="./tc.config"

# 外网网口,控制上传
dev_up=eth0 
# 内网网口,控制下载
dev_down=eth1


# args : dev
init_dev () { 
    # delete the old tc queue ;
    tc qdisc del dev $1 root >/dev/null 2>&1
    # add root
    tc qdisc add dev $1 root handle 1: htb r2q 1
    if [ $? -ne 0 ]; then
        echo -ne "tc add dev root Error !\n"
        return 1;
    fi
}

# args : dev
delete_dev () {
    # delete the old tc queue ;
    tc qdisc del dev $1 root >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -ne "tc del dev [$1] root Error !\n"
        return 1;
    fi
    return 0;
}

stop_up () {
    delete_dev $dev_up ;
    if [ $? -ne 0 ]; then
        echo -ne "\nError\n"
        return 1;
    fi
    return 0;
}

stop_down () { 
    delete_dev $dev_down ;
    if [ $? -ne 0 ]; then
        echo -ne "\nError\n"
        return 1;
    fi
    return 0;
}

# args : dev  classID  Rate  Mark
add_policy () {
    tc class add dev ${1} parent 1: classid 1:${2} htb rate ${3}kbit ceil ${3}kbit burst 15k prio ${2}
    if [ $? -ne 0 ]; then
        echo -ne "add tc class return Error\n"
    fi
    tc qdisc add dev ${1} parent 1:${2} handle ${2}0: sfq perturb 10
    if [ $? -ne 0 ]; then
        echo --ne "add tc qdisc sfq return Error\n"
    fi
    tc filter add dev ${1} parent 1: protocol ip prio ${2} handle ${4} fw flowid 1:${2}
    if [ $? -ne 0 ]; then
        echo -ne "add tc filter return Error\n"
    fi
}


start_up () {
    init_dev $dev_up ;
    num=1
    while read line ; do
        rate=`echo $line | awk '{ print $1}'`
        mark=`echo $line | awk '{ print $3}'`

        add_policy $dev_up $num $rate $mark ;
        num=`expr $num + 1`
    done < <(cat $tc_conf )

    return ;
}

start_down () {
    init_dev $dev_down ;
    num=1
    while read line ; do
        rate=`echo $line | awk '{ print $2}'`
        mark=`echo $line | awk '{ print $3}'`

        add_policy $dev_down $num $rate $mark ;
        num=`expr $num + 1`
    done < <(cat $tc_conf )

    return 0;
}

get_status () {
# uplink
    echo 
    echo -ne "=================================================================================\n"
    echo -ne "uplink :\n"
    echo -ne "=================================================================================\n"
    echo -ne "+++ Qdisc :\n"
    echo -ne "+++------------------------------------------------------------------------------\n"
    tc -s qdisc show dev $dev_up
    echo -ne "+++------------------------------------------------------------------------------\n\n"
    echo -ne "++++++ Class :\n"
    echo -ne "++++++---------------------------------------------------------------------------\n"
    tc -s class show dev $dev_up
    echo -ne "++++++---------------------------------------------------------------------------\n\n"

    # downlink
    echo 
    echo -ne "=================================================================================\n"
    echo -ne "downlink :\n"
    echo -ne "=================================================================================\n"
    echo -ne "+++ Qdisc :\n"
    echo -ne "+++------------------------------------------------------------------------------\n"
    tc -s qdisc show dev $dev_down
    echo -ne "+++------------------------------------------------------------------------------\n\n"
    echo -ne "++++++ Class :\n"
    echo -ne "++++++---------------------------------------------------------------------------\n"
    tc -s class show dev $dev_down
    echo -ne "++++++---------------------------------------------------------------------------\n\n"
}


usage () {
    echo 
    echo -ne "  Usage : \n\n"
    echo -ne "\t`basename $0`   [start|stop|restart|status]\n\n"
    echo 
}


##########################################################
## start here
##########################################################
if [ $# -ne 1 ]; then
    usage  ;
    exit 1 ;
fi

action=$1
case $action in
    "start" )
        start_up   ;
        start_down ;
    ;;
    "stop")
        stop_up    ;
        stop_down  ;
    ;;
    "restart")
        stop_up    ;
        stop_down  ;
        start_up   ;
        start_down ;
    ;;
    "status")
        get_status ;
    ;;
    *)
        usage  ;
        exit 1 ;
    ;;
esac

echo -ne "\nStatus : [OK]\n\n"

exit 0
