#!/bin/sh

script_path=${0%/*}
echo  $script_path > $script_path/test

getconf()
{
	val=`cat $1 | grep $2: | sed -e "s/$2://g" -e "s/\r//g" -e "s/\n//g" -e "s/$(echo -e '\015')//g"`
	if [ -z "$val" ]; then
		echo "getconf $2 failed" >> $script_path/test
		$script_path/i2s_play $script_path/getconffail.pcm
		exit 1
	fi

	echo -n $val
}

killprocess()
{
	ProcName=$1
	ProPid=`ps | awk '$4 ~ "'$ProcName'$" {printf $1" "}'`
	if [ "$ProPid" != "" ]; then
		kill -9 $ProPid
	fi
}

kill_wait()
{
	ProcName=$1
	ProPid=`ps | awk '$4 ~ "'$ProcName'$" {printf $1" "}'`
	while [ -z "$ProPid" ]
	do
		ProPid=`ps | awk '$4 ~ "'$ProcName'$" {printf $1" "}'`
		sleep 1
	done
	kill $ProPid
}

kill_wait wlandaemon
killprocess wpa_supplicant
killprocess udhcpc
killprocess hostapd
killprocess udhcpd

filename=$script_path/wifiSetup.ini
SSID=$(getconf $filename SSID)
echo SSID=$SSID >> $script_path/test
PASSWORD=$(getconf $filename PASSWORD)
#echo PASSWORD=$PASSWORD
CHANNEL=$(getconf $filename CHANNEL)
#echo CHANNEL=$CHANNEL
IP=$(getconf $filename IP)
#echo IP=$IP
WG=$(getconf $filename WG)
#echo WG=$WG
NETMASK=$(getconf $filename NETMASK)
#echo NETMASK=$NETMASK

sleep 1
ifconfig eth2 up
sleep 1

rssi=`iw dev eth2 scan | grep -B 5 "SSID: $SSID" | grep "signal: "`
echo $rssi >> $script_path/test
rssi=${rssi#*: -}
rssi=${rssi:0:2}

echo rssi=$rssi >> $script_path/test
if [ -z "$rssi" ]; then
	$script_path/i2s_play $script_path/errorWiFi.pcm
elif [ $rssi -le 47 ]; then
	echo "strong WiFi" >> $script_path/test
	$script_path/i2s_play $script_path/strongWiFi.pcm
elif [ $rssi -le 52 ]; then
	echo "medium WiFi" >> $script_path/test
	$script_path/i2s_play $script_path/mediumWiFi.pcm
else
	echo "weak WiFi" >> $script_path/test
	$script_path/i2s_play $script_path/weakWiFi.pcm
fi 2>>$script_path/error

cp -f $script_path/wpa_wpa2.conf /var/tmp/wpa.conf
echo ssid=$SSID >> $script_path/test
echo psk=$PASSWORD >> $script_path/test
sed "s/ssid=.*$/ssid=\"$SSID\"/g" -i /var/tmp/wpa.conf
sed "s/psk=.*$/psk=\"$PASSWORD\"/g" -i /var/tmp/wpa.conf
cp -f /var/tmp/wpa.conf $script_path/wpa.conf

ifconfig eth2 down
ifconfig eth2 up
 
netinit eth2 $IP $NETMASK $WG  
echo $IP $WG $NETMASK  >> $script_path/test

$script_path/i2s_play $script_path/connecting.pcm
wpa_supplicant -ieth2 -Dnl80211 -c /var/tmp/wpa.conf >/dev/null 2>&1 &
sleep 1
#isp &

i=0
while [ "$i" -lt "60" ]
do
	#ping -c3 $WG
	wlanstate=`cat /var/tmp/wpa_state`
	echo $wlanstate
	if [ "$wlanstate" = "9" ]; then
		break
	fi
	let i++
	sleep 1
done

if [ "$i" -ge "60" ]; then
	echo "connect fail!" >> $script_path/test
	$script_path/i2s_play $script_path/connectfail.pcm
	exit 3
fi

for com_ip in `cat $script_path/computerip.txt`
do
	ping $com_ip &
done

echo "connect succeed" >> $script_path/test
$script_path/i2s_play $script_path/connected.pcm
echo -e -n "\03\0\0\0" > /var/tmp/wlanstate &

#insmod /usr/lib/modules/xm_wdt.ko
isp &
sleep 5
Sofia &

exit 0
