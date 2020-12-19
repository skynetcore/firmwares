#!/bin/sh

script_path=${0%/*}

$script_path/led 0 2
sleep 2
$script_path/led 0 2
sleep 2
$script_path/led 1 2
sleep 2
$script_path/led 1 2

exit 0