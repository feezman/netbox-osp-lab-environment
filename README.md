# NetBox + NetBox-OSP Lab Environment

## 1. Project Overview

This project documents the deployment, configuration, validation, and operational readiness of a self-hosted network infrastructure management lab using NetBox and NetBox-OSP.

The lab is designed to support practical learning and experimentation with network inventory, data centre infrastructure, outside-plant (OSP) fibre records, and physical connectivity modelling.

The project is divided into two parts:

- **Part One — Building the Lab Environment:** Deploy and validate the application stack and document the installation process.
- **Part Two — KASI Infrastructure Modelling:** Model KASI's data centre and fibre infrastructure inside NetBox and NetBox-OSP. This phase will be documented separately according to the agreed implementation workflow.

## Documentation Index

| Document | Description |
|---|---|
| [Lab Architecture](docs/02-lab-architecture.md) | Application components, service relationships, and lab architecture. |
| [Environment Specifications](docs/03-environment-specifications.md) | Operating system, software versions, and VM configuration. |
| [Installation Guide](docs/04-installation-guide.md) | Installation and configuration procedures for the lab. |
| [Validation and Testing](docs/06-validation-and-testing.md) | Validation checks and recorded test results. |
| [Backup and Recovery](docs/07-backup-and-recovery.md) | Database backup, restoration, and recovery verification. |
| [Troubleshooting](docs/08-troubleshooting.md) | Problems encountered, diagnostic steps, and resolutions. |
| [Lessons Learned](docs/09-lessons-learned.md) | Practical lessons and recommendations from the implementation.

## 2. Project Objectives

- Deploy NetBox in a self-hosted Ubuntu virtual machine.
- Integrate the NetBox-OSP plugin.
- Configure and validate the supporting database, cache, web server, and background worker.
- Test service persistence following a VM reboot.
- Validate database backup restoration in a separate temporary database.
- Document installation steps, configuration decisions, troubleshooting, and lessons learned.
- Establish a foundation for later fibre infrastructure modelling.

## 3. Lab Environment

| Component | Installed Version / Configuration |
|---|---|
| Operating system | Ubuntu 24.04 LTS |
| Virtualisation | Oracle VirtualBox |
| VM management | Vagrant |
| VM memory | 4 GB |
| VM CPUs | 4 |
| NetBox | 4.6.9 |
| NetBox-OSP | 0.3.8 |
| Python | 3.12.3 |
| PostgreSQL | 17.11 |
| Redis | 7.0.15 |
| Nginx | 1.24.0 |
| Git | 2.43.0 |
| Browser access | http://localhost:8080 |

Versions above reflect the lab at the time of validation. Recheck them before reproducing the installation.

## 4. Architecture

```text
Windows Host
└── Vagrant + VirtualBox
    └── Ubuntu 24.04 LTS VM
        ├── Nginx (HTTP reverse proxy, port 80)
        │   └── Gunicorn (NetBox application, port 8001)
        │       ├── NetBox Core
        │       └── NetBox-OSP Plugin
        ├── NetBox RQ (background worker)
        ├── PostgreSQL 17 (database)
        └── Redis 7 (cache and task queue support)

```

Nginx exposes the lab web interface through the host's forwarded port. PostgreSQL stores application data, while Redis supports the background task infrastructure.

## 5. Validation Summary

The following checks were completed during Part One:

- NetBox dashboard accessible through the browser.
- NetBox-OSP visible in the web interface.
- OSP pages opened successfully.
- NetBox and NetBox RQ services active.
- PostgreSQL, Redis, and Nginx services active.
- Services remained active following a VM reboot.
- PostgreSQL dump restored into a separate temporary database.
- Restored database contained 198 public base tables.
- Temporary restore database removed after testing.

The restoration test provides evidence that the SQL backup is usable. It does not replace periodic backup scheduling or a full application-level recovery drill.

## 6. Repository Structure

```text
netbox-osp-lab-environment/
├── README.md
├── docs/
├── screenshots/
│   └── validation-evidence/
├── scripts/
├── .gitignore
└── LICENSE
```

Detailed installation procedures, configuration notes, test evidence, troubleshooting records, and lessons learned will be maintained under `docs/`.

## 7. Project Scope

### Part One — Lab Environment

Included:

- VM and operating system preparation
- NetBox installation
- PostgreSQL and Redis configuration
- Nginx and systemd service configuration
- NetBox-OSP installation and activation
- Service, reboot, and backup restoration validation
- Technical documentation

### Part Two — KASI Infrastructure

Planned as a separate implementation phase. It will cover the modelling of KASI's data centre and fibre infrastructure, including relevant locations, racks, ODFs, fibre cables, manholes, splice closures, strands, and connectivity.

Detailed scope and implementation sequence will be defined before Part Two begins.

## 8. Security Notes

- Never commit application secret keys, passwords, tokens, or private configuration.
- Do not commit database backups or unredacted configuration files.
- This lab currently uses HTTP for local testing; it is not configured as a production-hardened deployment.
- Review access controls, TLS, firewall rules, backup retention, and upgrade procedures before any production use.

## 9. Current Status

**Part One — Lab installation and validation: completed.**

Documentation is being developed as a dedicated Git deliverable. Part Two will begin after its infrastructure modelling workflow has been agreed.

## 10. Author and Learning Outcomes

This project demonstrates practical experience with Linux administration, virtualisation, application deployment, PostgreSQL, Redis, reverse proxy configuration, Git, service troubleshooting, backup recovery testing, and network infrastructure management tooling.
## 11. Health Check

A read-only health-check script is provided to inspect the status of the core lab services.

Run it from the repository root:

    ./scripts/health-check.sh

The script checks Nginx, NetBox, NetBox RQ, PostgreSQL, and Redis. It reports each service as PASS or FAIL and returns a non-zero exit status if any service is not active.

The check validates service state only; it does not test HTTP response, database queries, or end-to-end NetBox-OSP workflows.
