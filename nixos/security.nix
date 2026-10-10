# YubiKey: PIV/OATH via pcscd (ykman), OpenPGP card for gpg, udev access.
{ pkgs, ... }:
{
  services.pcscd.enable = true;
  hardware.gpgSmartcards.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
}
