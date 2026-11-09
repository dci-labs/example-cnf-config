# CNFApp

This hook deploys all resources from example-cnf scenario, then launches TRex job to evaluate the packet loss ratio in the deployment made.

We can use either [TestPMD](https://doc.dpdk.org/guides/testpmd_app_ug/) or [Grout](https://github.com/DPDK/grout/) as CNF application. Both are based on DPDK.

Some variables than can be used for debugging purposes:

| Name                              | Required | Default    | Description                                                                                           |
|-----------------------------------|----------|------------|-------------------------------------------------------------------------------------------------------|
| example_cnf_enable_rdma_exclusive | No       | false      | Enable RDMA exclusive mode to configure a RDMA subsystem for SRIOV. This requires a specific setup for the SriovNetwork, please check [this documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking/hardware-networks#nw-sriov-networknodepolicy-object_configuring-sriov-device). This procedure only applies to Mellanox NICs. |
| example_cnf_cnfapp_name           | No       | grout      | CNFApp to be used. Could be "grout" or "testpmd"                                                      |
| example_cnf_skip_trex_job_failure | No       | false      | If true, do not fail the job if TRex job fails                                                        |
| example_cnf_sriov_file            | Yes      | ''         | Path to find the SRIOV config file, to generate SriovNetworkNodePolicy and SriovNetwork
| example_cnf_network_config_file   | No       | ''         | Path to find the network config file to provide IP-MAC config to TRex and CNFApp (required for Grout) |
| run_migration_test                | No       | true       | Enable migration tests                                                                                |
| run_opcap_check                   | No       | true       | Enable opcap check                                                                                    |

## Pod Security Admission

The `example-cnf` namespace is created with `pod-security.kubernetes.io/enforce: privileged` because DPDK/SR-IOV workloads need capabilities and device access that are not allowed under the `baseline` or `restricted` Pod Security Standards (for example `IPC_LOCK`, `NET_ADMIN`, and vfio). SCC-to-PSA label sync is disabled so OpenShift does not overwrite that choice.

`audit` and `warn` are set to `restricted` so pods that would violate the restricted profile are still recorded and warned about, without failing admission for the lab/CI workload. This namespace is ephemeral and removed during teardown; it is not intended as a production security boundary.

## Automation

Three layers run this scenario:

1. Hooks in [cnfapp/hooks](hooks).
2. [`redhatci.ocp.example_cnf_deploy`](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/main.yml), dispatched by `ecd_action`.
3. Operators in [openshift-kni/example-cnf](https://github.com/openshift-kni/example-cnf). `watches.yaml` maps each CR to an Ansible role: [Grout](https://github.com/openshift-kni/example-cnf/blob/main/grout-operator/roles/grout/tasks/main.yml), [TestPMD](https://github.com/openshift-kni/example-cnf/blob/main/testpmd-operator/roles/testpmd/tasks/main.yml), [TRexConfig](https://github.com/openshift-kni/example-cnf/blob/main/trex-operator/roles/trexconfig/tasks/main.yml), and [TRexApp](https://github.com/openshift-kni/example-cnf/blob/main/trex-operator/roles/trexapp/tasks/main.yml).

### Pre-run

[hooks/pre-run.yml](hooks/pre-run.yml) prepares the namespace and publishes the example-cnf catalog. The catalog step is `ecd_action: catalog`, which runs [tasks/catalog.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/catalog.yml) and then [`redhatci.ocp.catalog_source`](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/catalog_source/tasks/main.yml).

```mermaid
sequenceDiagram
    participant Hook as cnfapp pre-run
    participant DCI as DCI job
    participant Skopeo
    participant OCP as OpenShift API
    participant Sriov as sriov_config role
    participant Role as example_cnf_deploy<br/>tasks/catalog.yml
    participant Cat as catalog_source role

    Hook->>Hook: Require example_cnf_sriov_file
    Hook->>Hook: Default example_cnf_cnfapp_name to grout
    Hook->>Hook: set_fact namespace example-cnf and SR-IOV nets

    Hook->>DCI: Read component type nfv-example-cnf-index
    DCI-->>Hook: operator_version, index image URL, component id

    opt dci_change_dir contains an example-cnf checkout
        Hook->>Hook: generate-versions.sh from the PR JSON
        Hook->>DCI: Remove the stable nfv-example-cnf-index component
        Note over Hook: Index image becomes<br/>quay.io/rh-nfv-int/nfv-example-cnf-catalog<br/>tagged by generate-versions.sh
    end

    Hook->>Skopeo: resolve-catalog-digest.yml inspects the index
    Skopeo-->>Hook: Pin example_cnf_index_image to tag@sha256

    opt certify_operators is true
        Hook->>Hook: opm render, keep images whose ref contains bundle@
        Note over Hook: preflight_operators_to_certify
    end

    Hook->>OCP: Namespace example-cnf<br/>PSA enforce=privileged, audit/warn=restricted
    loop label in cnf-app, pkt-gen, pkt-gen-app, controller-manager
        Hook->>OCP: NetworkPolicy from network_policies_cnf_traffic.yml.j2
    end
    Hook->>OCP: Read Service/Endpoints kubernetes
    Hook->>OCP: NetworkPolicies for DNS, API, and Istio<br/>network_policies_istio_dns_api_traffic.yml.j2
    Hook->>OCP: ResourceQuota from resource_quota.yml.j2

    opt example_cnf_enable_rdma_exclusive
        Hook->>OCP: SriovNetworkPoolConfig worker<br/>rdmaMode exclusive
    end

    Hook->>Sriov: include_role with example_cnf_sriov_file
    Sriov->>OCP: SriovNetworkNodePolicy and SriovNetwork

    Hook->>Hook: Install git, make, python3-openshift, python3-pyyaml

    opt dci_disconnected
        Hook->>Hook: mirror-catalog.yml
        Note over Hook: mirror_images + mirror_catalog<br/>ImageDigestMirrorSet or ImageContentSourcePolicy<br/>wait for MachineConfigPool
    end

    Hook->>Role: include_role ecd_action=catalog
    Note over Role: tasks/main.yml asserts ecd_action<br/>and OCP >= 4.14, then includes catalog.yml
    Role->>Role: Assert operator version and CatalogSource CRD
    Role->>Skopeo: skopeo inspect catalog image
    Skopeo-->>Role: index digest
    Role->>Cat: cs_image pinned to @digest, registryPoll 30m
    Cat->>OCP: CatalogSource nfv-example-cnf-catalog<br/>namespace openshift-marketplace
```

**OpenShift resources created in pre-run**

| Resource | Namespace | Created by |
|----------|-----------|------------|
| Namespace `example-cnf` | — | hook |
| NetworkPolicy (CNF traffic, DNS, API, Istio) | example-cnf | hook templates |
| ResourceQuota | example-cnf | hook template |
| SriovNetworkPoolConfig `worker` | openshift-sriov-network-operator | hook, when RDMA exclusive is enabled |
| SriovNetworkNodePolicy, SriovNetwork | openshift-sriov-network-operator | `redhatci.ocp.sriov_config` |
| CatalogSource `nfv-example-cnf-catalog` | openshift-marketplace | `example_cnf_deploy` `catalog` → `catalog_source` |

### Install

[hooks/install.yml](hooks/install.yml) selects the high-performance RuntimeClass, then calls the role with `ecd_action: deploy` ([tasks/deploy.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/deploy.yml)). Operator install is [tasks/deploy/sub.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/deploy/sub.yml) through [`redhatci.ocp.olm_operator`](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/olm_operator/tasks/main.yml). Workload CRs are created in [tasks/deploy/app.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/deploy/app.yml) and [tasks/trex/app.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/trex/app.yml).

```mermaid
sequenceDiagram
    participant Hook as cnfapp install
    participant OCP as OpenShift API
    participant Role as example_cnf_deploy<br/>tasks/deploy.yml
    participant OLM as olm_operator role
    participant CnfOp as grout-operator or<br/>testpmd-operator
    participant TrexCfg as trex-operator<br/>roles/trexconfig
    participant TrexApp as trex-operator<br/>roles/trexapp
    participant Stats as trex-container-app<br/>trexstats.py

    Hook->>OCP: List RuntimeClass, keep handler high-performance
    Hook->>Role: include_role ecd_action=deploy<br/>cnfapp, catalog image, runtime class, network file

    Note over Role: tasks/main.yml asserts action and OCP >= 4.14
    Role->>Role: Fail when cnfapp is grout and the network file is empty
    Role->>OCP: check_nodes.yml sets single-node or multi-node
    Role->>Role: opm render catalog<br/>set trex-container-app@ and trex-container-server@

    Role->>OLM: deploy/sub.yml for each enabled operator
    Note over OLM: grout-operator or testpmd-operator,<br/>plus trex-operator<br/>OperatorGroup example-cnf-operator-group<br/>Subscription channel alpha, approval Automatic
    OLM->>OCP: OperatorGroup, Subscription, InstallPlan, CSV
    OLM->>OCP: Wait until the operator pod is ready

    Role->>OCP: Wait for a NetworkAttachmentDefinition in example-cnf
    opt ecd_network_config_file is set
        Role->>Role: deploy/net-config.yml<br/>MAC and IP lists for cnfapp and trex
    end

    alt cnfapp is grout
        Role->>OCP: Apply templates/grout-cr.yaml.j2<br/>networks, trexMaclist, trexIplist
        OCP->>CnfOp: Reconcile kind Grout<br/>grout-operator/roles/grout
        CnfOp->>CnfOp: network-parse.yaml reads the NAD resourceName
        CnfOp->>OCP: ServiceAccount, Role, RoleBinding
        CnfOp->>OCP: Deployment grout-app
        Note over CnfOp,OCP: Init grout-init args generate-grout-config<br/>env TREX_MAC_LIST and TREX_IP_LIST<br/>Init frr-init args generate-frr-config<br/>Containers grout and frr, shared API socket
        CnfOp->>OCP: PodDisruptionBudget for the grout pod
    else cnfapp is testpmd
        Role->>OCP: Apply templates/testpmd-cr.yaml.j2<br/>ethpeerMaclist from the TRex MAC list
        OCP->>CnfOp: Reconcile kind TestPMD<br/>testpmd-operator/roles/testpmd
        CnfOp->>CnfOp: Build eth_peer as port,mac pairs
        CnfOp->>OCP: ServiceAccount, Role, RoleBinding, Deployment, PDB
        Note over CnfOp: TestPMD forwards by MAC<br/>using ethpeerMaclist
    end

    Role->>OCP: Wait for pod example-cnf-type=cnf-app Running<br/>grout also waits for container frr

    Role->>Role: trex/retry-trex.yml includes trex/app.yml
    Role->>OCP: Create TRexConfig trexconfig when it is absent<br/>templates/trex-server-cr.yaml.j2
    OCP->>TrexCfg: Reconcile kind TRexConfig
    TrexCfg->>TrexCfg: network-parse.yaml
    TrexCfg->>OCP: ServiceAccount, Role, RoleBinding, Deployment, PDB
    TrexCfg->>OCP: Service trex-server TCP 4500 and 4501
    Role->>OCP: Wait for container trex-server Running

    Role->>OCP: Apply templates/trex-app-cr.yaml.j2<br/>duration, rate, size, trexIps, cnfappIps<br/>arpResolution 1 for grout, 0 for testpmd
    OCP->>TrexApp: Reconcile kind TRexApp
    TrexApp->>OCP: Fail the reconcile until a TRexConfig exists
    TrexApp->>TrexApp: job-check.yml skips creation while a pkt-gen-app Job is active
    TrexApp->>OCP: ServiceAccount, Role, RoleBinding, Job job-trex-app
    OCP->>Stats: Container trex-app runs the profile
    Stats->>OCP: Event TestStarted
    Stats->>OCP: Event PacketMatched or PacketDropped
    Stats->>OCP: Event TestCompleted, then TestPassed or TestFailed
    Role->>OCP: Wait for those events on the TRexApp
    Role->>Role: get-example-cnf-status.sh and get-example-cnf-results.sh

    opt ecd_trex_test_config is set and continuous mode is off
        Role->>Role: trex/tests.yml creates one extra TRexApp per profile
        OCP->>TrexApp: Reconcile each extra TRexApp into its own Job
    end

    Hook->>OCP: PodDisruptionBudget for control-plane=controller-manager
    opt do_certsuite
        Hook->>OCP: apply_certsuite_config labels pods that skip connectivity tests
    end
```

**Custom resources and what the operator turns them into**

| CR from the role | Operator role | Workload |
|------------------|---------------|----------|
| `Grout` [grout-cr.yaml.j2](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/templates/grout-cr.yaml.j2) | [grout/tasks/main.yml](https://github.com/openshift-kni/example-cnf/blob/main/grout-operator/roles/grout/tasks/main.yml) | Deployment with `grout-init`, `frr-init`, `grout`, `frr` |
| `TestPMD` [testpmd-cr.yaml.j2](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/templates/testpmd-cr.yaml.j2) | [testpmd/tasks/main.yml](https://github.com/openshift-kni/example-cnf/blob/main/testpmd-operator/roles/testpmd/tasks/main.yml) | Deployment, MAC forwarding via `eth_peer` |
| `TRexConfig` [trex-server-cr.yaml.j2](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/templates/trex-server-cr.yaml.j2) | [trexconfig/tasks/main.yml](https://github.com/openshift-kni/example-cnf/blob/main/trex-operator/roles/trexconfig/tasks/main.yml) | TRex server Deployment, PDB, Service `trex-server` |
| `TRexApp` [trex-app-cr.yaml.j2](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/templates/trex-app-cr.yaml.j2) | [trexapp/tasks/main.yml](https://github.com/openshift-kni/example-cnf/blob/main/trex-operator/roles/trexapp/tasks/main.yml) and [job-check.yml](https://github.com/openshift-kni/example-cnf/blob/main/trex-operator/roles/trexapp/tasks/job-check.yml) | Job `job-<cr-name>`; events from [trexstats.py](https://github.com/openshift-kni/example-cnf/blob/main/trex-container-app/app/pyfiles/trexstats.py) |

### Tests

[hooks/tests.yml](hooks/tests.yml) calls `ecd_action: validate` ([tasks/validate.yml](https://github.com/redhatci/ansible-collection-redhatci-ocp/blob/main/roles/example_cnf_deploy/tasks/validate.yml)) and, separately, `redhatci.ocp.opcap_tool`.

```mermaid
sequenceDiagram
    participant Hook as cnfapp tests
    participant Role as example_cnf_deploy<br/>tasks/validate.yml
    participant OCP as OpenShift API
    participant Opcap as opcap_tool role

    opt run_migration_test (default true)
        Hook->>Role: include_role ecd_action=validate
        Role->>OCP: check_nodes.yml
        Role->>Role: Fail when the cluster is single-node
        Role->>OCP: validate/migrate.yml<br/>require exactly one Grout or TestPMD
        opt example_cnf_skip_trex_job_failure and no PacketMatched event
            Role->>Role: Skip migration (ecd_try_running_migration_tests=false)
        end
        Role->>OCP: Wait for Event reason=PacketMatched
        Role->>OCP: validate/pod-delete.yml
        Note over Role,OCP: oc adm cordon the cnf-app node<br/>delete the pod<br/>wait until a new Running pod appears<br/>oc adm uncordon<br/>fail if the new pod stays on the same node
        Role->>OCP: validate/validate.yml<br/>list PacketMatched and PacketDropped
        Role->>Role: packet_missing on those events
    end

    opt run_opcap_check (default true)
        Hook->>Opcap: CatalogSource nfv-example-cnf-catalog<br/>namespace openshift-marketplace
        Opcap->>OCP: Score the catalog and write results under job logs
    end
```

### Teardown

[hooks/teardown.yml](hooks/teardown.yml) deletes the objects this scenario created. Every delete in this stage is a task in the hook.

```mermaid
sequenceDiagram
    participant Hook as cnfapp teardown
    participant OCP as OpenShift API

    Hook->>Hook: Assert ecd_cnf_namespace and example_cnf_sriov_file
    Hook->>OCP: Delete Subscriptions in example-cnf
    Hook->>OCP: Delete ClusterServiceVersions in example-cnf
    Hook->>OCP: oc delete all --all -n example-cnf
    Hook->>OCP: Delete Namespace example-cnf
    loop until the namespace is gone
        Hook->>OCP: Get Namespace example-cnf
    end
    Hook->>OCP: Delete CatalogSource nfv-example-cnf-catalog
    Hook->>Hook: include_vars example_cnf_sriov_file
    loop each SriovNetwork
        Hook->>OCP: Delete SriovNetwork
    end
    loop each SriovNetworkNodePolicy
        Hook->>OCP: Delete SriovNetworkNodePolicy
    end
    opt example_cnf_enable_rdma_exclusive
        Hook->>OCP: Delete SriovNetworkPoolConfig worker
    end
    opt pullsecret_tmp_file was created
        Hook->>Hook: Remove the temporary pull-secret file
    end
```
