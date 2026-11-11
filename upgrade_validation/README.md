# Upgrade validation

This hook is expected to be run after an upgrade job, where the CNF app was running, with a meaningful TREX profile.

This hook prepares and launches the validation tasks from example_cnf_deploy role from [redhatci.ocp collection](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/README.md).

To ensure the previous run of TRex (usually the default CR) is not polluting the results, all the event from the previous CR are removed.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default    | Description                                      |
|-----------------------------------|----------|------------|--------------------------------------------------|
| trex_app_cr_name                  | Yes      | 'trex-app' | Name of the initial CR that will be cleaned      |
| example_cnf_cnfapp_name           | No       | testpmd    | CNFApp to be used. Only "testpmd" can be used    |

## Continuous burst ending - WIP

Covering the case where the TRex profile duration has been set to '-1'. TBD.

## Automation

This scenario assumes [cnfapp](../cnfapp/README.md) already deployed TestPMD and a TRex job, and that an OpenShift upgrade has finished. The hook then reuses `ecd_action: validate` from [`example_cnf_deploy`](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/validate.yml). Operators stay in place: the TestPMD operator recreates the pod after deletion, and [trexstats.py](https://github.com/openshift-kni/example-cnf/blob/main/trex-container-app/app/pyfiles/trexstats.py) is the source of `PacketMatched` and `PacketDropped` events.

### Pre-run

[hooks/pre-run.yml](hooks/pre-run.yml) records the namespace, the previous TRexApp name, and TestPMD as the CNF application.

```mermaid
sequenceDiagram
    participant Hook as upgrade_validation pre-run

    Hook->>Hook: ecd_cnf_namespace = example-cnf
    Hook->>Hook: trex_app_first_cr = trex_app_cr_name or trex-app
    Hook->>Hook: example_cnf_cnfapp_name = testpmd
```

### Install

[hooks/install.yml](hooks/install.yml) drops events from the TRexApp that ran across the upgrade, then runs the same migration and packet-loss checks as the cnfapp tests hook.

```mermaid
sequenceDiagram
    participant Hook as upgrade_validation install
    participant OCP as OpenShift API
    participant Role as example_cnf_deploy<br/>tasks/validate.yml
    participant TpmdOp as testpmd-operator<br/>roles/testpmd
    participant Stats as trex-container-app<br/>trexstats.py

    Hook->>OCP: List Events involvedObject.name=trex-app
    loop each previous event
        Hook->>OCP: Delete Event
    end

    Hook->>Role: include_role ecd_action=validate<br/>cnfapp testpmd
    Note over Role: tasks/main.yml asserts OCP >= 4.14<br/>then includes validate.yml
    Role->>OCP: check_nodes.yml
    Role->>Role: Fail when the cluster is single-node
    Role->>OCP: validate/migrate.yml<br/>require exactly one TestPMD CR
    Stats-->>OCP: PacketMatched or PacketDropped from the job that ran across the upgrade
    Role->>OCP: Wait for Event reason=PacketMatched

    Role->>OCP: oc adm cordon the testpmd node
    Role->>OCP: Delete the cnf-app pod
    Note over TpmdOp,OCP: The Deployment was applied earlier by<br/>testpmd-operator/roles/testpmd/templates/deployment.yml
    OCP->>OCP: Deployment controller schedules a replacement pod
    Role->>OCP: Wait until pod count is restored and phase is Running
    Role->>OCP: oc adm uncordon
    Role->>Role: Fail if the new pod is still on the cordoned node

    Role->>OCP: validate/validate.yml<br/>collect PacketMatched and PacketDropped
    Role->>Role: packet_missing reports gaps between drop and match

    Hook->>OCP: List Jobs in example-cnf until at least one exists
    Hook->>Hook: set_fact list of Job names
```
