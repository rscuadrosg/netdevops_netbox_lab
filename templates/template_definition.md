# Configuration templates

Jinja2 templates that turn NetBox data into device configuration.

## One template per platform and feature

Templates are organized by **platform** (folder) and **feature** (file), never
by device or by site:

```
templates/
├── srlinux/            # Nokia SR Linux
│   ├── interfaces.j2   # interfaces, subinterfaces, IPv4 addresses
│   └── bgp.j2          # routing policy and eBGP underlay
└── <platform>/         # one folder per vendor platform (see docs/multi-vendor.md)
```

The same template renders a different config for every device, because each
device fills it with its own data from NetBox:

```
templates/srlinux/interfaces.j2
        ├──► spine1: ethernet-1/1, ethernet-1/2, system0
        ├──► leaf1:  ethernet-1/49, system0
        └──► leaf2:  ethernet-1/49, system0
```

| Change | Touch a template? |
|---|---|
| Add a device, change an IP or an ASN | No, edit `data/fabric.yml` |
| Add a site | No, add its data (see below) |
| Configure a new feature (VLANs, NTP...) | Yes, add `templates/<platform>/<feature>.j2` |
| Add a vendor | Yes, add `templates/<platform>/` |

## Templates hold syntax, data holds values

A template only describes **how** a feature is written for a platform. The
values come from data, stored at the scope where they apply:

| Scope | Where the data lives | Example |
|---|---|---|
| Device | NetBox: device, interfaces, IP addresses, custom fields | IP of `ethernet-1/1`, `bgp_asn` |
| Site | NetBox config context for the site, or `inventory/group_vars/sites_<slug>.yml` | NTP / DNS servers of DC1 |
| Global | `inventory/group_vars/all.yml` | Domain name, login banner |

## Template variables

Templates are rendered per device, so they can use that device's host
variables from the NetBox dynamic inventory (`inventory/netbox.yml`), for
example `interfaces`, `primary_ip4`, `device_roles` and
`custom_fields.bgp_asn`. To list everything available for a device:

```bash
ansible-inventory --host spine1
```

## Previewing a template

Render a template for one device without touching it:

```bash
ansible spine1 -m ansible.builtin.debug \
  -a "msg={{ lookup('ansible.builtin.template', 'templates/srlinux/interfaces.j2') | from_yaml }}"
```
