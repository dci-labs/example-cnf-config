# Launch TRex job

On an already deployed example-cnf, this hook deploys a new TRexApp job, to check if a new TRex execution achieves the same result than the previous iteration.

This hook reuses the retry-trex play, included in the example_cnf_deploy role from [redhatci.ocp collection](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/README.md).

To ensure the previous run of TRex (usually the default CR) is not polluting the results, all the event from the previous CR are removed.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default      | Description                                      |
|-----------------------------------|----------|--------------|--------------------------------------------------|
| trex_app_cr_name                  | Yes      | 'trex-app'   | Name of the initial CR that will be cleaned      |
| example_cnf_cnfapp_name           | No       | testpmd      | CNFApp to be used. Only "testpmd" can be used    |
| trex_app_new_cr_name              | No       | trex-app-new | Name of the TRexApp CR to create                 |

## Automation

This scenario runs against an example-cnf install that is already up (see [cnfapp](../cnfapp/README.md)). Pre-run resolves the catalog. Install clears events from the first TRexApp, then calls `ecd_action: deploy_extra_trex` ([tasks/deploy_extra_trex.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/deploy_extra_trex.yml)), which includes [tasks/trex/retry-trex.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/trex/retry-trex.yml) and [tasks/trex/app.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/trex/app.yml).

The TRex server is left as-is. A new `TRexApp` is reconciled by [trex-operator/roles/trexapp](https://github.com/openshift-kni/example-cnf/blob/main/trex-operator/roles/trexapp/tasks/main.yml). The Job container publishes results from [trexstats.py](https://github.com/openshift-kni/example-cnf/blob/main/trex-container-app/app/pyfiles/trexstats.py).

### Pre-run

```mermaid
sequenceDiagram
    participant Hook as launch_trex_job pre-run
    participant DCI as DCI job
    participant Skopeo
    participant OPM as opm

    Hook->>Hook: ecd_cnf_namespace = example-cnf
    Hook->>Hook: trex_app_first_cr = trex_app_cr_name or trex-app
    Hook->>Hook: example_cnf_cnfapp_name = testpmd
    Hook->>DCI: Read component type nfv-example-cnf-index
    DCI-->>Hook: operator_version
    Hook->>Hook: example_cnf_index_image =<br/>quay.io/rh-nfv-int/nfv-example-cnf-catalog:version
    Hook->>Skopeo: cnfapp resolve-catalog-digest.yml
    Skopeo-->>Hook: Pin the index to @sha256
    Hook->>OPM: opm render, relatedImages of olm.bundle
    OPM-->>Hook: trex_app_v = image ref containing trex-container-app@
```

### Install

```mermaid
sequenceDiagram
    participant Hook as launch_trex_job install
    participant OCP as OpenShift API
    participant Role as example_cnf_deploy<br/>tasks/deploy_extra_trex.yml
    participant TrexCfg as trex-operator<br/>roles/trexconfig
    participant TrexApp as trex-operator<br/>roles/trexapp
    participant Stats as trex-container-app<br/>trexstats.py

    Hook->>OCP: List Events involvedObject.name=trex-app
    loop each event from the first TRexApp
        Hook->>OCP: Delete Event
    end

    Hook->>Role: include_role ecd_action=deploy_extra_trex<br/>CR name trex-app-new, image trex_app_v
    Note over Role: tasks/main.yml asserts cnfapp is testpmd<br/>and ecd_trex_app_version is set<br/>then includes trex/retry-trex.yml
    Role->>OCP: check_nodes.yml
    Role->>OCP: Get TRexConfig trexconfig
    Note over Role,TrexCfg: The server CR already exists,<br/>so trex/app.yml skips TRexConfig creation<br/>and the running trex-server pod stays
    TrexCfg-->>OCP: Existing Deployment and Service trex-server

    Role->>Role: get-example-cnf-status.sh before the job
    Role->>OCP: Apply templates/trex-app-cr.yaml.j2<br/>name trex-app-new, arpResolution 0
    OCP->>TrexApp: Reconcile TRexApp
    TrexApp->>OCP: Require TRexConfig, then job-check.yml
    TrexApp->>OCP: ServiceAccount, Role, RoleBinding
    TrexApp->>OCP: Job job-trex-app-new<br/>image from the catalog trex-container-app ref
    OCP->>Stats: Run the new profile against trex-server
    Stats->>OCP: TestStarted
    Stats->>OCP: PacketMatched or PacketDropped
    Stats->>OCP: TestCompleted, then TestPassed or TestFailed
    Role->>OCP: Wait for those events on trex-app-new
    Role->>Role: get-example-cnf-status.sh and get-example-cnf-results.sh
    Role->>Role: Copy Job logs to the DCI log directory
```
