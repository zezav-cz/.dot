# Installer USB for p15v (and, via rehearsal.nix, the rehearsal VM). Carries
# the flake at /etc/dot and the source of every flake.lock node, so evaluating
# it needs no GitHub access (the private `vn` input included).
{
  lib,
  modulesPath,
  pkgs,
  inputs,
  self,
  ...
}:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../keys/jantrojak.pub ];

  environment.etc."dot".source = self;
  isoImage.storeContents =
    let
      sources = i: [ i.outPath ] ++ lib.concatMap sources (lib.attrValues (i.inputs or { }));
    in
    lib.unique (
      [ self.outPath ] ++ lib.concatMap sources (lib.attrValues (removeAttrs inputs [ "self" ]))
    );

  # The host key is sops-encrypted to the OpenPGP key on the YubiKey.
  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };
  environment.systemPackages = [
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
    pkgs.git
    pkgs.sops
    pkgs.age
    pkgs.ssh-to-age
  ];
}
