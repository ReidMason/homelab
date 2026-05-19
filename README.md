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
| Talos control plane (vm 120)   | `10.128.20.20`          | `10.128.30.20`                 |
| Talos worker (vm 121)          | `10.128.20.21`          | `10.128.30.21`                 |
| MetalLB Traefik / nginx        | `10.128.20.60`, `.61`   | `10.128.30.60`, `.61`          |
| MetalLB pool                   | `10.128.20.60–69`       | `10.128.30.60–69`              |

## Production cluster

Prereqs: Proxmox on `ivy` (`10.128.20.5`), switch port native VLAN 20, UniFi static host entries for Talos MACs → `.20` / `.21` (same as dev), DNS for `kube1.prod.internal` / `kube2.prod.internal`.

```bash
# Terraform (from terraform/)
cp environments/prod/credentials.tfvars.example environments/prod/credentials.tfvars  # fill in
cp environments/prod/prod.s3.tfbackend.example environments/prod/prod.s3.tfbackend    # Rustfs keys
just env=prod init
just env=prod apply

eval "$(just env=prod kubeconfig)"
CLUSTER_ENV=prod ./kubernetes-v2/bootstrap.sh
```

After bootstrap: seal `vault-approle-eso` on the prod cluster (dev ciphertext does not transfer), enable `homelab.vaultAppRoleSealedSecret` in `kubernetes-v2/values/prod/external-secrets/values.yaml`, and add Vault paths `secret/prod/cloudflare` plus NFS export `kubernetes-prod` on fern.
