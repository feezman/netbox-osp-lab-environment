# NetBox and NetBox-OSP Lab Architecture

## 1. Purpose

This document describes the architecture of the NetBox and NetBox-OSP lab environment, including the components, their responsibilities, and how they interact.

## 2. Architecture Overview

The lab runs on Ubuntu 24.04 LTS inside a virtual machine hosted on Windows. Vagrant manages the VM configuration, and VirtualBox provides virtualisation.

The browser accesses NetBox at http://localhost:8080. Nginx receives HTTP requests and forwards application traffic to Gunicorn, which runs the NetBox Django application.

NetBox uses PostgreSQL for persistent data storage and Redis for caching and task queue support. The NetBox RQ worker processes background jobs. NetBox-OSP extends NetBox with outside-plant fibre infrastructure capabilities.

## 3. Logical Architecture

```text
Windows Host
└── Vagrant + VirtualBox
    └── Ubuntu 24.04 LTS VM
        ├── Nginx (guest port 80)
        │   └── Gunicorn (127.0.0.1:8001)
        │       └── NetBox Django Application
        │           ├── NetBox Core
        │           └── NetBox-OSP Plugin
        ├── PostgreSQL 17
        │   └── Persistent application database
        ├── Redis 7
        │   └── Cache and task queue support
        └── NetBox RQ
            └── Background job processing
```

## 4. Component Responsibilities

### 4.1 Windows Host
The Windows computer provides the physical computing environment. It runs Vagrant and VirtualBox and provides browser access to the lab.

### 4.2 Vagrant and VirtualBox
Vagrant manages the virtual machine configuration, while VirtualBox runs the Ubuntu virtual machine. The VM has 4 virtual CPUs, 4 GB RAM, and port forwarding from host TCP port 8080 to guest TCP port 80.

### 4.3 Ubuntu Server
Ubuntu 24.04 LTS hosts the application, database, cache, reverse proxy, and background worker services.

### 4.4 Nginx
Nginx acts as the HTTP reverse proxy and web entry point. It receives requests on guest port 80, forwards application traffic to Gunicorn at 127.0.0.1:8001, and serves NetBox static files. The lab uses HTTP without TLS and is intended for local testing, not production deployment.

### 4.5 Gunicorn
Gunicorn is the WSGI application server for NetBox. It runs the Django application and handles requests forwarded by Nginx.

### 4.6 NetBox Core
NetBox provides the main web application and data model for documenting supported network infrastructure, including sites, locations, devices, and cables. Installed version: 4.6.9.

### 4.7 NetBox-OSP Plugin
NetBox-OSP extends NetBox with additional outside-plant fibre infrastructure capabilities. Installed version: 0.3.8.

Plugin registration, database migrations, menu visibility, and access to the Splice Closures page were verified. End-to-end fibre tracing has not yet been validated and belongs to Part Two.

### 4.8 PostgreSQL
PostgreSQL provides persistent relational data storage for NetBox and its plugins. The active database server is PostgreSQL 17.11, and the application database is named netbox.

### 4.9 Redis
Redis provides caching and task queue support for NetBox. The installed version is 7.0.15.

### 4.10 NetBox RQ Worker
The netbox-rq service processes background jobs submitted through NetBox's task queue.

## 5. Browser Request Flow

1. The user opens http://localhost:8080 in a browser on the Windows host.
2. VirtualBox forwards the request to port 80 inside Ubuntu.
3. Nginx receives the HTTP request.
4. Nginx forwards application traffic to Gunicorn at 127.0.0.1:8001.
5. Gunicorn passes the request to the NetBox Django application.
6. NetBox processes the request, including applicable NetBox-OSP functionality.
7. The application interacts with PostgreSQL and, as required, Redis.
8. The response returns through Gunicorn and Nginx to the browser.

Background jobs are processed separately by the netbox-rq worker.

## 6. Environment Specifications

| Component | Verified version or configuration |
|---|---|
| Host operating system | Windows |
| Virtualisation | Vagrant and VirtualBox |
| Guest operating system | Ubuntu 24.04.3 LTS |
| NetBox | 4.6.9 |
| NetBox-OSP | 0.3.8 |
| Python | 3.12.3 |
| PostgreSQL | 17.11 |
| Redis | 7.0.15 |
| Nginx | 1.24.0 |
| VM memory | 4 GB |
| VM CPUs | 4 |
| Browser URL | http://localhost:8080 |

## 7. Service Management

The following core services are managed through systemd:

- nginx
- netbox
- netbox-rq
- postgresql
- redis-server

Their status can be checked using:

    for service in nginx netbox netbox-rq postgresql redis-server; do
      printf "%-15s " "$service"
      systemctl is-active "$service"
    done

All five services were verified as active, including after a VM reboot.

## 8. Architecture Limitations

- The environment runs on a single virtual machine and does not provide high availability.
- HTTP is used without TLS and is suitable only for this local lab setup.
- No production performance, penetration, or load testing was performed.
- Automated off-host backups and full VM disaster recovery have not been demonstrated.
- End-to-end fibre route modelling and connectivity tracing have not yet been validated.

## 9. Relationship to Part Two

Part One established and validated the software environment.

Part Two will focus on documenting KASI's actual fibre infrastructure in NetBox and NetBox-OSP. The modelling approach, object hierarchy, naming conventions, and relationships between sites, manholes, cables, splice closures, cabinets, ODFs, and other infrastructure components will be agreed before implementation.

## 10. Conclusion

The architecture separates web access, application processing, persistent data storage, caching, and background task processing into distinct services within one Ubuntu virtual machine.

This design provides a practical lab for evaluating NetBox and NetBox-OSP before applying the tools to KASI's fibre infrastructure documentation requirements.
