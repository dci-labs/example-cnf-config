# CNFApp

This hook deploys all resources from example-cnf scenario, then launches TRex job to evaluate the packet loss ratio in the deployment made.

We can use either [TestPMD](https://doc.dpdk.org/guides/testpmd_app_ug/) or [Grout](https://github.com/DPDK/grout/) as CNF application. Both are based on DPDK.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default    | Description                                                                                           |
|-----------------------------------|----------|------------|-------------------------------------------------------------------------------------------------------|
| example_cnf_enable_rdma_exclusive | No       | false      | Enable RDMA exclusive mode to configure a RDMA subsystem for SRIOV. This requires a specific setup for the SriovNetwork, please check [this documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking/hardware-networks#nw-sriov-networknodepolicy-object_configuring-sriov-device). This procedure only applies to Mellanox NICs. |
| example_cnf_cnfapp_name           | No       | grout      | CNFApp to be used. Could be "grout" or "testpmd"                                                      |
| example_cnf_skip_trex_job_failure | No       | false      | If true, do not fail the job if TRex job fails                                                        |
| example_cnf_sriov_file            | Yes      | ''         | Path to find the SRIOV config file, to generate SriovNetworkNodePolicy and SriovNetwork
| example_cnf_network_config_file   | No       | ''         | Path to find the network config file to provide IP-MAC config to TRex and CNFApp (required for Grout) |
| run_migration_test                | No       | true       | Enable migration tests                                                                                |
| run_opcap_check                   | No       | true       | Enable opcap check                                                                                    |

## Pod Security Admission

The `example-cnf` namespace is created with `pod-security.kubernetes.io/enforce: privileged` because DPDK/SR-IOV workloads need capabilities and device access that are not allowed under the `baseline` or `restricted` Pod Security Standards (for example `IPC_LOCK`, `NET_ADMIN`, and vfio). SCC-to-PSA label sync is disabled so OpenShift does not overwrite that choice.

`audit` and `warn` are set to `restricted` so pods that would violate the restricted profile are still recorded and warned about, without failing admission for the lab/CI workload. This namespace is ephemeral and removed during teardown; it is not intended as a production security boundary.
