#!/bin/bash

NS=travel-agency

# ANSI color codes
BGreen='\033[1;32m'  # Bright Green
BYellow='\033[1;33m' # Bright Yellow
NC='\033[0m'          # No Color

POD_V1=$(oc get pod -n $NS -l app=discounts,version=v1 -o jsonpath='{.items[0].metadata.name}')
POD_V2=$(oc get pod -n $NS -l app=discounts,version=v2 -o jsonpath='{.items[0].metadata.name}')

echo -e "Tailing logs from:"
echo -e "- ${BGreen}$POD_V1 (v1)${NC}"
echo -e "- ${BYellow}$POD_V2 (v2)${NC}"
echo ""

# Function to tail and color logs
tail_logs() {
  local pod=$1
  local version=$2
  local color=$3
  oc logs -n $NS -f "$pod" | awk -v prefix="[$version] " -v color="$color" -v reset="$NC" '{print color prefix $0 reset}'
}

# Trap Ctrl+C to kill entire process group
trap "echo -e '${NC}\nStopping log tails...'; kill -- -$$" SIGINT

# Start tails in background, in the same process group
tail_logs "$POD_V1" "v1" "$BGreen" &
tail_logs "$POD_V2" "v2" "$BYellow" &

# Wait for all child processes
wait