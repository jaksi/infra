{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    <apple-silicon-support/apple-silicon-support>
    ./efi.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  boot.loader.efi.canTouchEfiVariables = false;
}
