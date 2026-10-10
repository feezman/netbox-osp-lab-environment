# NetBox + NetBox-OSP Installation Guide

## 1. Purpose

This document records the installation of NetBox and the NetBox-OSP plugin in a self-hosted Ubuntu virtual machine. It is intended to help another engineer reproduce the lab and understand the key configuration decisions and troubleshooting steps.

This guide describes the lab as built and validated. Package versions and upstream installation instructions can change, so verify compatibility before reproducing it on a new system.

## 2. Lab Specifications

| Component | Configuration |
|---|---|
| Host operating system | Windows |
| Virtualisation | Oracle VirtualBox |
| VM management | Vagrant |
| Guest OS | Ubuntu 24.04 LTS |
| VM memory | 4 GB |
| VM CPUs | 4 |
| NetBox | 4.6.9 |
| NetBox-OSP | 0.3.8 |
| Python | 3.12.3 |
| PostgreSQL | 17.11 |
| Redis | 7.0.15 |
| Nginx | 1.24.0 |
| Application directory | `/opt/netbox` |
| Project documentation | `/opt/projects/netbox-osp-lab-environment` |
| Host browser URL | `http://localhost:8080` |

## 3. Virtual Machine Preparation

The VM was created using Vagrant and VirtualBox. The Vagrant configuration used Ubuntu 24.04, 4 GB RAM, four virtual CPUs, and forwarded guest HTTP port 80 to host port 8080.

Example Vagrantfile:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 4
    vb.name = "NetBox-Lab"
  end
end
```

From the Windows host, the VM can be managed from the directory containing the Vagrantfile:

```bash
vagrant status
vagrant ssh
```

## 4. Operating System Dependencies

The following system packages were installed:

```bash
sudo apt update
sudo apt install -y \
  git python3-pip python3-venv python3-dev \
  build-essential libxml2-dev libxslt1-dev \
  libffi-dev libpq-dev libssl-dev zlib1g-dev
```

Git was used to retrieve the NetBox source. Python virtual environments were used to isolate application dependencies.

## 5. DNS Troubleshooting

During initial setup, DNS resolution failed because the configured DNS server was unreachable from the VM. Connectivity was restored for the active session with:

```bash
sudo resolvectl dns eth0 8.8.8.8
```

This was a runtime fix and may not survive a reboot. For a reproducible deployment, diagnose the VM's DNS configuration and establish a persistent, approved resolver configuration appropriate for the network. Do not assume that this command alone permanently fixes DNS.

## 6. NetBox Source and Python Environment

The NetBox source was cloned into `/opt/netbox`, and version `v4.6.9` was selected.

Verify the checked-out version:

```bash
cd /opt/netbox
git describe --tags --exact-match
```

Expected output:

```text
v4.6.9
```

Create and activate the Python virtual environment and install the project's requirements using the requirements file supplied by the checked-out NetBox release:

```bash
cd /opt/netbox
python3 -m venv venv
source /opt/netbox/venv/bin/activate
pip install -r requirements.txt
```

The virtual environment is located at `/opt/netbox/venv`.

## 7. PostgreSQL Database

PostgreSQL was installed and configured with a database named `netbox` and a database role named `netbox`.

The lab was initially configured with PostgreSQL 16 and subsequently migrated to PostgreSQL 17.11. The active PostgreSQL 17 cluster uses port 5432. The old PostgreSQL 16 cluster was retained as a stopped fallback on port 5433 during validation.

Confirm the installed client version:

```bash
psql --version
```

Confirm the server version:

```bash
sudo -u postgres psql -tAc "SELECT version();"
```

The NetBox database connection settings are maintained in:

```text
/opt/netbox/netbox/netbox/configuration.py
```

**Security:** Database passwords must not be committed to Git. Use a protected local configuration file and a strong, unique password when reproducing the installation.

## 8. Redis

Redis was installed as the cache and task-queue service used by NetBox.

Check service status:

```bash
sudo systemctl status redis-server --no-pager
```

Check Redis responsiveness:

```bash
redis-cli ping
```

Expected response:

```text
PONG
```

The NetBox configuration uses Redis on localhost with separate logical databases for task processing and caching.

## 9. NetBox Configuration

The main configuration file is:

```text
/opt/netbox/netbox/netbox/configuration.py
```

The lab's allowed hosts include localhost and 127.0.0.1 for local access. A generated secret key was configured for Django/NetBox.

Do not copy actual secret values into this repository. Use the configuration template supplied with the checked-out NetBox release and follow its documentation for required settings.

The NetBox upgrade script was run after the initial configuration:

```bash
cd /opt/netbox
sudo ./upgrade.sh
```

The script completed successfully in the lab.

## 10. Gunicorn and systemd

NetBox is served by Gunicorn, managed through the `netbox` systemd service. Background tasks are handled by `netbox-rq`.

During setup, the initial Gunicorn service definition referenced a configuration file at the wrong path. The working service configuration uses:

```text
/opt/netbox/contrib/gunicorn.py
```

The working Gunicorn invocation was:

```bash
/opt/netbox/venv/bin/gunicorn \
  --pid /var/tmp/netbox.pid \
  --pythonpath /opt/netbox/netbox \
  --config /opt/netbox/contrib/gunicorn.py \
  netbox.wsgi
