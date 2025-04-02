# Draining validation

If example-cnf is launched in continuous mode (or emulating continuous mode with a long TRex job duration), we can use this hook to emulate a node draining process that impacts in the worker node where testpmd pod is deployed, then it needs to be reallocated, and consequently packet loss starts to appear.

For this to work, some requirements need to be met:

- example-cnf needs to be deployed in continuous mode or emulating continuous mode, as said before.
- The MAC addresses used by testpmd pod need to be hardcoded, to ensure the same MAC addresses are used in the new pod scheduled in a different worker node.
- There must be 3+ worker nodes to allow testpmd being reallocated in a different worker, also different than the worker node where trex is running.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default    | Description                                      |
|-----------------------------------|----------|------------|--------------------------------------------------|
| example_cnf_cnfapp_name           | No       | testpmd    | CNFApp to be used. Only "testpmd" can be used    |
