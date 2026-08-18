# 0004: Hand-maintained relabeling to correlate Unraid drive metrics

## Status

Accepted

## Context

The Unraid Drives Grafana dashboard shows one row per physical drive with both temperature and capacity. These come from two separate exporters with no shared identifier: `node_exporter` labels capacity by `mountpoint` (`/mnt/disk1`, `/mnt/cache`, ...), while `smartctl_exporter` labels temperature by raw device (`sdb`, `nvme0`, ...). Unraid's virtual `md` array driver means there's no reliable string transform between the two, and device letters aren't guaranteed stable across reboots in general (though empirically stable on this host so far).

Considered alternatives: (a) build a textfile-collector exporter reading Unraid's own disk-to-serial mapping for an always-correct join, (b) drop the join entirely and show temperature/capacity as separate, unmerged panels.

## Decision

`metric_relabel_configs` were added to both the `unraid` and `unraid-smart` Prometheus scrape jobs (`kubernetes-v2/values/prod/monitoring/values.yaml`), mapping each job's native label to a shared `disk` label (`disk1`, `disk2`, `disk3`, `parity`, `parity2`, `cache`). The device-to-slot assignment is copied by hand from the Unraid Main tab. Grafana joins the two metric sources on this `disk` label.

## Consequences

- If a drive is physically replaced, or a device letter otherwise shifts, a dashboard row can silently show the wrong drive's data until the relabel map is updated to match Unraid's Main tab.
- Adding/removing a drive means updating both scrape jobs' `metric_relabel_configs`, not just one.
- If this becomes a recurring maintenance burden, revisit option (a) — a textfile collector keyed on serial number would make the join self-correcting.
