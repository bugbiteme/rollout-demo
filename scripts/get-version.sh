oc get rollout discounts -n travel-agency -o yaml | kubectl neat | yq | grep demo_travels_discounts 
    