# WSL

{ pkgs, ... }:

{
  imports = [ ../NixOS-WSL/modules ../roles/common.nix ];

  networking.hostName = "win";

  wsl = {
    enable = true;
    useWindowsDriver = true;
  };
  environment = {
    systemPackages = with pkgs; [ nodejs_18 ];
    variables = {
      LD_LIBRARY_PATH = "/usr/lib/wsl/lib:"
        + pkgs.lib.makeLibraryPath (with pkgs; [ glib libGL stdenv.cc.cc.lib ]);
    };
  };
}
