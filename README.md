# example-cnf-config

Samples files to deploy and enable CNF application based on DPDK (could be either [TestPMD](https://doc.dpdk.org/guides/testpmd_app_ug/) or [Grout](https://github.com/DPDK/grout/)) with `dci-openshift-app-agent` and `dci-pipeline`.

## Related projects

- [example-cnf project](https://github.com/openshift-kni/example-cnf): here you will find the images in which example-cnf operators and workloads are based.
- [example_cnf_deploy Ansible role](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/README.md): here you will find the Ansible role used to support the automation of this hook.
- [example-cnf pipelines](https://github.com/dci-labs/dallas-pipelines): here you can find the pipelines (prefixed with `example-cnf`) to deploy the different scenarios to test example-cnf. Please refer to [dci-pipeline docs](https://doc.distributed-ci.io/dci-pipeline/) to review how `dci-pipeline` works and how to deploy your pipeline.

## Scenarios

### CNFApp deployment

This implies the deployment of example-cnf operators and workloads. See [cnfapp doc](cnfapp/README.md).

### Upgrade validation

> This scenario is only supported by TestPMD for the time being.

When running example-cnf during an upgrade, an extra DCI hook can be called to gather information about the CNF behavior. See [upgrade_validation doc](upgrade_validation/README.md).

### Launch a new TRex job

> This scenario is only supported by TestPMD for the time being.

If you want to launch a new TRex job on an already deployed example-cnf instance, use the launch_trex_job hook. See [launch_trex_job docs](launch_trex_job/README.md) for more details.

### Node draining validation

> This scenario is only supported by TestPMD for the time being.

If example-cnf is launched in continuous mode (or emulating continuous mode with a long TRex job duration), we can use [draining validation](draining_validation/README.md) to emulate a node draining process that impacts in the worker node where TestPMD pod is deployed and TRex is running, then TestPMD pod needs to be reallocated, and consequently packet loss starts to appear.
