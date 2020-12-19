#!/bin/sh

script_path=${0%/*}

size=1
if grep -q 5M /mnt/custom/CustomConfig/Encode.json; then
	size=5
elif grep -q 3M /mnt/custom/CustomConfig/Encode.json; then
	size=3
elif grep -q 1080P /mnt/custom/CustomConfig/Encode.json; then
	size=2
fi

$script_path/ircut $size
sleep 1
$script_path/ircut $size
sleep 1
$script_path/ircut $size
sleep 1
$script_path/ircut $size
sleep 1
$script_path/ircut $size
sleep 1
