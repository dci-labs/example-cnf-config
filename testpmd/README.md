# Testpmd

This hook interacts with [nfv-example-cnf-deploy](https://github.com/rh-nfv-int/nfv-example-cnf-deploy) repository to deploy all resources from example-cnf scenario, then launch TRex job to evaluate the packet loss ratio in the deployment made.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default    | Description                                    |
|-----------------------------------|----------|------------|------------------------------------------------|
| example_cnf_skip_trex_job_failure | No       | false      | If true, do not fail the job if TRex job fails |
