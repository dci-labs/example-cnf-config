# CNFApp

This hook deploys all resources from example-cnf scenario, then launches TRex job to evaluate the packet loss ratio in the deployment made.

We can use either [TestPMD](https://doc.dpdk.org/guides/testpmd_app_ug/) or [Grout](https://github.com/DPDK/grout/) as CNF application. Both are based on DPDK.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default    | Description                                                                                           |
|-----------------------------------|----------|------------|-------------------------------------------------------------------------------------------------------|
| example_cnf_cnfapp_name           | No       | grout      | CNFApp to be used. Could be "grout" or "testpmd"                                                      |
| example_cnf_skip_trex_job_failure | No       | false      | If true, do not fail the job if TRex job fails                                                        |
| example_cnf_network_config_file   | No       | ''         | Path to find the network config file to provide IP-MAC config to TRex and CNFApp (required for Grout) |
| run_migration_test                | No       | true       | Enable migration tests |
| run_opcap_check                   | No       | true       | Enable opcap check |
