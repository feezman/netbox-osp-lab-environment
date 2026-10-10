# NetBox Lab Backup and Recovery Guide

## 1. Purpose

This document describes the database backup files created during the NetBox and NetBox-OSP lab deployment, the restoration test performed, and the limitations of the recovery process.

The objective is to provide a repeatable reference for protecting the lab's NetBox database and validating that a database dump can be restored.

## 2. Backup Location

The database backup files are stored locally in:

    /opt/netbox/backups/

The verified backup files are:

| Filename | Approximate size | Recorded date |
|---|---:|---|
| netbox_20261007_235554.sql | 809 KB | 7 October 2026 |
| netbox_pg17_20261008_132954.sql | 809 KB | 8 October 2026 |

The second file is the PostgreSQL 17 backup used as the primary reference for the restoration procedure documented here.

These files are stored on the lab VM. They should not be committed to the Git repository.

## 3. Backup File Validation

The PostgreSQL 17 dump was inspected, and its ending included the expected database dump completion marker.

The file was also used in a successful restoration test into a separate temporary database.

File existence and size are useful initial checks, but do not alone prove that a backup can be restored. Periodic restoration tests provide stronger evidence of backup usability.

## 4. Database Restoration Test

A restoration test was performed using the PostgreSQL 17 backup. The dump was restored into a separate temporary database named `netbox_restore_test`, leaving the working `netbox` database untouched.

The restoration command used was:

    sudo -u postgres psql --dbname=netbox_restore_test --file=/opt/netbox/backups/netbox_pg17_20261008_132954.sql --single-transaction --set ON_ERROR_STOP=on

The test database was then queried to verify that the restoration had completed.

## 5. Restoration Verification Results

| Check | Recorded result |
|---|---|
| Backup source | netbox_pg17_20261008_132954.sql |
| Restoration target | netbox_restore_test |
| Database accessible after restoration | Yes |
| Public base tables found | 198 |
| Original netbox database used as target | No |
| Temporary test database removed after verification | Yes |

The restored database was confirmed to be accessible, and 198 public base tables were found. The temporary database was subsequently dropped after the test.

This provides evidence that the database dump could be restored into an isolated database. It does not prove that a complete system recovery, including the VM, application configuration, services, and external dependencies, has been tested.## 6. Recommended Backup Practices

The following practices are recommended for maintaining the lab:

- Create a fresh database dump before significant NetBox or plugin changes.
- Use timestamped filenames to distinguish backup versions.
- Check that backup commands complete successfully and that dump files are non-empty.
- Perform periodic restoration tests using a separate temporary database.
- Keep an additional backup copy outside the VM to protect against host or VM failure.
- Protect backup files because they may contain infrastructure inventory and other sensitive information.
- Never commit SQL dumps, credentials, or secret keys to the Git repository.

## 7. Recovery Considerations and Limitations

The completed restoration test validates the database dump restoration process only.

A full recovery procedure would also need to address:

- Rebuilding or restoring the Ubuntu virtual machine.
- Restoring the NetBox configuration and any required secret values securely.
- Reinstalling or restoring compatible NetBox and NetBox-OSP versions.
- Restoring Nginx and Gunicorn service configuration.
- Restoring the database and verifying application access.
- Confirming that all required services start correctly after recovery.

An off-host backup and a full virtual machine disaster-recovery exercise have not yet been demonstrated in this lab.

## 8. Conclusion

The PostgreSQL backup was successfully restored into an isolated temporary database, and 198 public base tables were verified. The temporary database was removed after the test.

This provides evidence that the database dump was restorable. Further work is required to establish and test a complete disaster-recovery procedure for the entire NetBox lab.