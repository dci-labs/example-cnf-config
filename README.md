# example-cnf-config

Samples files to deploy and enable `TestPMD` application with the `dci-openshift-app-agent` .
Work In Progress.

## Usage
### From dci-openshift-app-agent
* Copy (with recursive) `hooks/*` to `/etc/dci-openshift-app-agent/hooks/`
* Start the `dci-openshift-app-agent` in foreground.

```
# su - dci-openshift-app-agent
$ export KUBECONFIG=/path/to/kubeconfig 
$ cd /usr/share/dci-openshift-app-agent && source /etc/dci-openshift-app-agent/dcirc.sh && ansible-playbook -vv /usr/share/dci-openshift-app-agent/dci-openshift-app-agent.yml -e dci_topic=OCP-4.5 -e cluster_name=cluster6
```

### From dci-pipeline
Create a pipeline file. For example:

```
---
  - name: example-cnf
    type: cnf
    prev_stages: [ocp]
    ansible_playbook: /usr/share/dci-openshift-app-agent/dci-openshift-app-agent.yml
    ansible_cfg: /var/lib/dci/pipelines/ansible.cfg
    dci_credentials: /etc/dci-openshift-app-agent/dci_credentials.yml
    ansible_extravars:
      dci_cache_dir: /var/lib/dci-pipeline
      dci_config_dir: /path/to/git/clone/example-cnf-config/testpmd
      operator_version: v0.0.1
      app_version: v0.1.2
      repo_name: nfv-example-cnf
      ocp_version: 4.7
      enable_trex: true
    topic: OCP-4.5
    components: []
    inputs:
      kubeconfig: kubeconfig_path
    success_tag: example-cnf-ok
```

Then run it from `dci-pipeline`:

```
$ dci-pipeline cnf:ansible_inventory=/var/lib/dci/inventories/dallas/8nodes/cluster6-post.yml /var/lib/dci/pipelines/example-cnf-on-ocp-4.5-pipeline.yml
```

### From schedule

```
TBD
```

### Upgrade validation
When run during an upgrade, an extra DCI hook can be called to gather information about the CNF behavior.
See [upgrade validation doc](upgrade_validation/README.md).

### Node draining validation
If example-cnf is launched in continuous mode (or emulating continuous mode with a long TRex job duration), we can use [draining validation](draining_validation/README.md) to emulate a node draining process that impacts in the worker node where testpmd pod is deployed, then it needs to be reallocated, and consequently packet loss starts to appear.

### Launch a new TRex job

If you want to launch a new TRex job on an already deployed example-cnf instance, use the launch_trex_job hook.
See [launch_trex_job docs](launch_trex_job/README.md) for more details.
