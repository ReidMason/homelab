{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  # Temporary: allow console login for debugging
  users.users.root.password = "nixos";

  system.stateVersion = "25.11";
}
