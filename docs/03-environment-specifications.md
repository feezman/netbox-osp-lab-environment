# NetBox Lab Environment Specifications

## 1. Purpose

This document records the verified hardware resources, software versions, network settings, service endpoints, and important filesystem paths used by the NetBox and NetBox-OSP lab.

It serves as a technical reference for maintaining, troubleshooting, and reproducing the lab environment.

## 2. Virtual Machine Specifications

| Parameter | Specification |
|---|---|
| Host operating system | Windows |
| Virtualisation platform | Oracle VirtualBox |
| VM management | Vagrant |
| Vagrant box | bento/ubuntu-24.04 |
| Guest operating system | Ubuntu 24.04.3 LTS |
| VM name | NetBox-Lab |
| Allocated memory | 4 GB |
| Allocated CPUs | 4 |
| Host web port | TCP 8080 |
| Guest web port | TCP 80 |
| Browser URL | http://localhost:8080 |

## 3. Application and Software Versions

| Component | Verified version | Purpose |
|---|---|---|
| NetBox | 4.6.9 | Network infrastructure documentation |
| NetBox-OSP | 0.3.8 | Outside-plant fibre infrastructure functionality |
| Python | 3.12.3 | Application runtime |
| PostgreSQL | 17.11 | Persistent database |
| Redis | 7.0.15 | Caching and task queue support |
| Nginx | 1.24.0 | HTTP reverse proxy and static file serving |
| Git | 2.43.0 | Source control and documentation history |

## 4. Network Ports and Access

| Item | Configuration |
|---|---|
| Browser URL | http://localhost:8080 |
| Windows host port | TCP 8080 |
| Ubuntu guest web port | TCP 80 |
| Nginx upstream | 127.0.0.1:8001 |
| Gunicorn | Bound to the local loopback address |
| PostgreSQL | TCP 5432 |
| Redis | TCP 6379 |

Vagrant forwards host port 8080 to guest port 80. Nginx receives browser requests and forwards application traffic to Gunicorn on the Ubuntu VM.

PostgreSQL and Redis are local lab services. Their ports should not be exposed publicly.

## 5. Important Filesystem Paths

| Path | Purpose |
|---|---|
| /opt/netbox | NetBox installation directory |
| /opt/netbox/netbox | NetBox application source and management files |
| /opt/netbox/venv | Python virtual environment |
| /opt/netbox/netbox/netbox/configuration.py | NetBox application configuration |
| /opt/netbox/contrib/gunicorn.py | Gunicorn configuration |
| /etc/nginx/sites-available/netbox | Nginx site configuration |
| /opt/netbox/backups | Local database backup files |
| /opt/projects/netbox-osp-lab-environment | Git documentation repository |


## 6. Service Management

The following services are managed by systemd:

| Service | Responsibility |
|---|---|
| nginx | HTTP reverse proxy and static file serving |
| netbox | NetBox application service |
| netbox-rq | Background task processing |
| postgresql | Persistent database service |
| redis-server | Cache and task queue support |

Check service status with:

    for service in nginx netbox netbox-rq postgresql redis-server; do
      printf "%-15s " "$service"
      systemctl is-active "$service"
    done

All five services were verified as active during the lab validation, including after a VM reboot.

## 7. Backup and Recovery Reference

Database backups are stored locally under /opt/netbox/backups.

A SQL dump was restored successfully into a separate temporary database, and 198 public base tables were verified. The temporary database was subsequently removed.

Local backups alone do not provide protection against loss of the virtual machine or its host. An off-host backup and complete VM recovery procedure have not yet been demonstrated.

## 8. Security and Operational Limitations

- The lab uses HTTP without TLS and is intended for local testing.
- Database and Redis services should remain restricted to the local lab environment.
- Credentials, secret keys, database dumps, and other sensitive files must not be committed to Git.
- The database backup directory is local to the VM.
- No production security, performance, or load assessment has been completed.
- The lab has not been configured for high availability.

## 9. Conclusion

This document records the main software versions, VM resources, network endpoints, filesystem paths, and operational constraints of the NetBox and NetBox-OSP lab.

These specifications provide a reference for troubleshooting, maintaining, and reproducing the lab environment before it is used to document KASI fibre infrastructure in Part Two.
