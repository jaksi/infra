# Desktop, AMD Zen 4, Nvidia Lovelace

let secrets = import ../secrets.nix;
in {
  imports = [ ../hardware/amd.nix ../roles/common.nix ];

  networking.hostName = "jet";
  programs.tmux.extraConfig = ''
    set -g window-status-current-style fg=#eff1f5,bg=#d20f39
  '';

  boot.initrd.availableKernelModules = [ "nvme" ];
  security.sudo.wheelNeedsPassword = false;
  users.users.jaksi = {
    extraGroups = [ "wheel" ];
    hashedPassword = secrets.hashedUserPassword;
    isNormalUser = true;
  };
}
