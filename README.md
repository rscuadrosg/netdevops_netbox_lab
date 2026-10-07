# netdevops_netbox_lab
[![Lint](https://github.com/rscuadrosg/netdevops_netbox_lab/actions/workflows/lint.yml/badge.svg)](https://github.com/rscuadrosg/netdevops_netbox_lab/actions/workflows/lint.yml)

NetDevOps lab where **NetBox is the source of truth** and **Ansible** builds
the network from it: a Nokia SR Linux spine-leaf fabric running in
**Containerlab**, developed in **GitHub Codespaces**.

> Work in progress. A full guide with screenshots comes when the lab is finished.

## How it works

```
data/fabric.yml ──► Ansible ──► NetBox (source of truth: devices, IPs, ASNs, cables)
                                   │
                                   ▼  dynamic inventory
                                Ansible ──► Containerlab fabric (1 spine + 2 leaf)
```

1. The intended network is written as code in `data/fabric.yml`.
2. `playbooks/netbox_populate.yml` loads it into NetBox.
3. Ansible's dynamic inventory reads devices, IPs and ASNs back from NetBox.
4. Ansible renders per-platform templates and configures the routers.

## Multi-vendor by design

NetBox holds vendor-neutral data; each device's **platform** decides how it is
configured. Template-based vendors (Nokia, Arista, Cisco, Juniper) get Jinja2
templates, API-managed vendors (Meraki, Palo Alto) use their API collections.
Adding a vendor means adding files for its platform, nothing else changes.

See [docs/multi-vendor.md](docs/multi-vendor.md) for the layout, the two
patterns and how to add a vendor.

## Repository layout

| Path | Purpose |
|---|---|
| `.devcontainer/` | Codespaces environment: Docker, Containerlab, Ansible |
| `data/fabric.yml` | Source of truth as code: sites, devices, IPs, ASNs, cables |
| `inventory/` | NetBox dynamic inventory and per-platform connection settings |
| `playbooks/` | Automation entry points |
| `templates/` | Per-platform Jinja2 config templates |
| `lab.clab.yml` | Containerlab topology |
| `scripts/netbox-up.sh` | Starts NetBox with netbox-docker |
| `docs/` | Design notes |
