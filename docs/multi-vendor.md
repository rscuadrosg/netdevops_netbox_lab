# Multi-vendor design

This lab starts with a single vendor (Nokia SR Linux), but the automation is
laid out so more vendors can be added without rewriting what already works.

## The principle

**NetBox stores vendor-neutral intent. The platform decides how it is applied.**

- The network data (devices, interfaces, IPs, ASNs, cables) lives in NetBox and
  is the same whatever the vendor.
- Every device in NetBox has a **platform** (for example `srlinux`).
- The dynamic inventory turns each platform into an Ansible group
  (`platforms_srlinux`), and that group decides three things:
  how to connect, how to push configuration and which templates to render.

Adding a vendor means adding files for its platform. The data model and the
existing platforms stay untouched.

## Two automation patterns

Not every vendor is automated the same way.

| | Template-based | API-managed |
|---|---|---|
| **Examples** | Nokia SR Linux, Arista EOS, Cisco IOS-XE / NX-OS, Juniper Junos | Cisco Meraki, Palo Alto PAN-OS / Panorama |
| **Who holds the config** | The device itself | A controller or cloud dashboard |
| **How Ansible works** | Renders Jinja2 templates into device config and pushes it | Calls vendor modules that create objects through the API |
| **Templates** | Yes, one folder per platform | No |
| **Ansible connection** | To the device (`httpapi`, `network_cli`, `netconf`) | `local`: the control node calls the API |

## Where each piece lives

```
inventory/
├── netbox.yml                    # dynamic inventory, groups devices by platform
└── group_vars/
    └── platforms_<slug>.yml      # HOW TO CONNECT to that platform
playbooks/
├── fabric_configure.yml          # single entry point, dispatches by platform
└── platforms/
    └── <slug>.yml                # HOW TO APPLY config on that platform
templates/
└── <slug>/                       # WHAT TO SEND (template-based platforms only)
    ├── interfaces.j2
    └── bgp.j2
```

| Path | Answers | Why it is separate per platform |
|---|---|---|
| `inventory/group_vars/platforms_<slug>.yml` | How do I connect? | Each vendor uses a different connection plugin, port and credentials. Ansible applies the file automatically to every device in that platform group. |
| `playbooks/platforms/<slug>.yml` | How do I apply config? | Module names and push methods differ (`nokia.srlinux.config`, `arista.eos.eos_config`, `cisco.meraki.*`...). |
| `templates/<slug>/` | What config do I send? | Same intent, different syntax. API-managed platforms don't need this folder. |
| NetBox (via `data/fabric.yml`) | What should the network look like? | It is **not** per platform: one source of truth for every vendor. |

`fabric_configure.yml` stays the same for every vendor: for each device it
includes `playbooks/platforms/<platform>.yml`, so adding a vendor never means
editing the shared playbook.

## Platform catalog

`<slug>` is the platform slug in NetBox and must match the folder and file
names above.

| Vendor / OS | Platform slug | Pattern | Ansible collection | Connection | Status |
|---|---|---|---|---|---|
| Nokia SR Linux | `srlinux` | Template | `nokia.srlinux` | `httpapi` (JSON-RPC) | Implemented |
| Arista EOS | `eos` | Template | `arista.eos` | `httpapi` (eAPI) | Planned |
| Cisco IOS-XE | `ios` | Template | `cisco.ios` | `network_cli` | Planned |
| Cisco NX-OS | `nxos` | Template | `cisco.nxos` | `httpapi` (NX-API) | Planned |
| Juniper Junos | `junos` | Template | `junipernetworks.junos` | `netconf` | Planned |
| Palo Alto PAN-OS | `panos` | API | `paloaltonetworks.panos` | `local` | Planned |
| Cisco Meraki | `meraki` | API | `cisco.meraki` | `local` | Planned |

## Adding a vendor

1. Add the platform to `data/fabric.yml` and run `playbooks/netbox_populate.yml`.
2. Add the collection to `collections/requirements.yml`.
3. Create `inventory/group_vars/platforms_<slug>.yml` with the connection settings.
   Secrets (passwords, API keys) come from environment variables, never from the file.
4. Create `playbooks/platforms/<slug>.yml` with the tasks that apply config.
5. Template-based only: create `templates/<slug>/` with the Jinja2 templates.
6. Optional: add a lab node to `lab.clab.yml` if the vendor ships a container
   image (Arista cEOS and Juniper cRPD do; Cisco and Palo Alto need licensed
   images; Meraki is cloud-only).
