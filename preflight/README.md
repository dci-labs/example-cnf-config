# Example CNF Preflight Configuration

This directory provides the configuration for running [Red Hat Preflight](https://github.com/redhat-openshift-ecosystem/openshift-preflight) certification tests within a Distributed CI (DCI) pipeline targeting Cloud-Native Network Functions (CNFs).

## What is Preflight?

Preflight is a tool provided by Red Hat to automate the certification process for containers and operators. It helps validate that components (such as the example-cnf operator or workload containers) are ready for certification and follow the required best practices.

## Summary of Tasks Performed Per Hook

The `preflight` directory contains several Ansible hooks involved in preparing and executing Preflight certification checks against the Example CNF components. Most important one is the [pre-run hook](hooks/pre-run.yml), where we have the following tasks:

- Extract information from the nfv-example-cnf-index component (required in the pipeline definition).
- Build `preflight_operators_to_certify` variable based on the index content.
    - We will take grout-operator-bundle for this test.
- Build `preflight_containers_to_certify` variable based on the index content.
    - We will take trex-container images for this test.
- Workflow selection with `example_cnf_preflight_workflow` variable:
    - The `example_cnf_preflight_workflow` variable provides fine-grained control over which certification checks are executed. Its value can be set to `"all"`, `"operator"`, or `"container"`.