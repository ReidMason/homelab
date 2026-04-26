# homelab

## Network

| VLAN      | Subnet           | Use |
| --------- | ---------------- | --- |
| (default) | `10.128.0.0/24`  | Trusted LAN |
| 10        | `10.128.10.0/24` | Guest |
| 20        | `10.128.20.0/24` | Lab prod (isolated, no DHCP; static only) |
| 30        | `10.128.30.0/24` | Lab dev (isolated, no DHCP; static only) |

Gateways: **`10.128.20.1`** (prod), **`10.128.30.1`** (dev). Each lab host’s switch port: **native to that VLAN** (not “None”).

### Static IPs

| Role | Prod (`10.128.20.0/24`) | Dev (`10.128.30.0/24`) |
| ---- | ----------------------- | ---------------------- |
| Application host (Proxmox) | `10.128.20.5` | `10.128.30.5` |

More assignments TBD (nodes, LB VIPs, etc.).
