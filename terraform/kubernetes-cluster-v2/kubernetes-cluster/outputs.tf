output "talosconfig" {
  value       = module.talos-setup.talosconfig
  sensitive   = true
  description = "Talos client configuration"
}

output "kubeconfig" {
  value       = module.talos-setup.kubeconfig
  sensitive   = true
  description = "Kubernetes configuration"
}
