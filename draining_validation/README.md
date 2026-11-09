# Draining validation

If example-cnf is launched in continuous mode (or emulating continuous mode with a long TRex job duration), we can use this hook to emulate a node draining process that impacts in the worker node where testpmd pod is deployed, then it needs to be reallocated, and consequently packet loss starts to appear.

For this to work, some requirements need to be met:

- example-cnf needs to be deployed in continuous mode or emulating continuous mode, as said before.
- The MAC addresses used by testpmd pod need to be hardcoded, to ensure the same MAC addresses are used in the new pod scheduled in a different worker node.
- There must be 3+ worker nodes to allow testpmd being reallocated in a different worker, also different than the worker node where trex is running.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default      | Description                                      |
|-----------------------------------|----------|..------------|--------------------------------------------------|
| example_cnf_cnfapp_name           | No       | testpmd      | CNFApp to be used. Only "testpmd" can be used    |
| trex_app_cr_name_to_check         | No       | trex-app-new | Name of the TRexApp CR to create                |

## Automation

This scenario runs while a TestPMD deployment and a long TRex job are already in the cluster (see [cnfapp](../cnfapp/README.md) and [launch_trex_job](../launch_trex_job/README.md)). Install calls `ecd_action: draining` ([tasks/draining.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/draining.yml)). The TestPMD operator keeps the Deployment, so deleting the pod schedules a replacement. Packet-loss events still come from [trexstats.py](https://github.com/openshift-kni/example-cnf/blob/main/trex-container-app/app/pyfiles/trexstats.py) on the TRexApp Job.

### Pre-run

[hooks/pre-run.yml](hooks/pre-run.yml) only sets facts.

```mermaid
sequenceDiagram
    participant Hook as draining_validation pre-run

    Hook->>Hook: ecd_cnf_namespace = example-cnf
    Hook->>Hook: example_cnf_cnfapp_name = testpmd
```

### Install

```mermaid
sequenceDiagram
    participant Hook as draining_validation install
    participant Role as example_cnf_deploy<br/>tasks/draining.yml
    participant OCP as OpenShift API
    participant TpmdOp as testpmd-operator<br/>roles/testpmd
    participant Stats as trex-container-app<br/>trexstats.py

    Hook->>Role: include_role ecd_action=draining<br/>TRexApp name trex-app-new
    Note over Role: tasks/main.yml asserts cnfapp is testpmd<br/>and OCP >= 4.14, then includes draining.yml
    Role->>OCP: check_nodes.yml
    Role->>Role: Fail when the cluster is single-node

    Role->>OCP: draining/gather-facts.yml<br/>pod example-cnf-type=cnf-app and pkt-gen
    OCP-->>Role: testpmd node, testpmd pod name, trex node

    Role->>OCP: oc adm cordon the testpmd node
    Role->>OCP: Wait until the node is SchedulingDisabled
    Role->>OCP: oc adm drain --pod-selector example-cnf-type=cnf-app<br/>--delete-emptydir-data (async)
    Role->>OCP: Wait until the old testpmd pod is gone
    Role->>Role: Record deletion timestamp

    Note over TpmdOp,OCP: The Deployment was applied earlier by<br/>testpmd-operator/roles/testpmd/templates/deployment.yml<br/>Pod annotations carry the MAC list from the TestPMD CR
    OCP->>OCP: Deployment controller schedules a replacement pod on another worker
    Role->>OCP: Wait until container testpmd is Running
    Role->>Role: Record recreation timestamp
    Role->>Role: Assert the new node differs from the old testpmd node and from the trex node
    Role->>OCP: oc adm uncordon the drained node

    Stats->>OCP: TestCompleted, TestPassed or TestFailed, PacketMatched
    Role->>OCP: draining/trex-validation.yml waits for those events<br/>on the TRexApp named by ecd_trex_app_cr_name
    Role->>Role: Downtime seconds and percent of the TRex duration
    Role->>Role: Write trex-downtime.log and the Job log under the DCI log path
```
