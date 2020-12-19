#!/bin/sh

echo "start"

if [ -e /home/mac ];then
    a=`ifconfig eth0|grep eth0|awk '{print $5}'`
    b=`cat /home/mac|sed 'y/abcdef/ABCDEF/'`

    if [ "$a" = "$b" ];then
    	if [ -e /home/upgraded ];then
    		c=`cat /home/upgraded`
    	else
    		c=""
    	fi

    	if [ "$b" != "$c" ];then
        	echo "upgrade successfully!"
        	/home/i2s_play /home/shengjichenggong.pcm
        	echo $b > /home/upgraded
        fi
    fi
fi

if [ -e /home/test/xm_autorun.sh ];then
    echo "run /home/test/xm_autorun.sh"
	/home/test/xm_autorun.sh &
else
	echo "/home/test/xm_autorun.sh not exist"
fi

exit 0
