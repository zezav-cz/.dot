# QEMU guest used by `mise run vm` and the NixOS test. No bootloader or disko:
# qemu-vm.nix boots the kernel directly.
{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  networking.hostName = "vm";

  virtualisation = {
    memorySize = 8192;
    cores = 4;
    diskSize = 20480;
  };

  # Throwaway key (world-readable in the store on purpose: vm.yaml holds only
  # the VM test password). sops-nix refuses a key file in the store, so it is
  # copied to /run before the secrets are decrypted.
  sops = {
    defaultSopsFile = ../../secrets/vm.yaml;
    age.keyFile = "/run/vm-test.agekey";
    age.sshKeyPaths = [ ];
    age.generateKey = false;
  };
  system.activationScripts.vmTestAgeKey = {
    deps = [ "specialfs" ];
    text = "install -m 400 ${../../secrets/vm-test.agekey} /run/vm-test.agekey";
  };
  system.activationScripts.setupSecretsForUsers.deps = [ "vmTestAgeKey" ];
}
