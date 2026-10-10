# NetBox Lab Troubleshooting Guide

## 1. Purpose

This document records the issues encountered while deploying and validating NetBox and NetBox-OSP, their observed symptoms, the resolutions applied, and any remaining limitations.

The guide provides a practical reference for troubleshooting the lab environment.

## 2. DNS Resolution Failure

### Symptom
The Ubuntu VM initially experienced DNS resolution problems, preventing successful resolution of external hostnames.

### Cause
The configured DNS server at 10.18.91.71 was unreachable from the VM.

### Resolution
The runtime DNS configuration was changed to use 8.8.8.8 on interface eth0 with:

    resolvectl dns eth0 8.8.8.8

Internet connectivity was subsequently restored, and hostname resolution worked.

### Remaining consideration
The runtime change was not confirmed to persist after a reboot. If DNS resolution fails again, inspect the active resolver configuration and network settings before applying a fix.

## 3. Gunicorn Service Configuration

### Symptom
The NetBox application service initially referenced an incorrect Gunicorn configuration file path.

### Cause
The service configuration referenced /opt/netbox/gunicorn.py, but the correct configuration file was located at /opt/netbox/contrib/gunicorn.py.

### Resolution
The systemd service configuration was updated to use the correct path:

    /opt/netbox/contrib/gunicorn.py

The service was then restarted and verified.

### Verification
The NetBox service was active, and the application remained accessible through the Nginx reverse proxy.

## 4. PostgreSQL Version and Migration

### Symptom
The lab initially used PostgreSQL 16 before being migrated to PostgreSQL 17.

### Resolution
PostgreSQL 17.11 became the active database server, while the older PostgreSQL 16 cluster was retained as a stopped fallback on port 5433.

### Operational consideration
Do not remove the older cluster until its contents and the need for fallback have been reviewed. Confirm which cluster is active before performing database administration or recovery operations.

## 5. NetBox-OSP Plugin Registration

### Symptom
After installing NetBox-OSP, the plugin needed to be enabled and its database migrations applied.

### Resolution
The plugin was registered in the NetBox configuration:

    PLUGINS = [
        "netbox_osp",
    ]

The plugin migrations were applied, and static files were collected.

### Verification
Plugin registration was confirmed through Django settings. The OSP menu appeared in the web interface, and the Splice Closures page opened successfully.

### Limitation
Successful page access confirms that the plugin is loaded, but does not prove that all fibre-modelling or end-to-end connectivity features work correctly. Those tests are planned for Part Two.

## 6. GitHub SSH Authentication

### Symptom
Git operations initially encountered a public-key authentication failure when connecting to GitHub.

### Resolution
An Ed25519 SSH key was generated, and the public key was configured for GitHub. SSH authentication was tested successfully, after which `git push` worked.

### Operational consideration
Keep the private SSH key secure and never commit it to the repository. Only the public key should be registered with GitHub.

## 7. Documentation and Terminal Input Issues

### Symptom
Long terminal pastes occasionally resulted in incomplete commands, missing Markdown code fences, joined headings, or shell prompts waiting for additional input.

### Cause
Long multi-line commands and heredocs were sometimes truncated or pasted incorrectly. Text intended as documentation was occasionally interpreted as shell commands.

### Resolution
The documentation workflow was changed to use shorter text files, inspect them before use, and append verified content in separate steps.

When a heredoc or shell command remains incomplete, press Ctrl+C to cancel it and return to a normal prompt before running another command.

### Prevention
- Keep terminal input blocks short.
- Ensure heredoc closing markers appear on their own line.
- Inspect Markdown headings and code fences before committing.
- Run git diff --check and review staged changes.
- Keep completed documentation in Git commits so earlier versions can be recovered.

## 8. General Diagnostic Commands

Check the status of the core services:

    for service in nginx netbox netbox-rq postgresql redis-server; do
      printf "%-15s " "$service"
      systemctl is-active "$service"
    done

Check the NetBox application service logs:

    sudo journalctl -u netbox -n 50 --no-pager

Check the Nginx service logs:

    sudo journalctl -u nginx -n 50 --no-pager

Check listening TCP ports:

    sudo ss -lntp

These commands provide starting points for diagnosis. Review the actual output before deciding on a corrective action.

## 9. Conclusion

The lab issues documented here were resolved sufficiently to achieve a working NetBox and NetBox-OSP environment. The DNS fix's persistence remains unconfirmed, and the older PostgreSQL cluster remains available as a stopped fallback pending review.

Plugin page access has been verified, but end-to-end fibre connectivity testing remains part of Part Two.