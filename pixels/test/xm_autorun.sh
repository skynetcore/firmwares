#!/bin/sh
FLAGS_DIR="/mnt/mtd/Flags"
SET_MIRROR="initMirrorOn"
SET_FLIP="initFlipOn"
SET_IRCUTREVERSE="initIRCutReverse"
SET_INFRAREDREVERSE="initInfraredReverse"
SET_INFRAREDRECOVER="initInfraredRecover"
SETTED_MIRROR="MirrorOnFlag"
SETTED_FLIP="FlipOnFlag"
SETTED_IRCUTREVERSE="IRCutReverseFlag"
SETTED_INFRAREDREVERSE="InfraredReverseFlag"
SETTED_INFRAREDRECOVER="InfraredRecoverFlag"

propFile="/mnt/mtd/Log/motor"

lsmod | grep xm_wdt && rmmod xm_wdt

script_path=${0%/*}
#script_path=`echo $0 | sed "s/\([^\/]*\)$//"
echo  $script_path > $script_path/test

$script_path/aoen

$script_path/i2s_play $script_path/FactoryTestStart.pcm

killprocess()
{
	ProcName=$1
	ProPid=`ps | awk '$4 ~ "'$ProcName'$" {printf $1" "}'`
	if [ "$ProPid" != "" ]; then
		kill -9 $ProPid
	fi
}

killprocess Sofia
killprocess isp
sleep 2

rm -f /mnt/mtd/Config/WLan /mnt/mtd/Config/wpa.conf /mnt/mtd/Config/hostapd.conf
rm -f /mnt/mtd/Log/SupportLanguage

getconf()
{
	val=`cat $1 | grep ^\\s*$2: | sed -e "s/\\s*$2://g" -e "s/\r//g" -e "s/\n//g" -e "s/$(echo -e '\015')//g"`
	if [ ! $val ]; then
		echo "getconf $2 failed" >> $script_path/test
	fi

	echo -n $val
}

filename=$script_path/function.ini

LANGUAGE=$(getconf $filename language)
echo LANGUAGE = $LANGUAGE >> $script_path/test
WIFISTARTUP=$(getconf $filename wifistartup)
echo STARTUPTYPE = $WIFISTARTUP >> $script_path/test

if [ "$LANGUAGE" = "SimpChinese" ] ||
   [ "$LANGUAGE" = "English" ] ||
   [ "$LANGUAGE" = "Spanish" ] ||
   [ "$LANGUAGE" = "Portugal" ] ||
   [ "$LANGUAGE" = "ChineseEnglish" ]
then
	echo $LANGUAGE > /mnt/mtd/Log/InitialLanguage
	$script_path/i2s_play $script_path/configLanguage$LANGUAGE.pcm
	sleep 1
fi

if [ "$WIFISTARTUP" = "Station" ];then
	echo "StartupType:0" > /mnt/mtd/Log/WifiStartupType
	$script_path/i2s_play $script_path/configWiFiStation.pcm
elif [ "$WIFISTARTUP" = "softAP" ];then
	echo "StartupType:1" > /mnt/mtd/Log/WifiStartupType
	$script_path/i2s_play $script_path/configWiFisoftAP.pcm
	sleep 1
fi

rm -f $propFile
MOTOR_FLIP=$(getconf $filename motor_flip)
if [ "$MOTOR_FLIP" = "yes" ] ||
	[ "$MOTOR_FLIP" = "no" ]
then
	echo "motor_flip:$MOTOR_FLIP" >> $propFile
fi

MOTOR_MIRROR=$(getconf $filename motor_mirror)
if [ "$MOTOR_MIRROR" = "yes" ] ||
	[ "$MOTOR_MIRROR" = "no" ]
then
	echo "motor_mirror:$MOTOR_MIRROR" >> $propFile
fi

[ -e "/mnt/mtd/Log/trackset" ] && rm /mnt/mtd/Log/trackset
TRACK_MODULE_OPEN=$(getconf $filename track_module_open)
if [ "$TRACK_MODULE_OPEN" = "yes" ]; then
	touch /mnt/mtd/Log/trackset

	TRACK_MOTOR_LEFT=$(getconf $filename track_motor_left)
	if [ "$TRACK_MOTOR_LEFT" = "left" ] ||
		[ "$TRACK_MOTOR_LEFT" = "right" ]
	then
		echo "motor_left:$TRACK_MOTOR_LEFT" >> /mnt/mtd/Log/trackset
	fi

	TRACK_MOTOR_RIGHT=$(getconf $filename track_motor_up)
	if [ "$TRACK_MOTOR_RIGHT" = "up" ] ||
		[ "$TRACK_MOTOR_RIGHT" = "down" ]
	then
		echo "motor_up:$TRACK_MOTOR_RIGHT" >> /mnt/mtd/Log/trackset
	fi

	TRACK_WIDTH_STEPS=$(getconf $filename track_width_steps)
	TRACK_HEIGHT_STEPS=$(getconf $filename track_height_steps)
	TRACK_DEFAULT_DEGREES_Y=$(getconf $filename track_default_degrees_y)
	echo "width_steps:$TRACK_WIDTH_STEPS" >> /mnt/mtd/Log/trackset
	echo "height_steps:$TRACK_HEIGHT_STEPS" >> /mnt/mtd/Log/trackset
	echo "vertical_degrees:$TRACK_DEFAULT_DEGREES_Y" >> /mnt/mtd/Log/trackset
fi

MOTOR_PRESET=$(getconf $filename MOTOR_PRESET)
if [ "$MOTOR_PRESET" = "yes" ]; then
	MAX_DEGREE_X=$(getconf $filename MAX_DEGREE_X)
	MAX_DEGREE_Y=$(getconf $filename MAX_DEGREE_Y)
	MID_DEGREE_Y=$(getconf $filename MID_DEGREE_Y)
	if [ "$MAX_DEGREE_X" -le "360" ] && [ "$MAX_DEGREE_Y" -le "360" ]; then
		echo -n "auto_test=1 MAX_DEGREE_X=$MAX_DEGREE_X MAX_DEGREE_Y=$MAX_DEGREE_Y" > /mnt/mtd/Log/motorset
		echo "max_degree_x:$MAX_DEGREE_X" >> $propFile
		echo "max_degree_y:$MAX_DEGREE_Y" >> $propFile
		echo "valid MAX_DEGREE_X=$MAX_DEGREE_X MAX_DEGREE_Y=$MAX_DEGREE_Y" >> $script_path/test
		if [ ! $MID_DEGREE_Y ]; then
			echo "Not config MID_DEGREE_Y." >> $script_path/test
		else
			if [ "$MID_DEGREE_Y" -le "$MAX_DEGREE_Y" ]; then
				echo "mid_degree_y:$MID_DEGREE_Y" >> $propFile
				echo "valid MID_DEGREE_Y=$MID_DEGREE_Y" >> $script_path/test
			else
				echo "invalid MAX_DEGREE_X=$MAX_DEGREE_X MAX_DEGREE_Y=$MAX_DEGREE_Y MID_DEGREE_Y=$MID_DEGREE_Y" >> $script_path/test
				$script_path/i2s_play $script_path/configMaxDegreeERROR.pcm
			fi
		fi
	else
		echo "invalid MAX_DEGREE_X=$MAX_DEGREE_X MAX_DEGREE_Y=$MAX_DEGREE_Y" >> $script_path/test
		$script_path/i2s_play $script_path/configMaxDegreeERROR.pcm
	fi
else
	[ -e "/mnt/mtd/Log/motorset" ] && rm /mnt/mtd/Log/motorset
fi

setflag()
{
	if [ "$1" = "yes" ]; then
		[ -e "$2" ] || touch $2
	else
		[ -e "$2" ] && rm $2
	fi
}

if [ -f $FLAGS_DIR/$SETTED_MIRROR ]; then
	rm -f $FLAGS_DIR/$SETTED_MIRROR
fi
if [ -f $FLAGS_DIR/$SET_MIRROR ];then
	rm -f $FLAGS_DIR/$SET_MIRROR
fi
if [ -f $FLAGS_DIR/$SETTED_FLIP ];then
	rm -f $FLAGS_DIR/$SETTED_FLIP
fi
if [ -f $FLAGS_DIR/$SET_FLIP ];then
	rm -f $FLAGS_DIR/$SET_FLIP
fi
if [ -f $FLAGS_DIR/$SETTED_IRCUTREVERSE ];then
	rm -f $FLAGS_DIR/$SETTED_IRCUTREVERSE
fi
if [ -f $FLAGS_DIR/$SET_IRCUTREVERSE ];then
	rm -f $FLAGS_DIR/$SET_IRCUTREVERSE
fi

[ -d "/mnt/mtd/Flags" ] || mkdir /mnt/mtd/Flags
IRCUT_REVERSE=$(getconf $filename IRCutReverse)
setflag $IRCUT_REVERSE /mnt/mtd/Flags/initIRCutReverse
VIDEO_MIRROR=$(getconf $filename video_mirror)
setflag $VIDEO_MIRROR /mnt/mtd/Flags/initMirrorOn
VIDEO_FLIP=$(getconf $filename video_flip)
setflag $VIDEO_FLIP /mnt/mtd/Flags/initFlipOn
INFRARED_REVERSE=$(getconf $filename InfraredReverse)
if [ "$INFRARED_REVERSE" = "yes" ] ||
	[ "$INFRARED_REVERSE" = "no" ]
then
	if [ "$INFRARED_REVERSE" = "yes" ]; then
		if [ -f $FLAGS_DIR/$SET_INFRAREDRECOVER ];then
			rm -f $FLAGS_DIR/$SET_INFRAREDRECOVER
		fi
		if [ -f $FLAGS_DIR/$SETTED_INFRAREDRECOVER ];then
			rm -f $FLAGS_DIR/$SETTED_INFRAREDRECOVER
		fi
		setflag $INFRARED_REVERSE /mnt/mtd/Flags/initInfraredReverse
	else
		if [ -f $FLAGS_DIR/$SET_INFRAREDREVERSE ];then
			rm -f $FLAGS_DIR/$SET_INFRAREDREVERSE
		fi
		if [ -f $FLAGS_DIR/$SETTED_INFRAREDREVERSE ];then
			rm -f $FLAGS_DIR/$SETTED_INFRAREDREVERSE
		fi
		if [ -f $FLAGS_DIR/$SETTED_INFRAREDRECOVER ];then
			rm -f $FLAGS_DIR/$SETTED_INFRAREDRECOVER
		fi
		setflag yes /mnt/mtd/Flags/initInfraredRecover
	fi
fi

DOUBLE_LIGHT_CONFIG=$(getconf $filename DoubleLightCamera)
if [ "$DOUBLE_LIGHT_CONFIG" = "yes" ] ||
	[ "$DOUBLE_LIGHT_CONFIG" = "no" ]
then
	setflag $DOUBLE_LIGHT_CONFIG /mnt/mtd/Flags/DoubleLightCameraFlag
fi

MOTOR=$(getconf $filename motor)
IRCUT=$(getconf $filename ircut)
AUDIO=$(getconf $filename audio)
WIFI=$(getconf $filename wifi)
LED=$(getconf $filename led)

if [ "$LED" = "yes" ];then
	echo LED begin >> $script_path/test
	echo LED begin
	$script_path/led/led.sh
fi
if [ "$MOTOR" = "yes" ];then
	echo MOTOR begin >> $script_path/test
	echo MOTOR begin
	$script_path/motor/motor.sh
fi
if [ "$IRCUT" = "yes" ];then
	echo IRCUT begin >> $script_path/test
	echo IRCUT begin
	$script_path/ircut/ircut.sh
fi
if [ "$AUDIO" = "yes" ];then
	echo AUDIO begin >> $script_path/test
	echo AUDIO begin
	$script_path/audio/audio.sh
fi
if [ "$WIFI" = "yes" ];then
	echo WIFI begin >> $script_path/test
	echo WIFI begin
	$script_path/wifi/wifi.sh
else
	$script_path/i2s_play $script_path/FactoryTestFinished.pcm
fi

echo "FINISHED" >> $script_path/test
sync

exit 0