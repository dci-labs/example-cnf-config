# Security Policy

## Supported Versions

This repository provides sample DCI hooks and Kubernetes templates for lab/CI deployment of the example CNF. Security fixes are applied on the default branch (`master`).

## Reporting a Vulnerability

Do **not** open a public GitHub issue for security vulnerabilities.

Report potential security issues in Red Hat software through the Red Hat Product Security process:

- Email: [secalert@redhat.com](mailto:secalert@redhat.com)
- Guidance: [Red Hat Coordinated Vulnerability Disclosure](https://access.redhat.com/articles/red-hat-coordinated-vulnerability-disclosure)
- Contact / PGP: [Security Contacts and Procedures](https://access.redhat.com/security/team/contact)

Please include the repository name (`dci-labs/example-cnf-config`), affected files or hooks, and reproduction steps when possible.

## Maintainer expectations

Repository administrators should keep GitHub branch protection enabled on `master` (required pull-request reviews and required status checks for lint workflows) so that unreviewed changes cannot land on the default branch.
