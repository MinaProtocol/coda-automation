#!/bin/bash

# intentionally only allow coda communications on from a subset of hosts

# Clear
iptables -F INPUT
iptables -F OUTPUT

# Allow list
iplist="127.0.0.1 13.57.185.74 34.219.205.93 52.41.245.81 52.40.10.84 100.26.146.129"
for ip in ${iplist}
do
    # Whitelist
    echo "${ip}"
    iptables -A INPUT  -p tcp -s "${ip}" --match multiport --dports 8301:8303 -j ACCEPT
    iptables -A INPUT  -p udp -s "${ip}" --match multiport --dports 8301:8303 -j ACCEPT
    iptables -A OUTPUT -p tcp -d "${ip}" --match multiport --dports 8301:8303 -j ACCEPT
    iptables -A OUTPUT -p udp -d "${ip}" --match multiport --dports 8301:8303 -j ACCEPT
done

# Drop any others
iptables -A INPUT  -p tcp --match multiport --dports 8301:8303 -j DROP
iptables -A INPUT  -p udp --match multiport --dports 8301:8303 -j DROP
iptables -A OUTPUT -p tcp --match multiport --dports 8301:8303 -j DROP
iptables -A OUTPUT -p udp --match multiport --dports 8301:8303 -j DROP
