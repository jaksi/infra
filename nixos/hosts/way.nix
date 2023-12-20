# Beelink EQ12

{ config, ... }:

let
  wanInterface = "enp1s0";
  lanInterface = "enp2s0";
in {
  imports = [ ../hardware/intel.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "way";
  programs.tmux.extraConfig = ''
    set -g window-status-current-style fg=#eff1f5,bg=#ea76cb
  '';

  boot.initrd.availableKernelModules = [ "nvme" ];
  networking = {
    firewall = {
      interfaces.${lanInterface} = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 67 ];
      };
      extraCommands = ''
        iptables -t nat -A POSTROUTING -o ${wanInterface} -j MASQUERADE
        iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i ${lanInterface} -o ${wanInterface} -j ACCEPT
      '';
    };
    interfaces.${lanInterface} = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.0.0.1";
        prefixLength = 16;
      }];
    };
  };
  services = {
    tailscale.extraUpFlags = [ "--advertise-routes=10.0.0.0/16" ];
    https-dns-proxy = {
      enable = true;
      provider.kind = "google";
    };
    dnsmasq = {
      enable = true;
      settings = {
        server =
          [ "127.0.0.1#${toString config.services.https-dns-proxy.port}" ];
        interface = "${lanInterface}";
        dhcp-leasefile = "/nix/persist/dnsmasq.leases";
        dhcp-range = "10.0.0.100,10.0.0.200,12h";
        dhcp-host = [
          "ArcherAX55,10.0.0.2"
          "nas,10.0.0.3"
        ];
      };
    };
  };
}
