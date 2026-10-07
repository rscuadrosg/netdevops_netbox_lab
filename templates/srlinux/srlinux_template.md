# Nokia SR Linux templates

Templates for the `srlinux` platform. General rules for all templates are in
[../template_definition.md](../template_definition.md).

## Output format

SR Linux is configured through its **JSON-RPC API**, not CLI text. Every
template renders a YAML list of `update` operations, each one a YANG
**path** plus the **value** to merge at that path:

```yaml
- path: /interface[name=ethernet-1/1]
  value:
    admin-state: enable
    subinterface:
      - index: 0
        ipv4:
          address:
            - ip-prefix: 10.1.1.0/31
```

The platform playbook (`playbooks/platforms/srlinux.yml`) parses that YAML and
sends it with the `nokia.srlinux.config` module. `update` merges into the
running config, so anything the template doesn't mention is left untouched.

## Templates

| File | Configures | Input (host variables) |
|---|---|---|
| `interfaces.j2` | Interfaces, subinterface `.0`, IPv4 addresses, membership in the `default` network-instance | `interfaces` (with `ip_addresses`) |
| `bgp.j2` | Loopback routing policy and eBGP underlay | `custom_fields.bgp_asn`, `interfaces` (with `connected_endpoints`), `fabric_loopback_pool` |

### interfaces.j2

1. Selects the **routed interfaces**: every NetBox interface that has at least
   one IP address and is not management-only.
2. For each one, enables the interface and subinterface `0`, sets the
   description and the IPv4 addresses from NetBox.
3. Adds every routed subinterface (`<name>.0`) to the `default`
   network-instance. On SR Linux an interface with an IP does not route
   traffic until it belongs to a network-instance.

`mgmt0` is skipped on purpose: Containerlab configures it in the `mgmt`
network-instance, and it is how Ansible reaches the router. Changing it could
cut Ansible off.

#### SR Linux concepts used

| Concept | Meaning |
|---|---|
| `ethernet-1/1` | Physical port: slot 1, port 1 |
| `system0` | Loopback interface, used as BGP router-id |
| Subinterface `.0` | Logical interface that carries the IP. SR Linux puts IPs on subinterfaces, never directly on the port |
| Network-instance `default` | The main routing table (like the global VRF) |
| Network-instance `mgmt` | Separate routing table for management, created by Containerlab |

### bgp.j2

1. **Routing policy `loopbacks`**: accepts only /32 routes inside
   `fabric_loopback_pool` (site data in `inventory/group_vars/sites_dc1.yml`)
   and rejects everything else. SR Linux applies RFC 8212 to eBGP: without
   import and export policies, no routes are exchanged.
2. **BGP** in the `default` network-instance, with the device ASN
   (`custom_fields.bgp_asn`) and the `system0` IP as router-id.
3. **Neighbors derived from NetBox cabling**: for every interface with a
   cable, `connected_endpoints` gives the peer device and interface. The
   template reads the peer's interface IP and its `bgp_asn` from that device's
   host variables (`hostvars`), so no neighbor is written by hand. Changing
   the cables in `data/fabric.yml` changes the BGP neighbors automatically.

Result: each leaf learns the other leaf's loopback through the spine. From
leaf1, `ping 10.0.0.12 network-instance default -I 10.0.0.11` replies with
TTL 63: one hop through spine1.


## Data source

Every value comes from NetBox through the dynamic inventory. To change the
rendered config, change `data/fabric.yml` and run
`playbooks/netbox_populate.yml`; never edit the template for a single device.
