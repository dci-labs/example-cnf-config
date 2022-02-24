#!/bin/bash 

NAMESPACE=openshift-sriov-network-operator

echo "=== Overview ===" 

{{ app_agent_dir.path }}/oc get pods -n $NAMESPACE
{{ app_agent_dir.path }}/oc get deployments -n $NAMESPACE
{{ app_agent_dir.path }}/oc get replicasets -n $NAMESPACE
{{ app_agent_dir.path }}/oc get daemonsets -n $NAMESPACE

{{ app_agent_dir.path }}/oc get csv -n $NAMESPACE
{{ app_agent_dir.path }}/oc get operatorgroup -n $NAMESPACE

{{ app_agent_dir.path }}/oc get SriovOperatorConfig -n $NAMESPACE
{{ app_agent_dir.path }}/oc get SriovNetwork -n $NAMESPACE
{{ app_agent_dir.path }}/oc get SriovNetworkNodeState -n $NAMESPACE
{{ app_agent_dir.path }}/oc get SriovNetworkNodePolicy -n $NAMESPACE

echo "=== -o yaml ==="

{{ app_agent_dir.path }}/oc get -o yaml pods -n $NAMESPACE
{{ app_agent_dir.path }}/oc get -o yaml deployments -n $NAMESPACE
{{ app_agent_dir.path }}/oc get -o yaml replicasets -n $NAMESPACE
{{ app_agent_dir.path }}/oc get -o yaml daemonsets -n $NAMESPACE

{{ app_agent_dir.path }}/oc get -o yaml csv -n $NAMESPACE
{{ app_agent_dir.path }}/oc get -o yaml operatorgroup -n $NAMESPACE

{{ app_agent_dir.path }}/oc get -o yaml SriovOperatorConfig -n $NAMESPACE
{{ app_agent_dir.path }}/oc get -o yaml SriovNetwork -n $NAMESPACE
{{ app_agent_dir.path }}/oc get -o yaml SriovNetworkNodeState -n $NAMESPACE
{{ app_agent_dir.path }}/oc get -o yaml SriovNetworkNodePolicy -n $NAMESPACE

echo "=== describe ==="

{{ app_agent_dir.path }}/oc describe pods -n $NAMESPACE
{{ app_agent_dir.path }}/oc describe deployments -n $NAMESPACE
{{ app_agent_dir.path }}/oc describe replicasets -n $NAMESPACE
{{ app_agent_dir.path }}/oc describe daemonsets -n $NAMESPACE

{{ app_agent_dir.path }}/oc describe csv -n $NAMESPACE
{{ app_agent_dir.path }}/oc describe operatorgroup -n $NAMESPACE

{{ app_agent_dir.path }}/oc describe SriovOperatorConfig -n $NAMESPACE
{{ app_agent_dir.path }}/oc describe SriovNetwork -n $NAMESPACE
{{ app_agent_dir.path }}/oc describe SriovNetworkNodeState -n $NAMESPACE
{{ app_agent_dir.path }}/oc describe SriovNetworkNodePolicy -n $NAMESPACE

echo "=== Collecting node info ==="
{{ app_agent_dir.path }}/oc get nodes -o yaml

echo "=== Collecting logs ==="
for pod in $({{ app_agent_dir.path }}/oc get pods -n $NAMESPACE -o name); do 
  echo "+++ logs for pod $pod +++"
  {{ app_agent_dir.path }}/oc logs -n $NAMESPACE $pod
done

EOF
