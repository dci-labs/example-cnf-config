# Testpmd

This hook deploys all resources from example-cnf scenario, then launches TRex job to evaluate the packet loss ratio in the deployment made.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default    | Description                                    |
|-----------------------------------|----------|------------|------------------------------------------------|
| example_cnf_skip_trex_job_failure | No       | false      | If true, do not fail the job if TRex job fails |
