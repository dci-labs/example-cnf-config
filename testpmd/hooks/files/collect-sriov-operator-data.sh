#!/bin/bash 

NAMESPACE=openshift-sriov-network-operator

echo "=== Overview ===" 

{{ oc_tool_path }} get pods -n $NAMESPACE
{{ oc_tool_path }} get deployments -n $NAMESPACE
{{ oc_tool_path }} get replicasets -n $NAMESPACE
{{ oc_tool_path }} get daemonsets -n $NAMESPACE

{{ oc_tool_path }} get csv -n $NAMESPACE
{{ oc_tool_path }} get operatorgroup -n $NAMESPACE

{{ oc_tool_path }} get SriovOperatorConfig -n $NAMESPACE
{{ oc_tool_path }} get SriovNetwork -n $NAMESPACE
{{ oc_tool_path }} get SriovNetworkNodeState -n $NAMESPACE
{{ oc_tool_path }} get SriovNetworkNodePolicy -n $NAMESPACE

echo "=== -o yaml ==="

{{ oc_tool_path }} get -o yaml pods -n $NAMESPACE
{{ oc_tool_path }} get -o yaml deployments -n $NAMESPACE
{{ oc_tool_path }} get -o yaml replicasets -n $NAMESPACE
{{ oc_tool_path }} get -o yaml daemonsets -n $NAMESPACE

{{ oc_tool_path }} get -o yaml csv -n $NAMESPACE
{{ oc_tool_path }} get -o yaml operatorgroup -n $NAMESPACE

{{ oc_tool_path }} get -o yaml SriovOperatorConfig -n $NAMESPACE
{{ oc_tool_path }} get -o yaml SriovNetwork -n $NAMESPACE
{{ oc_tool_path }} get -o yaml SriovNetworkNodeState -n $NAMESPACE
{{ oc_tool_path }} get -o yaml SriovNetworkNodePolicy -n $NAMESPACE

echo "=== describe ==="

{{ oc_tool_path }} describe pods -n $NAMESPACE
{{ oc_tool_path }} describe deployments -n $NAMESPACE
{{ oc_tool_path }} describe replicasets -n $NAMESPACE
{{ oc_tool_path }} describe daemonsets -n $NAMESPACE

{{ oc_tool_path }} describe csv -n $NAMESPACE
{{ oc_tool_path }} describe operatorgroup -n $NAMESPACE

{{ oc_tool_path }} describe SriovOperatorConfig -n $NAMESPACE
{{ oc_tool_path }} describe SriovNetwork -n $NAMESPACE
{{ oc_tool_path }} describe SriovNetworkNodeState -n $NAMESPACE
{{ oc_tool_path }} describe SriovNetworkNodePolicy -n $NAMESPACE

echo "=== Collecting node info ==="
{{ oc_tool_path }} get nodes -o yaml

echo "=== Collecting logs ==="
for pod in $({{ oc_tool_path }} get pods -n $NAMESPACE -o name); do 
  echo "+++ logs for pod $pod +++"
  {{ oc_tool_path }} logs -n $NAMESPACE $pod
done

EOF
