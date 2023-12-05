{ modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/headless.nix") ../modules/vscode-tunnel.nix ];

  environment.persistence."/nix/persist/system".directories =
    [ "/root/.vscode-server" ];
  services.vscode-tunnel.enable = true;
}
