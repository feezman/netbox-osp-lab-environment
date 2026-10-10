# Validation and Testing Report

## 1. Purpose

This document records the validation activities performed after deploying NetBox and NetBox-OSP in the lab environment.

## 2. Test Environment

| Component | Version / Configuration |
|---|---|
| Operating system | Ubuntu 24.04 LTS |
| NetBox | 4.6.9 |
| NetBox-OSP | 0.3.8 |
| Python | 3.12.3 |
| PostgreSQL | 17.11 |
| Redis | 7.0.15 |
| Nginx | 1.24.0 |
| Browser URL | `http://localhost:8080` |

## 3. Test Results

| ID | Test | Evidence | Result |
|---|---|---|---|
| VAL-01 | NetBox dashboard accessible | Dashboard opened in browser | PASS |
| VAL-02 | KASI site visible | KASI site shown in NetBox | PASS |
| VAL-03 | OSP navigation available | OSP menu visible | PASS |
| VAL-04 | OSP page accessible | Splice Closures page opened | PASS |
| VAL-05 | NetBox service health | `systemctl is-active netbox` returned `active` | PASS |
| VAL-06 | Background worker health | `systemctl is-active netbox-rq` returned `active` | PASS |
| VAL-07 | PostgreSQL health and version | PostgreSQL 17.11 reported; service active | PASS |
| VAL-08 | Redis service health | Redis service reported active | PASS |
| VAL-09 | Nginx service health | Nginx service reported active | PASS |
| VAL-10 | Reboot persistence | Services and dashboard remained available after reboot | PASS |
| VAL-11 | Database backup restoration | SQL dump restored into a separate temporary database | PASS |
| VAL-12 | Restored table count | 198 public base tables found in restored database | PASS |
| VAL-13 | Temporary database cleanup | `netbox_restore_test` removed after testing | PASS |

## 4. Service Health Command

The following command was used to check the five core services:

```bash
for service in netbox netbox-rq postgresql redis-server nginx; do
  printf "%-15s " "$service"
  systemctl is-active "$service"
done
```

All five services returned `active` during validation, including after the VM reboot.

## 5. NetBox-OSP Plugin Verification

Plugin registration was checked through Django:

```bash
/opt/netbox/venv/bin/python \
  /opt/netbox/netbox/manage.py shell \
  -c "from django.conf import settings; print(settings.PLUGINS)"
```

The output included:

```text
['netbox_osp']
```

The OSP menu appeared in the web interface, and the Splice Closures page opened successfully.

## 6. Backup Restoration Verification

The SQL dump was restored into a separate database named `netbox_restore_test`. The database was accessible and contained 198 public base tables.

The temporary database was then removed. The working `netbox` database was not used as the restoration target.

This test validates database dump restoration. It does not constitute a complete disaster-recovery exercise for all application configuration and system files.

## 7. Limitations

- OSP pages were tested for accessibility; end-to-end fibre tracing and infrastructure data validation belong to Part Two.
- The lab uses HTTP for local testing.
- No production load, performance, or security assessment was performed.
- The database restoration test did not include a full rebuild of the VM from scratch.

## 8. Conclusion

The lab passed the recorded installation and operational checks. NetBox and NetBox-OSP were accessible, the core services remained active after a reboot, and the database dump was successfully restored into an isolated test database.

Part One is validated as a working lab environment. Infrastructure modelling and functional fibre-connectivity tests will be documented separately in Part Two.
