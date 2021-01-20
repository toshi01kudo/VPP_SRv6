#!/bin/bash

if [ $USER != "root" ] ; then
    echo "Restarting script with sudo..."
    sudo $0 ${*}
    exit
fi

# delete previous incarnations if they exist
ip link del dev veth_RT2
ip netns del RT2

# Create namespace
ip netns add RT2
# Create link (cable)
ip link add veth_RT2 type veth peer name RT2
# Connect the links (cables)
ip link set dev veth_RT2 up netns RT2
ip link set dev RT2 up
# Assign IP address
ip netns exec RT2 ip addr add 172.24.60.110/24 dev veth_RT2
# Open loopback
ip netns exec RT2 ip link set lo up