```

After modifying a systemd unit, reload systemd and restart the affected service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart netbox netbox-rq
```

Validate the services:

```bash
systemctl is-active netbox
systemctl is-active netbox-rq
```

The expected result for each service is `active`.

## 11. Nginx Reverse Proxy

Nginx was configured for HTTP-only access within the lab. The site configuration is:

```text
/etc/nginx/sites-available/netbox
```

The default site was disabled and the NetBox site enabled. The configuration proxies requests to Gunicorn on `127.0.0.1:8001` and serves NetBox static files.

Validate and restart Nginx after configuration changes:

```bash
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl is-active nginx
```

The Vagrant forwarded port allows the application to be opened from the host at:

```text
http://localhost:8080
```

This HTTP configuration is for lab use. Do not expose it to an untrusted network without implementing appropriate TLS, access controls, and security hardening.

## 12. NetBox-OSP Installation

The NetBox-OSP package was added to the local requirements file:

```text
/opt/netbox/local_requirements.txt
```

Its content:

```text
netbox-osp
```

The package was installed through the NetBox upgrade process. The plugin was then enabled in `configuration.py`:

```python
PLUGINS = [
    "netbox_osp",
]
```

The plugin was activated by running migrations:

```bash
cd /opt/netbox/netbox
/opt/netbox/venv/bin/python manage.py migrate
```

The lab applied these plugin migrations successfully:

```text
netbox_osp.0001_initial
netbox_osp.0002_locationgeo
netbox_osp.0003_fibretrunk
netbox_osp.0004_trunkbreakout
netbox_osp.0005_fibretrunk_polarity
```

Static files were collected:

```bash
/opt/netbox/venv/bin/python manage.py collectstatic --no-input
```

The plugin package version was verified as `0.3.8`. The NetBox services were restarted:

```bash
sudo systemctl restart netbox netbox-rq
```

Plugin registration was verified using:

```bash
/opt/netbox/venv/bin/python \
  /opt/netbox/netbox/manage.py shell \
  -c "from django.conf import settings; print(settings.PLUGINS)"
```

Expected output included:

```text
['netbox_osp']
```

The OSP navigation appeared in the web interface and OSP pages opened successfully.

## 13. Backup and Recovery Test

A PostgreSQL SQL dump was created under:

```text
/opt/netbox/backups/
```

The post-migration backup was:

```text
netbox_pg17_20261008_132954.sql
```

The dump was restored into a separate temporary database named `netbox_restore_test`. The restored database was accessible and contained 198 public base tables.

After verification, the temporary database was removed:

```bash
sudo -u postgres dropdb netbox_restore_test
```

A successful database restore is an important validation step, but a full recovery procedure should also include application configuration, secret management, file assets, service configuration, and a documented recovery sequence.

## 14. Reboot and Service Validation

After a controlled VM reboot, the following services were confirmed active:

```bash
for service in netbox netbox-rq postgresql redis-server nginx; do
  printf "%-15s " "$service"
  systemctl is-active "$service"
done
```

The dashboard remained accessible from the host browser after the reboot.

## 15. Known Warnings and Limitations

- NetBox emitted a warning that `API_TOKEN_PEPPERS` was not defined. Version 2 API tokens are therefore not enabled. Configure token peppers according to the NetBox documentation if this feature is required.
- A warning about missing documentation static files was observed during initial setup. Investigate it if documentation assets are needed.
- The DNS fix applied during troubleshooting was not confirmed as persistent.
- HTTP is used for local lab access; production TLS and security hardening have not been completed.
- PostgreSQL 16 was retained as a stopped fallback after migrating to PostgreSQL 17. Do not remove it until the final environment is confirmed stable and a recovery plan is in place.

## 16. Reproduction Notes

This guide records the working environment and important commands. Before using it on a clean VM:

1. Verify current NetBox and NetBox-OSP compatibility.
2. Review the official installation instructions for the exact selected release.
3. Use secure, unique credentials and protect generated secret keys.
4. Confirm service paths and configuration files match the checked-out release.
5. Take a database backup before migrations or upgrades.
6. Validate the application, services, reboot behaviour, and recovery process before modelling production infrastructure.

## 17. Related Documentation

- [Project overview](../README.md)
- [Lab architecture](02-lab-architecture.md)
- [Environment specifications](03-environment-specifications.md)
- [Validation and testing](06-validation-and-testing.md)
- [Backup and recovery](07-backup-and-recovery.md)
- [Troubleshooting](08-troubleshooting.md)
- [Lessons learned](09-lessons-learned.md)
