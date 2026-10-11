# NetBox-OSP Lab — Lessons Learned

## 1. Purpose

This document records the key technical lessons, challenges, solutions, and recommendations learned while building the NetBox and NetBox-OSP laboratory environment on Ubuntu 24.04 LTS.

The objective is to preserve practical knowledge for future maintenance, troubleshooting, documentation, and the planned modelling of Kasi Cloud's fibre infrastructure.

## 2. Plan the Environment Before Installation

### Lesson learned

A structured environment makes installation and troubleshooting easier. The lab required coordination between the operating system, Python environment, NetBox application, PostgreSQL, Redis, Gunicorn, Nginx, and the NetBox-OSP plugin.

### Key takeaways

- Define the lab architecture before installing individual components.
- Record software versions and installation paths.
- Understand the role of each service and its dependencies.
- Separate application configuration, database storage, and reverse-proxy configuration.
- Keep installation notes alongside the project rather than relying on terminal history.

### Recommendation

Maintain an environment specification and installation guide so that the lab can be rebuilt consistently.
## 3. DNS and Network Troubleshooting

### Lesson learned

The lab initially experienced DNS resolution failures because the configured DNS resolver at `10.18.91.71` was unreachable. This prevented normal domain-name resolution even though the underlying network configuration was otherwise usable.

### Resolution

Changing the DNS resolver for the `eth0` interface to `8.8.8.8` using `resolvectl` restored name resolution.

Command used:

    resolvectl dns eth0 8.8.8.8

### Key takeaways

- Test IP connectivity separately from DNS resolution.
- Use `resolvectl status` to inspect DNS settings.
- Use `getent hosts github.com` to test name resolution.
- Confirm whether a DNS change is temporary or persistent.
- Avoid assuming that successful ping by IP means DNS is working.

### Recommendation

Document the intended DNS configuration and verify that it survives a VM reboot. The persistence of the lab's DNS change has not yet been confirmed.
## 4. Gunicorn and Service Management

### Lesson learned

NetBox requires its application server and supporting services to be configured correctly. During the lab setup, the Gunicorn service referenced an incorrect configuration-file path.

The incorrect path was `/opt/netbox/gunicorn.py`. The working configuration file was located at `/opt/netbox/contrib/gunicorn.py`.

### Resolution

The Gunicorn systemd service configuration was updated to reference the correct file. The service was then validated to confirm that NetBox could start successfully.

### Key takeaways

- Verify executable and configuration-file paths before starting a service.
- Use `systemctl status` to inspect service state.
- Use `journalctl -u netbox` to investigate NetBox service errors.
- Validate services after changing systemd unit files.
- Test the application after a reboot, not only immediately after installation.

### Recommendation

Document service names, configuration paths, listening ports, and dependencies. After changing a systemd unit, reload the systemd configuration and restart the affected service only when appropriate.
## 5. PostgreSQL and Database Management

### Lesson learned

The lab had multiple PostgreSQL versions installed. PostgreSQL 17.11 was used for the active NetBox database, while the older PostgreSQL 16 cluster was retained in a stopped state on port 5433 as a fallback.

This experience highlighted the importance of identifying the active database cluster before making configuration changes.

### Key takeaways

- Check the PostgreSQL version and active cluster before troubleshooting.
- Confirm which port the application uses to connect to the database.
- Avoid deleting an older cluster until the newer installation has been validated.
- Keep database credentials out of Git and public documentation.
- Test database backups by restoring them to a separate temporary database.

### Recovery validation

A PostgreSQL backup was restored into a temporary database named `netbox_restore_test`. The restored database was verified, and 198 public base tables were identified. The temporary database was subsequently removed.

This confirmed that the SQL backup could be restored and its tables inspected. It did not constitute a complete virtual-machine disaster-recovery test.

### Recommendation

Maintain regular database backups, document the active PostgreSQL cluster, and periodically perform controlled restore tests.
## 6. NetBox-OSP Plugin Integration

### Lesson learned

Installing a NetBox plugin involves more than making its Python package available. The plugin must be enabled in NetBox configuration, its database migrations must be applied, and its static assets must be collected where required.

### Validation performed

- Enabled `netbox_osp` in the NetBox `PLUGINS` configuration.
- Applied the plugin database migrations through `0005_fibretrunk_polarity`.
- Ran the static asset collection command.
- Verified that Django registered the plugin.
- Confirmed that the OSP menu appeared and the Splice Closures page opened.

### Key takeaways

- Follow the plugin's compatibility and installation requirements.
- Back up the database before significant plugin or schema changes.
- Apply migrations and restart the relevant services when required.
- Validate the plugin through both application registration and its user interface.
- Distinguish successful installation from successful end-to-end workflow testing.

### Recommendation

Before using the plugin to model live infrastructure, validate the complete workflow for fibre cables, routes, splice closures, and related network assets. Detailed Kasi infrastructure modelling and end-to-end tracing remain part of Part Two.
## 7. Git and Version Control

### Lesson learned

Using Git to manage the lab documentation provides a traceable history of installation decisions, configuration guidance, troubleshooting steps, and validation results.

The project uses a dedicated repository at `/opt/projects/netbox-osp-lab-environment`, with completed documentation committed to the `main` branch.

### Key takeaways

- Use descriptive commit messages that explain each change.
- Review staged changes before committing.
- Run `git diff --check` to identify whitespace problems.
- Check `git status --short` after each commit.
- Keep database dumps, secrets, private SSH keys, and other sensitive files out of the repository.
- Use `.gitignore` to exclude generated files and sensitive artifacts.

### Recommendation

Commit small, logically related changes and verify that the working tree is clean before starting the next documentation task. Never commit application credentials or private SSH keys.
## 8. Overall Lessons and Recommendations

The NetBox-OSP lab demonstrates the importance of structured installation, configuration management, service validation, database protection, and clear technical documentation.

The following practices should guide future development:

1. **Validate incrementally:** Test each component before proceeding to the next.
2. **Document actual results:** Record verified configurations and distinguish completed tests from pending work.
3. **Protect data:** Maintain database backups and perform controlled restore tests.
4. **Manage changes carefully:** Use Git commits to preserve a traceable history.
5. **Verify after reboot:** Confirm that the application and supporting services start correctly without manual intervention.
6. **Test complete workflows:** Confirm that plugin pages open and that infrastructure modelling and fibre-tracing operations work as intended.
7. **Plan the next phase:** Define the Kasi infrastructure modelling structure before creating detailed objects in NetBox.

### Outstanding items

- Confirm that the DNS configuration persists after a VM reboot.
- Retain the older PostgreSQL cluster until the fallback requirement has been reviewed.
- Complete end-to-end NetBox-OSP fibre-infrastructure modelling and tracing in Part Two.
- Continue validating backup and recovery procedures as the lab evolves.

## 9. Conclusion

The lab has established a working NetBox and NetBox-OSP environment with supporting services, documented installation procedures, validated plugin registration, and a tested PostgreSQL backup restoration.

The principal lesson is that a successful installation is only the foundation. Reliable operation also requires repeatable configuration, secure data handling, documented troubleshooting, and validation of the actual infrastructure-management workflows.
