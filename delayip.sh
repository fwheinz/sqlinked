#!/bin/sh

if [ "X$2X" = "XX" ]; then
   echo "Usage: ./delayip <ms> <ip>"
   echo "   Delays all network traffic to <ip> by <ms> milliseconds"
   echo
   exit 1;
fi;

tc qdisc del dev ens18 root 
tc qdisc add dev ens18 root handle 1: prio
tc qdisc add dev ens18 parent 1:3 handle 30: netem delay $1ms
tc filter add dev ens18 protocol ip parent 1:0 prio 3 u32 match ip dst $2 flowid 1:3
