#!/bin/bash

NS=travel-agency

# ANSI color codes
BGreen='\033[1;32m'
BYellow='\033[1;33m'
NC='\033[0m'

# Get ReplicaSets for 'discounts' sorted by creationTimestamp (oldest first)
RS_LIST=($(oc get rs -n $NS -l app=discounts -o=jsonpath='{range .items[*]}{.metadata.creationTimestamp}{"|"}{.metadata.name}{"\n"}{end}' | sort | cut -d"|" -f2))

if [ "${#RS_LIST[@]}" -lt 2 ]; then
  echo "❌ Not enough ReplicaSets to distinguish between stable and canary."
  exit 1
fi

RS_V1="${RS_LIST[0]}"
RS_V2="${RS_LIST[1]}"

# Get all pods for each ReplicaSet
PODS_V1=($(oc get pods -n $NS -l app=discounts -o=jsonpath="{.items[?(@.metadata.ownerReferences[0].name=='$RS_V1')].metadata.name}"))
PODS_V2=($(oc get pods -n $NS -l app=discounts -o=jsonpath="{.items[?(@.metadata.ownerReferences[0].name=='$RS_V2')].metadata.name}"))

if [[ "${#PODS_V1[@]}" -eq 0 || "${#PODS_V2[@]}" -eq 0 ]]; then
  echo "❌ Could not find pods for both ReplicaSets."
  exit 1
fi

echo -e "Tailing logs from:"
for pod in "${PODS_V1[@]}"; do
  echo -e "- ${BGreen}$pod (stable)${NC}"
done
for pod in "${PODS_V2[@]}"; do
  echo -e "- ${BYellow}$pod (canary)${NC}"
done
echo ""

# Function to tail logs from a pod with a label prefix
tail_logs() {
  local pod=$1
  local label=$2
  local color=$3
  oc logs -n $NS -f "$pod" | awk -v prefix="[$label:$pod] " -v color="$color" -v reset="$NC" '{print color prefix $0 reset}'
}

trap "echo -e '${NC}\nStopping log tails...'; kill -- -$$" SIGINT

# Tail all stable pods
for pod in "${PODS_V1[@]}"; do
  tail_logs "$pod" "stable" "$BGreen" &
done

# Tail all canary pods
for pod in "${PODS_V2[@]}"; do
  tail_logs "$pod" "canary" "$BYellow" &
done

wait
