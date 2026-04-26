# homelab

## Network

| VLAN      | Subnet           | Use                                       |
| --------- | ---------------- | ----------------------------------------- |
| (default) | `10.128.0.0/24`  | Trusted LAN                               |
| 10        | `10.128.10.0/24` | Guest                                     |
| 20        | `10.128.20.0/24` | Lab prod (isolated, no DHCP; static only) |
| 30        | `10.128.30.0/24` | Lab dev (isolated, no DHCP; static only)  |

Gateways: **`10.128.20.1`** (prod), **`10.128.30.1`** (dev). Each lab host’s switch port: **native to that VLAN** (not “None”).

### Lab VLAN layout (last octet, same on prod and dev)

| Range       | Use                                 |
| ----------- | ----------------------------------- |
| `.1`        | Gateway                             |
| `.2`–`.19`  | Infra                               |
| `.20`–`.59` | **Kubernetes nodes** (Talos)        |
| `.60`+      | MetalLB VIPs, other static services |

### Static IPs

| Role                           | Prod (`10.128.20.0/24`) | Dev (`10.128.30.0/24`)         |
| ------------------------------ | ----------------------- | ------------------------------ |
| Application host (Proxmox)     | `10.128.20.5`           | `10.128.30.5`                  |
| Talos control plane (vm 180)   | `10.128.20.20` (TBD)    | `10.128.30.20`                 |
| Talos worker (vm 181)          | `10.128.20.21` (TBD)    | `10.128.30.21`                 |
| MetalLB Traefik / Pi-hole VIPs | TBD                     | `10.128.30.70`, `10.128.30.72` |
