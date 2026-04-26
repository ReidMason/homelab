locals {
  nodes         = { for k, v in var.cluster_config.nodes : k => v if coalesce(v.enabled, true) }
  controlplanes = { for k, v in local.nodes : k => v if v.type == "control-plane" }
  workers       = { for k, v in local.nodes : k => v if v.type == "worker" }
  # Map keys are last IPv4 octets (20–59); pick lowest-octet control plane as bootstrap / API endpoint host.
  main_controlplane_octet    = min([for k in keys(local.controlplanes) : tonumber(k)]...)
  main_controlplane_key      = one([for k in keys(local.controlplanes) : k if tonumber(k) == local.main_controlplane_octet])
  main_controlplane_hostname = local.controlplanes[local.main_controlplane_key].hostname
  cluster_endpoint           = "https://${local.main_controlplane_hostname}:6443"
  control_plane_hostnames    = [for k in sort(keys(local.controlplanes)) : local.controlplanes[k].hostname]
  image                      = "factory.talos.dev/installer/${var.talos_schematic_id}:v${var.talos_version}"
  machine_config_by_role = {
    controlplane = "controlplane"
    worker       = "worker"
  }
  machine_base_patch = yamlencode({
    machine = {
      install = {
        image = local.image
        disk  = var.install_disk
      }
      network = {
        nameservers = var.nameservers
      }
    }
  })
  hostname_config = {
    apiVersion = "v1alpha1"
    kind       = "HostnameConfig"
    auto       = "off"
  }
}

resource "talos_machine_secrets" "machine_secrets" {}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_config.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = local.control_plane_hostnames
}

data "talos_machine_configuration" "machine" {
  for_each = local.machine_config_by_role

  // This should use a load balancer
  cluster_name       = var.cluster_config.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = each.value
  machine_secrets    = talos_machine_secrets.machine_secrets.machine_secrets
  kubernetes_version = "v${var.kubernetes_version}"
  talos_version      = "v${var.talos_version}"
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  for_each = local.controlplanes

  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machine["controlplane"].machine_configuration
  node                        = each.value.hostname
  config_patches = [
    local.machine_base_patch,
    yamlencode(merge(local.hostname_config, {
      hostname = each.value.hostname
    }))
  ]
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  for_each = local.workers

  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machine["worker"].machine_configuration
  node                        = each.value.hostname
  config_patches = [
    local.machine_base_patch,
    yamlencode(merge(local.hostname_config, {
      hostname = each.value.hostname
    }))
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.cp_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = local.main_controlplane_hostname
}

// data "talos_cluster_health" "health" {
//   depends_on           = [ talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply ]
//   client_configuration = data.talos_client_configuration.talosconfig.client_configuration
//   control_plane_nodes  = keys(local.controlplanes)
//   worker_nodes         = keys(local.workers)
//   endpoints            = data.talos_client_configuration.talosconfig.endpoints
// }

resource "talos_cluster_kubeconfig" "kubeconfig" {
  // depends_on           = [ talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health ]
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = local.main_controlplane_hostname
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}
