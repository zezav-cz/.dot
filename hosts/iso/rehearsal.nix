# Rehearsal-only additions (scripts/vm-rehearsal drives the ISO over SSH and
# the serial console); never on a real USB stick.
{
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../secrets/rehearsal/id_ed25519.pub ];
  boot.kernelParams = [ "console=ttyS0,115200" ];
}
