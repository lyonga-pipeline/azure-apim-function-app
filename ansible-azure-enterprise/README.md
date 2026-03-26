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

## How The Main Playbooks Are Wired End To End

This section shows the normal call path for the main operating-system baseline
playbooks. This is the easiest way for a new engineer to understand how the
files connect.

### Linux bootstrap flow

File chain:

1. [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
   sets the default inventory, roles path, collections path, and vault
   identities.
2. [inventories/<env>/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
   discovers Azure VMs and creates groups such as `linux`, `env_dev`,
   `env_prod`, and `app_*`.
3. [inventories/<env>/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
   loads automatically for every discovered host in that environment.
4. [inventories/<env>/group_vars/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/linux.yml)
   loads automatically for hosts in the `linux` group.
5. [inventories/<env>/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)
   loads automatically too, if it can be decrypted.
6. [playbooks/bootstrap-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-linux.yml)
   targets `hosts: linux` and explicitly adds
   [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)
   and
   [vars/compliance.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/compliance.yml).
7. The playbook runs roles in this order:
   `cert_trust -> endpoint_proxy -> common_baseline -> linux_baseline -> linux_hardening -> audit_logging -> azure_monitor_agent -> defender_for_endpoint -> backup_agent -> vulnerability_scanner -> service_accounts -> cis_controls -> java_runtime -> sql_client_tools -> nginx_reverse_proxy -> validation`
8. Each role starts at its own `tasks/main.yml`, which may then include
   `linux.yml`, `windows.yml`, templates, and handlers.

Important examples:

- `baseline_packages_linux` from
  [inventories/dev/group_vars/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/linux.yml)
  is consumed by
  [roles/common_baseline/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/linux.yml).
- `ntp_servers` from
  [inventories/dev/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
  is consumed by
  [roles/linux_baseline/templates/chrony.conf.j2](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/linux_baseline/templates/chrony.conf.j2).
- `proxy_url` and `no_proxy_list` from
  [inventories/dev/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
  are consumed by
  [roles/endpoint_proxy/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/endpoint_proxy/tasks/linux.yml)
  and
  [roles/backup_agent/templates/backup-agent.conf.j2](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/backup_agent/templates/backup-agent.conf.j2).
- `monitoring_enabled` and `ama_*` values from
  [inventories/dev/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
  are consumed by
  [roles/azure_monitor_agent/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/azure_monitor_agent/tasks/main.yml)
  and
  [roles/azure_monitor_agent/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/azure_monitor_agent/tasks/linux.yml).

### Windows bootstrap flow

File chain:

1. [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
   sets the default inventory, roles path, collections path, and vault
   identities.
2. [inventories/<env>/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
   discovers Azure VMs and creates groups such as `windows`,
   `role_domaincontroller`, and `env_prod`.
3. [inventories/<env>/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
   loads automatically for every discovered host.
4. [inventories/<env>/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)
   loads automatically for Windows hosts.
5. [inventories/<env>/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)
   provides domain-join and service-account secrets.
6. [playbooks/bootstrap-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-windows.yml)
   contains:
   - one play for `hosts: windows`
   - one play for `hosts: "windows:&role_domaincontroller"`
7. The first play loads
   [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)
   and
   [vars/compliance.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/compliance.yml),
   then runs:
   `cert_trust -> endpoint_proxy -> common_baseline -> domain_join -> windows_baseline -> windows_hardening -> audit_logging -> azure_monitor_agent -> defender_for_endpoint -> backup_agent -> vulnerability_scanner -> service_accounts -> cis_controls -> dotnet_runtime -> sql_client_tools -> iis_baseline -> validation`
8. The second play runs only the `ad_foundation` role for domain controller
   hosts.

Important examples:

- `ansible_connection`, `ansible_psrp_*`, and `ansible_shell_type` from
  [inventories/dev/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)
  are consumed by Ansible itself before any role runs.
- `windows_features_common`, `windows_installers_common`, and
  `windows_timezone` from
  [inventories/dev/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)
  are consumed by
  [roles/common_baseline/tasks/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/windows.yml).
- `ad_domain_name`, `ad_join_user`, and `ad_join_password` from
  [inventories/dev/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)
  are consumed by
  [roles/domain_join/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/domain_join/tasks/main.yml)
  and
  [roles/ad_foundation/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/ad_foundation/tasks/main.yml).

### Production-style site flow

[playbooks/site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)
uses the same inventory and variable loading model as the bootstrap playbooks,
but adds rollout safety for production.

What is different:

- it targets `linux:&env_prod` and `windows:&env_prod`, so it depends on the
  `env_prod` group created by
  [inventories/prod/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/prod/azure_rm.yml)
- it uses `rolling_batch_linux`, `rolling_batch_windows`, and `max_fail_pct`
  from
  [inventories/prod/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/prod/group_vars/all.yml)
- it checks `change_freeze` before making changes
- it includes a third play for `windows:&env_prod:&role_domaincontroller`

### Linux patch flow

[playbooks/patch-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/patch-linux.yml)
is simpler than the bootstrap playbooks.

It still depends on:

- [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
- [inventories/<env>/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
- auto-loaded inventory variables

It does not call the role stack.

Instead it:

- targets `hosts: linux`
- uses `ansible_os_family` facts to decide between `yum` and `apt`
- optionally uses `linux_reboot_after_patch` if you pass it as an inventory
  variable or extra var

### Windows patch flow

[playbooks/patch-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/patch-windows.yml)
is the Windows equivalent.

It depends on:

- [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
- [inventories/<env>/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
- Windows connection values from
  [inventories/<env>/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)

It does not call the role stack either.

It directly runs `ansible.windows.win_updates` against the `windows` group.

## Key Files Explained

This section explains the files most teams will touch.

Each file uses the same pattern:

1. where it lives
2. why it matters in this project
3. where and how it is used
4. what the important settings mean
5. how to verify it and common gotchas

### `ansible.cfg`

#### 1. File name and where it lives

- File: [ansible.cfg](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/ansible.cfg)
- Location: repository root

#### 2. Why this file matters in this project

This is the starting point for local runs.

If a new engineer opens only one file after this README, this is usually the
next best file because it shows:

- which inventory Ansible uses by default
- where roles are loaded from
- where collections are loaded from
- how vault decryption is expected to work

#### 3. Where and how it is used

Ansible reads this file automatically when you run commands from the repository
root.

In this project it is what connects:

- the root command line experience to
  [inventories/dev/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
- the entry playbooks to local roles under
  [roles](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles)
- encrypted `vault.yml` files to the vault identities configured on the
  control node
- dynamic inventory support to the Azure plugin

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This file tells Ansible which Azure VMs exist and which groups they belong to.

Without this file, the playbooks do not know which servers are Linux, which are
Windows, which are `prod`, or which hosts are domain controllers.

#### 3. Where and how it is used

This is the Azure dynamic inventory source.

You wire it into Ansible by either:

- passing it with `-i`
- or making it the default inventory in `ansible.cfg`

Examples:

```bash
ansible-inventory -i inventories/dev/azure_rm.yml --graph
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/bootstrap-linux.yml
```

The groups created here are used directly by the main playbooks:

- `linux` in
  [bootstrap-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-linux.yml),
  [patch-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/patch-linux.yml),
  and the Linux plays in
  [site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)
- `windows` in
  [bootstrap-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-windows.yml),
  [patch-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/patch-windows.yml),
  and the Windows plays in
  [site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)
- `env_prod` in
  [site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)
- `role_domaincontroller` in
  [bootstrap-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-windows.yml)
  and
  [site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This is the main environment-level configuration file.

If a team wants to change how a whole environment behaves, this is usually the
first file they update.

#### 3. Where and how it is used

Ansible loads this automatically for all hosts in that inventory.

The values in this file are consumed by multiple roles and playbooks:

- `linux_admin_group` and `linux_ansible_user` are used by
  [roles/common_baseline/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/linux.yml)
- `proxy_enabled`, `proxy_url`, and `no_proxy_list` are used by
  [roles/endpoint_proxy/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/endpoint_proxy/tasks/main.yml)
  and OS-specific proxy tasks
- `ntp_servers` is used by
  [roles/linux_baseline/templates/chrony.conf.j2](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/linux_baseline/templates/chrony.conf.j2)
- `monitoring_enabled` and `ama_*` values are used by
  [roles/azure_monitor_agent/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/azure_monitor_agent/tasks/main.yml)
- `corp_*` values are used by
  [roles/cert_trust/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/cert_trust/tasks/linux.yml)
  and
  [roles/cert_trust/tasks/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/cert_trust/tasks/windows.yml)
- `backup_agent_*` values are used by
  [roles/backup_agent/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/backup_agent/tasks/main.yml)
- `vuln_scanner_*` values are used by
  [roles/vulnerability_scanner/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/vulnerability_scanner/tasks/main.yml)
- `change_freeze`, `rolling_batch_linux`, `rolling_batch_windows`, and
  `max_fail_pct` are used in
  [site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This file defines the Linux baseline and hardening inputs for one environment.

When a Linux engineer wants to understand why a server got certain packages,
service settings, SSH restrictions, or validation checks, this is one of the
main files to inspect.

#### 3. Where and how it is used

Ansible loads this automatically for Linux hosts in that inventory.

The main values are wired into these active role files:

- `baseline_packages_linux` and `baseline_services_linux` are used by
  [roles/common_baseline/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/linux.yml)
- `linux_disable_root_ssh`, `linux_password_authentication`, `linux_umask`,
  and `linux_auditd_enabled` are used by
  [roles/linux_hardening/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/linux_hardening/tasks/main.yml)
- distro-specific service handling is completed by
  [roles/linux_baseline/defaults/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/linux_baseline/defaults/main.yml)
  and
  [roles/validation/defaults/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/validation/defaults/main.yml)
- `linux_fips_mode_required` and `linux_open_ports_allowlist` are not consumed
  by active tasks today; they are stored here as future baseline inputs

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

Verify:

```bash
ansible -i inventories/dev/azure_rm.yml linux -m ansible.builtin.debug -a "var=baseline_packages_linux"
```

Common gotchas:

- package names differ between Linux distributions, which is why this file now
  builds `baseline_packages_linux` from a common list plus distro-specific
  additions
- hardening changes can block access if SSH assumptions are wrong

### `inventories/<env>/group_vars/windows.yml`

#### 1. File name and where it lives

- Example file:
  [inventories/dev/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)

#### 2. What this file is for and why it matters

This file does two jobs:

- it gives Ansible the connection settings needed to reach Windows hosts
- it provides the Windows baseline values used by the roles

#### 3. Where and how it is used

Ansible loads this automatically for Windows hosts in that inventory.

The values in this file are wired in two different ways:

- `ansible_connection`, `ansible_psrp_protocol`, `ansible_psrp_port`,
  `ansible_psrp_auth`, `ansible_psrp_cert_validation`, and
  `ansible_shell_type` are consumed by Ansible itself before any playbook role
  runs
- `windows_features_common`, `windows_installers_common`, and
  `windows_timezone` are used by
  [roles/common_baseline/tasks/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/windows.yml)
- `windows_enable_rdp` is used by
  [roles/windows_hardening/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/windows_hardening/tasks/main.yml)
- `windows_firewall_*` values are not consumed directly today; the current
  hardening role enables all three Windows firewall profiles without reading
  those switches

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This file stores secrets and private values that should not live in the normal
inventory files.

For most teams, this is the file that controls domain join, privileged local
account passwords, and service-account passwords.

#### 3. Where and how it is used

Ansible loads this automatically with the other `group_vars` files, but this
file should be encrypted with Ansible Vault.

These values are consumed by active roles:

- `ad_domain_name`, `ad_join_user`, and `ad_join_password` are used by
  [roles/domain_join/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/domain_join/tasks/main.yml)
  and
  [roles/ad_foundation/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/ad_foundation/tasks/main.yml)
- `linux_local_admin_password` is used by
  [roles/common_baseline/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/linux.yml)
- `windows_local_admin_password` and `service_account_passwords` are used by
  [roles/service_accounts/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/service_accounts/tasks/main.yml)

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This file holds shared repository-wide switches for optional roles and runtime
components.

It is where teams usually turn optional capabilities on or off for all runs
that use the main baseline playbooks.

#### 3. Where and how it is used(-->> mostlt to turn on/off roles, when set to true role will be turned off. This uses the "when" condition in the role task config)

This file is loaded explicitly by:

- [playbooks/bootstrap-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-linux.yml)
- [playbooks/bootstrap-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-windows.yml)
- [playbooks/site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)

The main values are then consumed by these roles:

- `linux_java_required` ->
  [roles/java_runtime/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/java_runtime/tasks/main.yml)
- `windows_dotnet_required` ->
  [roles/dotnet_runtime/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/dotnet_runtime/tasks/main.yml)
- `sql_client_tools_enabled` ->
  [roles/sql_client_tools/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/sql_client_tools/tasks/main.yml)
- `nginx_reverse_proxy_enabled` ->
  [roles/nginx_reverse_proxy/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/nginx_reverse_proxy/tasks/main.yml)
- `iis_baseline_enabled` ->
  [roles/iis_baseline/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/iis_baseline/tasks/main.yml)
- `release_metadata_owner` and `release_metadata_repo` are stored here as
  shared metadata, but they are not consumed by active tasks today

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This file documents the shared compliance model the baseline is meant to align
to.

It helps teams understand the target control posture even when a given control
is implemented outside Ansible, for example in Terraform, Azure Policy, or a
security product.

#### 3. Where and how it is used

This file is loaded explicitly by:

- [playbooks/bootstrap-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-linux.yml)
- [playbooks/bootstrap-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-windows.yml)
- [playbooks/site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)

Today these values are mainly documentation and shared reference values. They
are not heavily consumed by active role tasks yet.

#### 4. Important settings and what they mean

- `compliance_frameworks`
  - the compliance baselines the repository is aligned to
- `security_controls.password_rotation_days`
  - password rotation expectation
- `security_controls.privileged_access_review_days`
  - access review expectation
- `security_controls.log_retention_days`
  - log retention expectation

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This is one of the main entry playbooks engineers run.

Use this playbook when you want to apply the full Linux operating-system
baseline to the selected environment.

It is usually the first full Linux configuration run after Terraform creates
servers.

#### 3. Where and how it is used

This playbook is wired to the rest of the repository like this:

- it depends on the `linux` group created by
  [inventories/<env>/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
- it auto-loads
  [inventories/<env>/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml),
  [inventories/<env>/group_vars/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/linux.yml),
  and
  [inventories/<env>/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)
- it explicitly loads
  [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)
  and
  [vars/compliance.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/compliance.yml)
- it then calls roles in a fixed order so certificates and proxy settings are
  in place before package-based roles run

#### 4. Important settings and what they mean

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

- `cert_trust`
- `endpoint_proxy`
- `common_baseline`
- `linux_baseline`
- `linux_hardening`
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

Why this order matters:

- `cert_trust` comes first so internal certificates are available
- `endpoint_proxy` comes next so package managers can reach internal package
  sources
- `common_baseline` installs the core OS packages and service-account baseline
- later roles add monitoring, protection, backup, scanning, and validation

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This is the main Windows bootstrap playbook.

It contains two plays:

- one for all Windows servers
- one for domain controller hosts only

Use this when you want to apply the full Windows baseline after the VM exists.

#### 3. Where and how it is used

This playbook is wired to the rest of the repository like this:

- it depends on the `windows` and `role_domaincontroller` groups created by
  [inventories/<env>/azure_rm.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/azure_rm.yml)
- it auto-loads
  [inventories/<env>/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml),
  [inventories/<env>/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml),
  and
  [inventories/<env>/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)
- it explicitly loads
  [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)
  and
  [vars/compliance.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/compliance.yml)
- it runs one main Windows baseline play and one narrower AD foundation play

#### 4. Important settings and what they mean

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

- `cert_trust`
- `endpoint_proxy`
- `common_baseline`
- `domain_join`
- `windows_baseline`
- `windows_hardening`
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

Why this order matters:

- `cert_trust` and `endpoint_proxy` prepare trusted and reachable package
  sources
- `common_baseline` establishes the common Windows features and packages
- `domain_join` happens before the AD-specific or application-specific roles
- the second play is isolated so only domain controller hosts get the AD
  foundation tasks

#### 5. How to verify it and common gotchas

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

#### 2. What this file is for and why it matters

This is the production-style rollout playbook.

It contains three plays:

- Linux production baseline
- Windows production baseline
- domain-controller AD foundation

Each play loads:

- `vars/global.yml`
- `vars/compliance.yml`

Use this when you want controlled, batched changes in a production
environment.

#### 3. Where and how it is used

This playbook is wired like the bootstrap playbooks, but it adds production
targeting and rollout guards:

- it depends on `env_prod` and `role_domaincontroller` groups created by the
  inventory
- it consumes `change_freeze`, `rolling_batch_linux`,
  `rolling_batch_windows`, and `max_fail_pct` from
  [inventories/prod/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/prod/group_vars/all.yml)
- it uses the same role stack as bootstrap, but only against production hosts

#### 4. Important settings and what they mean

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

#### 5. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/site.yml --check --diff
```

Common gotchas:

- if `change_freeze: true`, this playbook should stop by design
- `env_prod` must exist in inventory or the plays will match no hosts

### `playbooks/patch-linux.yml`

#### 1. File name and where it lives

- File:
  [playbooks/patch-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/patch-linux.yml)

#### 2. What this file is for and why it matters

This is the Linux patching playbook.

Use it when you only want operating-system package patching and reboot handling,
not the full baseline role stack.

#### 3. Where and how it is used

This playbook is wired more simply than the bootstrap playbooks:

- it depends on the `linux` group created by the inventory
- it uses gathered facts such as `ansible_os_family` to choose `yum` or `apt`
- it does not load `vars/global.yml` or `vars/compliance.yml`
- it does not call repository roles
- it optionally reads `linux_reboot_after_patch` if you pass it as an extra var
  or define it in inventory

#### 4. Important settings and what they mean

- `hosts: linux`
  - patch all Linux hosts in the selected inventory
- `serial: 5`
  - patch five hosts at a time
- Red Hat task
  - updates all packages with `yum`
- Debian task
  - updates all packages with `apt`
- reboot task
  - reboots when `linux_reboot_after_patch` is true or not set

#### 5. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/patch-linux.yml --list-tasks
```

Common gotchas:

- this playbook does not apply hardening, agents, or validation roles
- `linux_reboot_after_patch` is optional and defaults to `true`

### `playbooks/patch-windows.yml`

#### 1. File name and where it lives

- File:
  [playbooks/patch-windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/patch-windows.yml)

#### 2. What this file is for and why it matters

This is the Windows patching playbook.

Use it when you only want Windows Update execution and reboot handling, not the
full Windows baseline.

#### 3. Where and how it is used

This playbook depends on:

- the `windows` group created by the inventory
- Windows connection settings from
  [inventories/<env>/group_vars/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/windows.yml)

Like the Linux patch playbook, it does not load shared `vars_files` and does
not call repository roles.

#### 4. Important settings and what they mean

- `hosts: windows`
  - patch all Windows hosts in the selected inventory
- `serial: 3`
  - patch three hosts at a time
- `ansible.windows.win_updates`
  - installs Windows critical, security, and rollup updates
  - reboots automatically when Windows Update requires it

#### 5. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/prod/azure_rm.yml playbooks/patch-windows.yml --list-tasks
```

Common gotchas:

- Windows remoting must already be working
- this playbook does not run the baseline, security, or validation roles

### `playbooks/validate.yml`

#### 1. File name and where it lives

- File:
  [playbooks/validate.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/validate.yml)

#### 2. What this file is for and why it matters

This playbook is intentionally simple.

Use it when you want to check the current baseline state without rerunning the
full bootstrap or site playbooks.

#### 3. Where and how it is used

This playbook depends on:

- the selected inventory and host groups
- the `validation` role under
  [roles/validation](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/validation)

It does not load `vars/global.yml` or `vars/compliance.yml`.

It simply runs validation tasks against every host matched by the chosen
inventory.

#### 4. Important settings and what they mean

- `hosts: all`
  - run validation everywhere in the chosen inventory
- `roles: validation`
  - run only validation tasks

#### 5. How to verify it and common gotchas

Verify:

```bash
ansible-playbook -i inventories/dev/azure_rm.yml playbooks/validate.yml
```

Common gotchas:

- validation only checks what the role is written to check
- passing validation does not mean every business application is healthy

## How To Trace A Setting Through The Repository

When you need to understand why a server changed, use this method:

1. Start with the playbook you ran.
2. Confirm the target host group in the inventory.
3. Check which `group_vars` files were auto-loaded.
4. Check whether the playbook also loaded `vars/global.yml` or
   `vars/compliance.yml`.
5. Find the role in the playbook role list.
6. Open that role's `tasks/main.yml`.
7. Follow any `include_tasks`, templates, defaults, and handlers.

Examples:

- `baseline_packages_linux`
  - defined in
    [inventories/dev/group_vars/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/linux.yml)
  - loaded automatically for Linux hosts
  - consumed by
    [roles/common_baseline/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/linux.yml)
  - playbooks that use it:
    [bootstrap-linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/bootstrap-linux.yml)
    and the Linux play in
    [site.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/playbooks/site.yml)
- `proxy_url`
  - defined in
    [inventories/dev/group_vars/all.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/all.yml)
  - consumed by
    [roles/endpoint_proxy/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/endpoint_proxy/tasks/linux.yml),
    [roles/endpoint_proxy/tasks/windows.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/endpoint_proxy/tasks/windows.yml),
    and
    [roles/backup_agent/templates/backup-agent.conf.j2](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/backup_agent/templates/backup-agent.conf.j2)
- `ad_join_password`
  - defined in
    [inventories/dev/group_vars/vault.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/vault.yml)
  - consumed by
    [roles/domain_join/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/domain_join/tasks/main.yml)
    and
    [roles/ad_foundation/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/ad_foundation/tasks/main.yml)
- `linux_java_required`
  - defined in
    [vars/global.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/vars/global.yml)
  - loaded only by the bootstrap and `site.yml` playbooks
  - consumed by
    [roles/java_runtime/tasks/main.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/java_runtime/tasks/main.yml)

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

- core Linux baseline packages are installed by
  [common_baseline/tasks/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/roles/common_baseline/tasks/linux.yml)
  using the `baseline_packages_linux` variable from
  [inventories/dev/group_vars/linux.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/ansible-azure-enterprise/inventories/dev/group_vars/linux.yml)
  and the matching `qa` and `prod` files
- `chrony` with the correct service name selected for the Linux family
- `rsyslog`
- audit package with the correct distro package name (`audit` or `auditd`)
- `curl`
- `jq`
- `unzip`
- `openssl`
- `ca-certificates`
- `python3-pip`
- DNS utilities with the correct distro package name (`bind-utils` or `dnsutils`)
- netcat utilities with the correct distro package name (`nmap-ncat` or `netcat-openbsd`)
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
