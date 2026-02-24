{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/openstack/configuration.nix"
  ];
}
