# Launch TRex job

On an already deployed example-cnf, this hook deploys a new TRexApp job, to check if a new TRex execution achieves the same result than the previous iteration.

This hook reuses the retry-trex play, included in the example_cnf_deploy role from [redhatci.ocp collection](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/README.md).

To ensure the previous run of TRex (usually the default CR) is not polluting the results, all the event from the previous CR are removed.

| Name             | Required | Default    | Description                                 |
|------------------|----------|------------|---------------------------------------------|
| trex_app_cr_name | Yes      | 'trex-app' | Name of the initial CR that will be cleaned |
