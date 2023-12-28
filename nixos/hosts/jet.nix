# Desktop, AMD Zen 4, Nvidia Lovelace

let secrets = import ../secrets.nix;
in {
  imports = [ ../hardware/amd.nix ../roles/common.nix ];

  networking.hostName = "jet";

  boot.initrd.availableKernelModules = [ "nvme" ];
  security.sudo.wheelNeedsPassword = false;
  users.users.jaksi = {
    extraGroups = [ "wheel" ];
    hashedPassword = secrets.hashedUserPassword;
    isNormalUser = true;
  };
}
