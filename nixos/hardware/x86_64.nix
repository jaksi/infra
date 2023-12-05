{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
