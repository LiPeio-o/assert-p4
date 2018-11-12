#!/bin/bash
for idx in 0 1 2 3; do
    intf="veth$(($idx*2))"
    if ip link show $intf &> /dev/null; then
        ip link delete $intf type veth
    fi
done