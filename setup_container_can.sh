#!/bin/sh

# ref: https://www.lagerdata.com/articles/forwarding-can-bus-traffic-to-a-docker-container-using-vxcan-on-raspberry-pi

set -e

# obtain the container pid
CONTNAME=$1
CONTPID=$(kanto-cm -n $CONTNAME get | jq " .state.pid") 

# setup to virtual linked cans vxcan0 and vxcan1
ip link add vxcan0 type vxcan peer name vxcan1

# send vxcan1 to the container namespace
ip link set vxcan1 netns $CONTPID
ip link set vxcan0 up
nsenter -t $CONTPID -n ip link set vxcan1 up

# setup physical-to-virtual-can routing
modprobe can-gw
sudo cangw -A -s can0 -d vxcan0 -e
sudo cangw -A -s vxcan0 -d can0 -e
