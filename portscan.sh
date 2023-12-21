#!/bin/bash

# Usage: ./script.sh <CIDR>

CIDR=$1

# Convert CIDR to an IP range
cidr_to_ip_range() {
    local cidr=$1
    local ip mask a b c d
    IFS=/ read ip mask <<< "$cidr"

    IFS=. read -r a b c d <<< "$ip"
    local ip_int=$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))
    local mask=$(( 32 - mask ))
    local range_size=$(( 1 << mask ))
    local range_start=$(( ip_int & (0xFFFFFFFF << mask) ))
    local range_end=$(( range_start + range_size - 1 ))

    echo $range_start $range_end
}

# Convert integer to IP
int_to_ip() {
    local ip_int=$1
    echo "$((ip_int >> 24 & 255)).$((ip_int >> 16 & 255)).$((ip_int >> 8 & 255)).$((ip_int & 255))"
}

# Scan ports of a given IP
scan_ports() {
    local ip=$1
    echo "Scanning on IP: $ip"
    for port in $(seq 1 1024); do
        # Try TCP connection with a timeout of 1 second
        timeout 1 bash -c "echo > /dev/tcp/$ip/$port" 2>/dev/null && (
            echo "Port $port is open on $ip"
        ) &
    done
    wait
    echo "Scanning completed on IP: $ip."
}

# Main scanning loop
read range_start range_end <<< $(cidr_to_ip_range $CIDR)
for ip_int in $(seq $range_start $range_end); do
    scan_ports $(int_to_ip $ip_int)
done

echo "All scans are complete."
