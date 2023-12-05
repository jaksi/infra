{ config, lib, pkgs, ... }:

with lib;

{
  options.services.vscode-tunnel = {
    enable = mkEnableOption (mdDoc "the vscode-tunnel service");
  };
  config = mkIf config.services.vscode-tunnel.enable {
    systemd.services.vscode-tunnel = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.vscode-cli}/bin/code tunnel --cli-data-dir /nix/persist/vscode-tunnel --accept-server-license-terms --name ${config.networking.hostName}
        '';
        Restart = "always";
      };
    };
    system.activationScripts.vscode-tunnel.text = ''
      SERVER=${pkgs.vscode-server}
      COMMIT=$(${pkgs.jq}/bin/jq -r .commit $SERVER/product.json)
      rm -rf /nix/persist/vscode-tunnel/servers
      mkdir -p /nix/persist/vscode-tunnel/servers/Stable-$COMMIT
      ln -sf $SERVER /nix/persist/vscode-tunnel/servers/Stable-$COMMIT/server
    '';
  };
}
