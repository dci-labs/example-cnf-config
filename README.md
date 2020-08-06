# cnf-example-config

Samples files to deploy and enable `TestPMD` application with the `dci-openshift-app-agent` .
Work In Progress.

Usage
----------
* Copy (with recursive) `hooks/*` to `/etc/dci-openshift-app-agent/hooks/`
* Start the `dci-openshift-app-agent` in foreground.

```
# su - dci-openshift-app-agent
$ export KUBECONFIG=/path/to/kubeconfig 
$ cd /usr/share/dci-openshift-app-agent && source /etc/dci-openshift-app-agent/dcirc.sh && ansible-playbook -vv /usr/share/dci-openshift-app-agent/dci-openshift-app-agent.yml -e dci_topic=OCP-4.4
```