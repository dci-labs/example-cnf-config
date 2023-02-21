# Upgrade validation
This hook is expected to be run after an upgrade job, where the CNF app was running, with a meaningful TREX profile.

This hook prepares and launches the 'validation' role from [nfv-example-cnf-deploy](https://github.com/rh-nfv-int/nfv-example-cnf-deploy).

## Continuous burst ending - WIP
Covering the case where the T-REX profile duration has been set to '-1'