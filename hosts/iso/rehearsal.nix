# Rehearsal-only ISO additions; never on the real USB stick.
{
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../secrets/rehearsal/id_ed25519.pub ];
  boot.kernelParams = [ "console=ttyS0,115200" ];
}
