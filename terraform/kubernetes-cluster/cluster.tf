variable "cluster_config" {
  description = "Cluster configuration"
  type = object({
    cluster_name = string
  })
  default = {
    cluster_name = "kubernetes-test"
  }
}

locals {
  controlplanes = { for k, v in var.kube_servers : k => v if v.type == "controlplane" }
  workers = { for k, v in var.kube_servers : k => v if v.type == "worker" }
  main_controlplane = values(local.controlplanes)[0]
  cluster_endpoint = "https://${local.main_controlplane.ip}:6443"
  image = "factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.7.5"
}

resource "talos_machine_secrets" "machine_secrets" {}

data "talos_client_configuration" "talosconfig" {
  cluster_name = var.cluster_config.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints = [for s in local.controlplanes : s.ip]
}

data "talos_machine_configuration" "machineconfig_cp" {
  cluster_name     = var.cluster_config.cluster_name
  // This shoud use a load balancer
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  for_each                    = local.controlplanes

  depends_on                  = [ proxmox_vm_qemu.kube-server ]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp.machine_configuration
  node                        = each.value.ip
  config_patches = [
  yamlencode({
    machine = {
      install = {
        image = local.image
      }
      network = {
        hostname = each.value.name
      }
    }
    })
  ]
}

data "talos_machine_configuration" "machineconfig_worker" {
  cluster_name     = var.cluster_config.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  for_each                    = local.workers

  depends_on                  = [ proxmox_vm_qemu.kube-server ]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration
  node                        = each.value.ip
  config_patches = [
  yamlencode({
    machine = {
      install = {
        image = local.image
      }
      network = {
        hostname = each.value.name
      }
    }
    })
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [ talos_machine_configuration_apply.cp_config_apply ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = local.main_controlplane.ip
}

// data "talos_cluster_health" "health" {
//   depends_on           = [ talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply ]
//   client_configuration = data.talos_client_configuration.talosconfig.client_configuration
//   control_plane_nodes  = [for s in local.controlplanes : s.ip]
//   worker_nodes         = [for s in local.workers : s.ip]
//   endpoints            = data.talos_client_configuration.talosconfig.endpoints
// }

data "talos_cluster_kubeconfig" "kubeconfig" {
  // depends_on           = [ talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health ]
  depends_on           = [ talos_machine_bootstrap.bootstrap ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = local.main_controlplane.ip
}

output "talosconfig" {
  value = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}
