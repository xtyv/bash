#!/bin/bash

rt_tab='/etc/iproute2/rt_tables'
rc_local='/etc/rc.local'
cat>$rt_tab<<EOF
#
# reserved values
#
255	local
254	main
253	default
0	unspec
EOF


cat>$rc_local<<EOF
#!/bin/bash
# THIS FILE IS ADDED FOR COMPATIBILITY PURPOSES
#
# It is highly advisable to create own systemd services or udev rules
# to run scripts during boot instead of using this file.
#
# In contrast to previous versions due to parallel execution during boot
# this script will NOT be run after all other services.
#
# Please note that you must run 'chmod +x /etc/rc.d/rc.local' to ensure
# that this script will be executed during boot.

sleep 5

EOF

rt_n=0
total_network=`ip addr | grep 'inet ' | grep -v ' lo' | wc -l`
ip addr | grep 'inet ' | grep -v ' lo' | awk '{print $2, $NF}' | while read line
do
    rt_rec=$(( 251 - $rt_n ))'\trt'$(( $total_network - $rt_n - 1 ))
    echo -e $rt_rec >> $rt_tab
    arr=($line)
    echo 'ip route flush table 'rt$rt_n >> $rc_local
    echo 'ip route add default via '${arr[0]%.*}'.1 dev '${arr[1]}' table rt'$rt_n >> $rc_local
    echo 'ip route add '${arr[0]%.*}'.0/'${arr[0]#*/}' dev '${arr[1]}' table rt'$rt_n >> $rc_local
    echo 'ip rule add from '${arr[0]%/*}' table rt'$rt_n >> $rc_local
    echo '' >> $rc_local
    let rt_n++
done

cat>>$rt_tab<<EOF
#
# local
#
#1	inr.ruhep
EOF

echo 'touch /var/lock/subsys/local'  >> $rc_local
chmod +x /etc/rc.d/rc.local
/bin/bash $rc_local
