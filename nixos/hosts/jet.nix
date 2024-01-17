# Desktop, AMD Zen 4, Nvidia Lovelace

{
  imports = [ ../hardware/amd.nix ../roles/desktop.nix ../roles/common.nix ];

  networking.hostName = "jet";

  boot.initrd.availableKernelModules = [ "nvme" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    nvidia = {
      nvidiaSettings = false;
      modesetting.enable = true;
    };
    opengl.driSupport32Bit = true;
  };
  programs.sway = {
    extraOptions = [ "--unsupported-gpu" ];
    extraSessionCommands = ''
      export WLR_NO_HARDWARE_CURSORS=1
    '';
  };
  environment.etc."sway/config".text = ''
    output DP-2 adaptive_sync on
    output DP-2 mode 2560x1440@279.958Hz
  '';
}
