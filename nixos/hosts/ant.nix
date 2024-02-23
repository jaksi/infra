# M2 Mac mini

{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    <apple-silicon-support/apple-silicon-support>
    ../hardware/efi.nix
    ../roles/server.nix
  ];

  networking.hostName = "ant";

  fileSystems."/boot".device = "/dev/disk/by-uuid/33CF-1813";
  nixpkgs.hostPlatform = "aarch64-linux";
  boot.loader.efi.canTouchEfiVariables = false;
  hardware.asahi.useExperimentalGPUDriver = true;
}
