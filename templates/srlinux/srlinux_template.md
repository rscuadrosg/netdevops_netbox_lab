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
| `bgp.j2` | eBGP underlay (planned) | `custom_fields.bgp_asn`, neighbor IPs |

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

## Data source

Every value comes from NetBox through the dynamic inventory. To change the
rendered config, change `data/fabric.yml` and run
`playbooks/netbox_populate.yml`; never edit the template for a single device.
