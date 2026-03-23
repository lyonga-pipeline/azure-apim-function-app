# Ansible Azure Enterprise

## Purpose

This repository configures Azure virtual machines after Terraform creates them.

Simple way to think about it:

- Terraform builds the server.
- Ansible configures the server.

This repository is the guest operating system baseline for Linux and Windows
servers in an Azure landing zone.

## What This Repository Does

It applies a repeatable server baseline such as:

- operating system hardening
- certificate trust
- proxy settings
- logging and audit configuration
- Azure Monitor Agent
- endpoint protection
- backup agent
- vulnerability scanner
- service accounts
- CIS-inspired controls
- optional runtimes such as Java, IIS, .NET, SQL tools, and `nginx`

## What This Repository Does Not Do

It does not create Azure infrastructure.

It expects these to already exist:

- virtual machines
- network access from the Ansible control node to the virtual machines
- Azure tags used by the dynamic inventory
- internal package locations, MSI paths, and secrets needed by enterprise
  agents

## Quick Start For New Engineers

If you are new to this tool, read in this order:

1. This README
2. [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
3. [inventories/dev/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
4. One environment variable set:
   - [inventories/dev/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
   - [inventories/dev/group_vars/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/linux.yml)
   - [inventories/dev/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)
   - [inventories/dev/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)
5. [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)
6. One entry playbook:
   - [playbooks/bootstrap-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-linux.yml)
   - [playbooks/bootstrap-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-windows.yml)
   - [playbooks/site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)
7. One role, starting with:
   - [roles/common_baseline](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline)
   - [roles/linux_baseline](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/linux_baseline)
   - [roles/windows_baseline](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/windows_baseline)

## Repository Map

### Root files

- [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
  - default Ansible behavior for this repository
- [README.md](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/README.md)
  - operator guide for the repository

### `inventories/`

Environment-specific inventory and variables.

- `inventories/dev`
- `inventories/qa`
- `inventories/prod`

Each environment folder contains:

- `azure_rm.yml`
  - dynamic Azure inventory configuration
- `group_vars/all.yml`
  - values shared by all hosts in that environment
- `group_vars/linux.yml`
  - Linux-specific values
- `group_vars/windows.yml`
  - Windows-specific values
- `group_vars/vault.yml`
  - secrets, usually encrypted with Ansible Vault

### `playbooks/`

Main entry points teams run:

- `bootstrap-linux.yml`
- `bootstrap-windows.yml`
- `site.yml`
- `patch-linux.yml`
- `patch-windows.yml`
- `validate.yml`
- `emergency-lockdown.yml`

### `roles/`

Reusable building blocks.

Each role usually owns one area such as:

- baseline
- hardening
- logging
- monitoring
- backup
- vulnerability management
- certificate trust
- runtimes

### `vars/`

Shared values used by the playbooks:

- [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)
- [vars/compliance.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/compliance.yml)

### `collections/`

Ansible collection requirements:

- [collections/requirements.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/collections/requirements.yml)

### `scripts/` and `ci/`

Supporting scripts and CI assets.

## How A Run Works

When someone runs a playbook, the repository works in this order:

1. `ansible.cfg` sets the defaults.
2. the inventory discovers Azure VMs.
3. variables are loaded from inventory, shared vars, and role defaults.
4. the playbook decides which hosts and roles are in scope.
5. each role runs its tasks, templates, files, and handlers.
6. validation confirms the expected end state.

## Key Files Explained

This section explains the files most teams will touch.

Each file uses the same pattern:

1. where it lives
2. how it is wired into Ansible
3. what the important settings mean
4. how to verify it and common gotchas

### `ansible.cfg`

#### 1. File name and where it lives

- File: [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
- Location: repository root

#### 2. How it is wired into Ansible

Ansible reads this file automatically when you run commands from the repository
root.

It sets the default behavior for the whole project.

#### 3. Important settings and what they mean

- `inventory = ./inventories/dev/azure_rm.yml`
  - default inventory file if you do not pass `-i`
  - example: if you run `ansible-playbook playbooks/bootstrap-linux.yml`, this
    inventory is used unless you override it
- `roles_path = ./roles`
  - tells Ansible where local roles are stored
- `collections_paths = ./collections`
  - tells Ansible where the required collections are installed
- `host_key_checking = True`
  - SSH host keys must match
  - safer for enterprise use
- `forks = 20`
  - how many hosts Ansible can work on at once
- `fact_caching = jsonfile`
  - stores facts locally to speed up later runs
- `vault_identity_list = ...`
  - points to the vault password files for `dev`, `qa`, and `prod`
- `enable_plugins = ..., azure.azcollection.azure_rm`
  - allows the Azure dynamic inventory plugin to run

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-config dump --only-changed
```

Common gotchas:

- running from the wrong directory means Ansible may not pick up this file
- missing vault password files will break any run that needs encrypted values
- if `inventory` points to `dev`, do not assume prod will be used unless you
  pass `-i`

### `inventories/<env>/azure_rm.yml`

#### 1. File name and where it lives

- Example file:
  [inventories/dev/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
- Location: one per environment under `inventories/<env>/`

#### 2. How it is wired into Ansible

This is the Azure dynamic inventory source.

You wire it into Ansible by either:

- passing it with `-i`
- or making it the default inventory in `ansible.cfg`

Examples:

```bash
ansible-inventory -i inventories/dev/azure_rm.yml --graph
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-linux.yml
```

#### 3. Important settings and what they mean

- `plugin: azure.azcollection.azure_rm`
  - use the Azure Resource Manager inventory plugin
- `auth_source: auto`
  - use available Azure credentials automatically
  - this usually works with `az login` or CI environment variables
- `include_vm_resource_groups`
  - only search these resource groups for VMs
  - useful for speed and blast-radius control
- `plain_host_names: true`
  - keep host names simple
- `keyed_groups`
  - build groups from tags and Azure metadata
  - example:
    - `tags.environment=dev` becomes `env_dev`
    - `tags.application=finserv-api` becomes `app_finserv-api`
- `conditional_groups`
  - add hosts to groups when an expression is true
  - example:
    - Linux hosts go to `linux`
    - Windows hosts go to `windows`
    - `tags.exposure=public` goes to `public_facing`
- `hostvar_expressions`
  - create helper variables for each host
  - example:
    - `ansible_host` uses private IP first, public IP second
    - `azure_rg` stores the resource group name
- `exclude_host_filters`
  - remove hosts from inventory if they should not be managed
  - example:
    - exclude stopped VMs
    - exclude decommissioned VMs

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-inventory -i inventories/dev/azure_rm.yml --graph
ansible-inventory -i inventories/dev/azure_rm.yml --list
```

Common gotchas:

- empty inventory usually means wrong credentials, wrong resource groups, or no
  matching VMs
- if tags are missing or inconsistent, the expected groups will not exist
- if a host has no private IP, `ansible_host` falls back to public IP

### `inventories/<env>/group_vars/all.yml`

#### 1. File name and where it lives

- Example file:
  [inventories/dev/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
- Location: `inventories/<env>/group_vars/`

#### 2. How it is wired into Ansible

Ansible loads this automatically for all hosts in that inventory.

This is the main environment-level configuration file.

#### 3. Important settings and what they mean

- `environment_name`
  - environment label such as `dev`
- `organization_name`
  - company or platform label
- `change_freeze`
  - stops production-style runs when set to `true`
- `linux_admin_group`, `linux_ansible_user`
  - Linux baseline account and admin-group settings
- `windows_admin_group`, `windows_ansible_user`
  - Windows baseline admin settings
- `proxy_enabled`, `proxy_url`, `no_proxy_list`
  - enterprise proxy settings
- `ntp_servers`
  - time sources used by the server baseline
- `monitoring_enabled`
  - controls the Azure Monitor Agent role
- `defender_enabled`
  - controls endpoint protection tasks
- `backup_agent_enabled`
  - controls backup agent installation
- `vuln_scanner_enabled`
  - controls vulnerability agent installation
- `audit_logging_enabled`
  - controls log forwarding and audit configuration
- `service_accounts_enabled`
  - controls service account creation
- `cis_controls_enabled`
  - controls CIS-inspired hardening
- `ama_*`
  - Azure Monitor Agent package URLs and service names
- `corp_*`
  - certificate trust destinations and Windows stores
- `windows_connection_plugin`, `windows_psrp_port`
  - Windows remoting settings
- `rolling_batch_linux`, `rolling_batch_windows`, `max_fail_pct`
  - rollout-safety settings used in production-style playbooks
- `log_forward_target`, `log_forward_port`
  - audit logging destination
- `backup_agent_*`, `vuln_scanner_*`
  - package names and MSI paths for required agents

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-inventory -i inventories/dev/azure_rm.yml --host <host-name>
```

Common gotchas:

- placeholder URLs and MSI paths must be replaced before real deployment
- toggles may be `true`, but the package source may still be invalid
- do not store secrets here; use `vault.yml`

### `inventories/<env>/group_vars/linux.yml`

#### 1. File name and where it lives

- Example file:
  [inventories/dev/group_vars/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/linux.yml)

#### 2. How it is wired into Ansible

Ansible loads this automatically for Linux hosts in that inventory.

#### 3. Important settings and what they mean

- `baseline_packages_linux`
  - Linux packages that should exist on every managed Linux host
- `baseline_services_linux`
  - Linux services that should be enabled and running
- `linux_disable_root_ssh`
  - disable direct root SSH access
- `linux_password_authentication`
  - enable or disable SSH password authentication
- `linux_umask`
  - default file permission mask
- `linux_auditd_enabled`
  - whether auditd should be enabled
- `linux_fips_mode_required`
  - whether FIPS mode is expected
- `linux_open_ports_allowlist`
  - baseline open-port expectation used by validation or hardening logic

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible -i inventories/dev/azure_rm.yml linux -m ansible.builtin.debug -a "var=baseline_packages_linux"
```

Common gotchas:

- package names differ between Linux distributions
- hardening changes can block access if SSH assumptions are wrong

### `inventories/<env>/group_vars/windows.yml`

#### 1. File name and where it lives

- Example file:
  [inventories/dev/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)

#### 2. How it is wired into Ansible

Ansible loads this automatically for Windows hosts in that inventory.

#### 3. Important settings and what they mean

- `ansible_connection`
  - connection type for Windows hosts
  - here it is driven by `windows_connection_plugin`
- `ansible_psrp_protocol`
  - protocol for PowerShell remoting, usually `https`
- `ansible_psrp_port`
  - PSRP port, usually `5986` for HTTPS
- `ansible_psrp_auth`
  - authentication method for remoting
- `ansible_psrp_cert_validation`
  - certificate validation behavior
- `windows_features_common`
  - Windows features that should exist on managed hosts
- `windows_timezone`
  - server timezone
- `windows_enable_rdp`
  - whether RDP should remain enabled
- `windows_firewall_*`
  - firewall profile expectations
- `windows_installers_common`
  - standard Chocolatey packages installed by the baseline

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible -i inventories/dev/azure_rm.yml windows -m ansible.windows.win_ping
```

Common gotchas:

- PSRP must be reachable from the control node
- remoting or certificate settings may fail if the Windows image is not ready
- Chocolatey package names must be valid in the repository the host can reach

### `inventories/<env>/group_vars/vault.yml`

#### 1. File name and where it lives

- Example file:
  [inventories/dev/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)

#### 2. How it is wired into Ansible

Ansible loads this automatically with the other `group_vars` files, but this
file should be encrypted with Ansible Vault.

#### 3. Important settings and what they mean

- `ad_domain_name`
  - Active Directory domain name
- `ad_join_user`
  - account used for domain join or AD management tasks
- `ad_join_password`
  - password for the join or AD management account
- `linux_local_admin_password`
  - Linux account password if the role needs one
- `windows_local_admin_password`
  - Windows local admin password if the role needs one
- `service_account_passwords`
  - password map for named service accounts

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-vault view inventories/dev/group_vars/vault.yml
```

Common gotchas:

- never store plain-text secrets here in git
- missing vault password files will break playbook runs
- one wrong vault value can break domain join or service-account creation

### `vars/global.yml`

#### 1. File name and where it lives

- File:
  [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)

#### 2. How it is wired into Ansible

This file is loaded explicitly by the main playbooks using `vars_files`.

#### 3. Important settings and what they mean

- `release_metadata_owner`, `release_metadata_repo`
  - release metadata values used by supporting tooling
- `linux_java_required`
  - turn on the Java role
- `windows_dotnet_required`
  - turn on the .NET role
- `sql_client_tools_enabled`
  - turn on SQL client tools
- `nginx_reverse_proxy_enabled`
  - turn on the Linux reverse proxy role
- `iis_baseline_enabled`
  - turn on the IIS role

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-linux.yml -e "linux_java_required=true" --list-tasks
```

Common gotchas:

- this file is for shared settings, not secrets
- enabling a runtime here affects all playbook runs that load this file

### `vars/compliance.yml`

#### 1. File name and where it lives

- File:
  [vars/compliance.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/compliance.yml)

#### 2. How it is wired into Ansible

This file is also loaded explicitly by the main playbooks using `vars_files`.

#### 3. Important settings and what they mean

- `compliance_frameworks`
  - the compliance baselines the repository is aligned to
- `security_controls.password_rotation_days`
  - password rotation expectation
- `security_controls.privileged_access_review_days`
  - access review expectation
- `security_controls.log_retention_days`
  - log retention expectation

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible -i inventories/dev/azure_rm.yml all -m ansible.builtin.debug -a "var=compliance_frameworks"
```

Common gotchas:

- this file documents the shared control model, but it does not enforce every
  control by itself
- teams should not assume adding a framework name automatically configures a
  full policy set

### `playbooks/bootstrap-linux.yml`

#### 1. File name and where it lives

- File:
  [playbooks/bootstrap-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-linux.yml)

#### 2. How it is wired into Ansible

This is one of the main entry playbooks engineers run.

It targets the `linux` group returned by the dynamic inventory.

It explicitly loads:

- `vars/global.yml`
- `vars/compliance.yml`

It also automatically receives the relevant inventory `group_vars`.

#### 3. Important settings and what they mean

- `hosts: linux`
  - run only on hosts grouped as Linux
- `become: true`
  - use privilege escalation for Linux system changes
- `gather_facts: true`
  - collect host facts before role execution
- `vars_files`
  - load shared repository values
- `roles`
  - define the order of the Linux baseline

Role order in this file:

- `common_baseline`
- `cert_trust`
- `linux_baseline`
- `linux_hardening`
- `endpoint_proxy`
- `audit_logging`
- `azure_monitor_agent`
- `defender_for_endpoint`
- `backup_agent`
- `vulnerability_scanner`
- `service_accounts`
- `cis_controls`
- `java_runtime`
- `sql_client_tools`
- `nginx_reverse_proxy`
- `validation`

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-linux.yml --list-tasks
```

Common gotchas:

- package URLs and agent package names must be valid before a real run
- Linux hardening can affect access if SSH assumptions are wrong

### `playbooks/bootstrap-windows.yml`

#### 1. File name and where it lives

- File:
  [playbooks/bootstrap-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-windows.yml)

#### 2. How it is wired into Ansible

This is the main Windows bootstrap playbook.

It contains two plays:

- one for all Windows servers
- one for domain controller hosts only

It explicitly loads:

- `vars/global.yml`
- `vars/compliance.yml`

#### 3. Important settings and what they mean

First play:

- `hosts: windows`
  - run the Windows baseline on all Windows hosts
- `roles`
  - defines the normal Windows baseline order

Second play:

- `hosts: "windows:&role_domaincontroller"`
  - run only on Windows hosts tagged as domain controllers
- `roles: ad_foundation`
  - create baseline AD structure on those hosts

Main Windows role order:

- `common_baseline`
- `cert_trust`
- `domain_join`
- `windows_baseline`
- `windows_hardening`
- `endpoint_proxy`
- `audit_logging`
- `azure_monitor_agent`
- `defender_for_endpoint`
- `backup_agent`
- `vulnerability_scanner`
- `service_accounts`
- `cis_controls`
- `dotnet_runtime`
- `sql_client_tools`
- `iis_baseline`
- `validation`

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-windows.yml --list-tasks
```

Common gotchas:

- the domain-controller play only runs if the inventory creates
  `role_domaincontroller`
- Windows remoting must be working before any bootstrap can succeed

### `playbooks/site.yml`

#### 1. File name and where it lives

- File:
  [playbooks/site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)

#### 2. How it is wired into Ansible

This is the production-style rollout playbook.

It contains three plays:

- Linux production baseline
- Windows production baseline
- domain-controller AD foundation

Each play loads:

- `vars/global.yml`
- `vars/compliance.yml`

#### 3. Important settings and what they mean

Linux production play:

- `hosts: "linux:&env_prod"`
  - only Linux hosts in the `prod` environment
- `serial: "{{ rolling_batch_linux }}"`
  - roll out changes in batches
- `max_fail_percentage: "{{ max_fail_pct }}"`
  - stop if failure rate gets too high
- `pre_tasks`
  - check `change_freeze` before making changes

Windows production play:

- `hosts: "windows:&env_prod"`
  - only Windows hosts in the `prod` environment
- `serial: "{{ rolling_batch_windows }}"`
  - batch the rollout
- same `change_freeze` guard

AD production play:

- `hosts: "windows:&env_prod:&role_domaincontroller"`
  - only production domain-controller hosts
- same `change_freeze` guard

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/site.yml --check --diff
```

Common gotchas:

- if `change_freeze: true`, this playbook should stop by design
- `env_prod` must exist in inventory or the plays will match no hosts

### `playbooks/validate.yml`

#### 1. File name and where it lives

- File:
  [playbooks/validate.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/validate.yml)

#### 2. How it is wired into Ansible

This playbook is intentionally simple.

It targets all hosts and runs only the `validation` role.

#### 3. Important settings and what they mean

- `hosts: all`
  - run validation everywhere in the chosen inventory
- `roles: validation`
  - run only validation tasks

#### 4. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/validate.yml
```

Common gotchas:

- validation only checks what the role is written to check
- passing validation does not mean every business application is healthy

## How Roles Are Wired

Each role usually contains:

- `defaults/main.yml`
  - fallback values for that role
- `tasks/main.yml`
  - the role entry point
- `tasks/linux.yml` or `tasks/windows.yml`
  - OS-specific tasks
- `handlers/main.yml`
  - delayed actions such as restarts
- `templates/`
  - config files built from variables
- `files/`
  - static files copied as-is

Examples:

- [roles/common_baseline/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/main.yml)
  - includes Linux or Windows tasks based on the host OS
- [roles/common_baseline/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/linux.yml)
  - installs Linux baseline packages and settings
- [roles/common_baseline/tasks/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/windows.yml)
  - installs Windows baseline packages and settings
- [roles/cert_trust/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/cert_trust/tasks/main.yml)
  - routes to Linux or Windows trust tasks
- [roles/cert_trust/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/cert_trust/tasks/linux.yml)
  - copies CA files and triggers a trust refresh

## Main Roles And What They Are For

### Baseline roles

- `common_baseline`
  - shared setup used by both Linux and Windows
- `linux_baseline`
  - Linux operating system baseline
- `windows_baseline`
  - Windows operating system baseline
- `linux_hardening`
  - Linux hardening controls
- `windows_hardening`
  - Windows hardening controls

### Security and operations roles

- `cert_trust`
  - installs corporate trust certificates
- `endpoint_proxy`
  - configures approved proxy settings
- `audit_logging`
  - configures audit and log forwarding
- `azure_monitor_agent`
  - installs Azure Monitor Agent
- `defender_for_endpoint`
  - enables or validates endpoint protection
- `backup_agent`
  - installs and configures the backup agent
- `vulnerability_scanner`
  - installs the vulnerability scanner agent
- `service_accounts`
  - creates approved service accounts
- `cis_controls`
  - applies CIS-inspired controls
- `validation`
  - checks the expected end state

### Optional workload roles

- `domain_join`
  - joins Windows systems to Active Directory
- `ad_foundation`
  - creates baseline AD OUs and security groups on domain controller hosts
- `java_runtime`
  - installs Java on Linux
- `dotnet_runtime`
  - installs the .NET hosting bundle on Windows
- `sql_client_tools`
  - installs SQL tools on Linux or Windows
- `nginx_reverse_proxy`
  - enables the Linux reverse proxy pattern
- `iis_baseline`
  - installs IIS on Windows

## Typical Installables For A Financial-Company Baseline

This repository already covers most of the installables a financial company
would normally expect at the OS layer.

### Linux

- `chrony` / `chronyd`
- `rsyslog`
- `audit` / `auditd`
- `curl`
- `jq`
- `unzip`
- `openssl`
- `ca-certificates`
- `python3-pip`
- `bind-utils`
- `nmap-ncat`
- optional Java runtime
- optional SQL client tools
- optional `nginx`

### Windows

- `RSAT-AD-PowerShell`
- `.NET Framework 4.5` core feature
- Chocolatey packages:
  - `7zip`
  - `notepadplusplus`
  - `sysinternals`
  - `microsoft-edge`
- optional IIS
- optional .NET hosting bundle
- optional SQL tools
- optional AD foundation for domain controller hosts

### Enterprise agents and controls

- Azure Monitor Agent
- Microsoft Defender for Endpoint / Windows Defender checks
- backup agent
- vulnerability scanner
- audit log forwarding
- proxy configuration
- service accounts
- CIS-inspired controls

## What Is Ready Today

Ready once environment values are populated:

- Azure dynamic inventory
- Linux and Windows baseline playbooks
- production rollout playbook
- patch playbooks
- validation playbook
- enterprise roles for monitoring, protection, backup, scanning, and hardening

## What Must Be Replaced Before Production

- internal package URLs
- Windows MSI paths
- real backup and scanner package names if placeholders differ
- real proxy values
- real log forwarding destinations
- real corporate certificate files if the current files are placeholders
- real encrypted secrets in `vault.yml`

## Control Node Prerequisites

Before a team can run the playbooks, the control node needs:

- Python 3
- Ansible
- Azure CLI login or service principal authentication
- Ansible collections from
  [collections/requirements.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/collections/requirements.yml)
- PSRP support for Windows if the control node is Linux or macOS
- access to the vault password files referenced in
  [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)

Recommended setup:

```bash
cd ansible-azure-enterprise
python3 -m venv .venv
source .venv/bin/activate
pip install "ansible-core>=2.17,<2.19" pypsrp pywinrm
ansible-galaxy collection install -r collections/requirements.yml
az login
```

## Common Run Commands

Check the inventory:

```bash
ansible-inventory -i inventories/dev/azure_rm.yml --graph
```

List hosts:

```bash
ansible -i inventories/dev/azure_rm.yml all --list-hosts
```

Run Linux bootstrap:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-linux.yml
```

Run Windows bootstrap:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-windows.yml
```

Run production rollout:

```bash
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/site.yml --check --diff
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/site.yml
```

Run patching:

```bash
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/patch-linux.yml
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/patch-windows.yml
```

Run validation only:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/validate.yml
```

Target one application or host group:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-linux.yml --limit app_finserv-api
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-windows.yml --limit role_domaincontroller
```

## Recommended Onboarding Path

For a junior engineer, the easiest way to understand the implementation is:

1. Read this README.
2. Read `ansible.cfg`.
3. Read one environment inventory.
4. Read the related `group_vars`.
5. Read one entry playbook.
6. Read the first few roles in that playbook in order.

That reading order matches how the repository actually runs.
