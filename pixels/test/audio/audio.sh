#!/bin/sh

script_path=${0%/*}

if [ -e $script_path/audiotest.pcm ];then
	rm $script_path/audiotest.pcm
fi

touch $script_path/audiotest.pcm
$script_path/i2s_play $script_path/start.pcm
$script_path/i2s_record $script_path/audiotest.pcm 5
$script_path/i2s_play $script_path/audiotest.pcm

exit 0