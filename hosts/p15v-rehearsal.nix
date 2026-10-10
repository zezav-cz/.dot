# p15v as installed into the rehearsal VM: same disko layout, bootloader,
# initrd, sops mechanism (host key -> age) and modules; minus the real
# hardware, Wi-Fi and secrets. Its sops file is vm.yaml, re-keyed for the
# throwaway rehearsal host key in secrets/rehearsal/.
{ lib, modulesPath, ... }:
{
  imports = [
    ./p15v/common.nix
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  p15v.disk = "/dev/vda";
  sops.defaultSopsFile = lib.mkForce ../secrets/vm.yaml;

  # LUKS prompt and logs on the serial port the rehearsal script talks to.
  boot.kernelParams = [ "console=ttyS0,115200" ];

  services.openssh.openFirewall = lib.mkForce true;
  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../secrets/rehearsal/id_ed25519.pub ];
}
