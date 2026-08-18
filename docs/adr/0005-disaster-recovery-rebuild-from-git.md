# 0005: Disaster recovery plan is rebuild-from-git, not cluster-state backup

## Status

Accepted

## Context

The cluster has no etcd snapshot mechanism and no backup of the ArgoCD installation itself. Longhorn volumes (app data) get daily/weekly backups to NFS (`nfs://fern.internal/mnt/user/Backups/longhorn`), but the cluster's control-plane state — the Kubernetes objects, ArgoCD's own state — is not separately backed up.

This was flagged as a potential gap during an architecture review. The cluster is fully GitOps-managed (`kubernetes-v2/`, ArgoCD `ApplicationSet` glob over `values/prod/*/deploy.yaml`), and provisioned via Terraform (`terraform/environments/prod`) against Talos. Considered alternatives: (a) add etcd snapshotting (e.g. Talos's built-in etcd backup, or a CronJob), (b) add Velero for cluster-resource + volume backup, (c) rely on rebuilding from the existing GitOps + Terraform sources of truth.

## Decision

No dedicated cluster-state backup tool is being added. The DR plan is: if the control plane is lost, re-run `terraform apply` (recreates the Talos VMs/nodes) followed by `kubernetes-v2/bootstrap.sh` (reinstalls ArgoCD and applies the root Application), and let the ArgoCD `ApplicationSet` resync all 31+ apps from git. This is a deliberate choice, not an oversight: the cluster's desired state already lives entirely in this repo, so re-deriving cluster state from git is preferred over maintaining a second, redundant copy of that state in a backup tool.

App *data* (Longhorn volumes, NFS-backed PVCs) is out of scope for this decision — that's covered separately by Longhorn's recurring backup jobs.

## Consequences

- Recovery is a manual, multi-step process (`terraform apply` → `bootstrap.sh` → wait for ArgoCD resync) rather than a single restore command — acceptable for a homelab's RTO expectations, but should be validated by a real dry run at some point rather than assumed to work.
- Vault (`compose/vault`, running on fern.internal outside the cluster) is a hidden dependency of this plan: `external-secrets` pulls all app secrets from it, so if Vault's data (`/mnt/user/appdata/hashicorp-vault/data` on fern) is lost alongside the cluster, rebuilding from git alone is not sufficient — every app secret would need to be recreated by hand. Vault's own backup posture is out of scope of this ADR but is a real dependency worth checking separately.
- Any cluster state that isn't captured in git (manual `kubectl` changes, imperative fixes applied outside the GitOps flow) will not survive a rebuild. This is a reason to keep such changes to a minimum, consistent with the read-only/no-one-off-fixes posture already used when operating this cluster.
- If recovery time or Vault's own durability becomes a real concern later, revisit option (a) or (b) above.
