# Upgrade validation
This hook is expected to be run after an upgrade job, where the CNF app was running, with a meaningful TREX profile.

This hook prepares and launches the 'validation' role from [nfv-example-cnf-deploy](https://github.com/rh-nfv-int/nfv-example-cnf-deploy).
To ensure the previous run of T-REX (usually the default CR) is not polluting the results, all the event from the previous CR are removed.

| Name             | Required | Default    | Description                                 |
|------------------|----------|------------|---------------------------------------------|
| trex_app_cr_name | Yes      | 'trex-app' | Name of the initial CR that will be cleaned |

## Continuous burst ending - WIP
Covering the case where the T-REX profile duration has been set to '-1'