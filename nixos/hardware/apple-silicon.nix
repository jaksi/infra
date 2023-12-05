{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    <apple-silicon-support/apple-silicon-support>
    ./efi.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  boot.loader.efi.canTouchEfiVariables = false;
  system.activationScripts.nix-channel = lib.mkIf config.nix.channel.enable
    (lib.stringAfter [ "etc" "users" ] ''
      APPLE_SILICON_CHANNEL="https://github.com/tpwrules/nixos-apple-silicon/archive/main.tar.gz apple-silicon-support"
      if ! grep -Fq "$APPLE_SILICON_CHANNEL" /root/.nix-channels; then
        echo "$APPLE_SILICON_CHANNEL" >> /root/.nix-channels
      fi
    '');
}
