clear

while true
do
  oc argo rollouts get rollout discounts -n travel-agency 
  echo 

  oc get virtualservice discounts -n travel-agency -o json | jq -r '.spec.http[0].route[] | "\(.destination.host): \(.weight)%"' 

  sleep 10
  clear
done