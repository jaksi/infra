# Vultr VPS

{ config, lib, ... }:

let
  oauth2ProxyPort = 8000;
  secrets = import ../secrets.nix;
in {
  imports = [ ../hardware/x86_64.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "dew";
  programs.tmux.extraConfig = ''
    set -g window-status-current-style fg=#eff1f5,bg=#179299
  '';

  virtualisation.hypervGuest.enable = true;
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };
    initrd.availableKernelModules =
      [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  };
  fileSystems."/boot".fsType = "ext4";
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 443 ];
  };
  services = {
    oauth2_proxy = {
      enable = true;
      provider = "github";
      clientID = secrets.oauth2ProxyClientID;
      clientSecret = secrets.oauth2ProxyClientSecret;
      cookie = {
        domain = "infra.jaksi.dev";
        secret = secrets.oauth2ProxyCookieSecret;
      };
      email.domains = [ "*" ];
      reverseProxy = true;
      upstream = [ "http://localhost:${builtins.toString oauth2ProxyPort}" ];
      scope = "user:email";
      extraConfig = {
        "github-user" = "jaksi";
        "skip-provider-button" = true;
      };
    };
    caddy = {
      enable = true;
      dataDir = "/nix/persist/caddy";
      virtualHosts = let
        hosts =
          [ "prometheus" "grafana" "zigbee2mqtt" "home-assistant" "unifi" ];
      in {
        "unauthenticated" = {
          hostName = "";
          serverAliases =
            lib.lists.forEach hosts (host: "${host}.infra.jaksi.dev");
          extraConfig = ''
            reverse_proxy ${config.services.oauth2_proxy.httpAddress}
          '';
        };
        "authenticated" = {
          hostName = "http://:${builtins.toString oauth2ProxyPort}";
          listenAddresses = [ "127.0.0.1" "::1" ];
          extraConfig = lib.strings.concatLines (lib.lists.forEach hosts
            (host: ''
              @host_${host} {
                host ${host}.infra.jaksi.dev
              }
              reverse_proxy @host_${host} "https://${host}.tailbb015.ts.net" {
                header_up host {upstream_hostport}
              }
            ''));
        };
      };
    };
  };
}
