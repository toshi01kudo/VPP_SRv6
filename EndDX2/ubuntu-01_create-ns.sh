#!/bin/bash

if [ $USER != "root" ] ; then
    echo "Restarting script with sudo..."
    sudo $0 ${*}
    exit
fi

# delete previous incarnations if they exist
ip link del dev veth_RT1
ip netns del RT1

# Create namespace
ip netns add RT1
# Create link (cable)
ip link add name veth_RT1 type veth peer name RT1
# Connect the links (cables)
ip link set dev veth_RT1 up netns RT1
ip link set dev RT1 up
# Assign IP address
ip netns exec RT1 ip addr add 172.24.60.105/24 dev veth_RT1
# Open loopback
ip netns exec RT1 ip link set lo up
