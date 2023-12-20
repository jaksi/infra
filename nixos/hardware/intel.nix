{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./x86_64.nix
    ./efi.nix
  ];

  hardware.cpu.intel.updateMicrocode = true;
}
