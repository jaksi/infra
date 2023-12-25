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
    firewall.allowedUDPPorts = [ 41641 ];
    interfaces.${lanInterface} = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.0.0.1";
        prefixLength = 16;
      }];
    };
    nat = {
      enable = true;
      internalInterfaces = [ lanInterface ];
      externalInterface = wanInterface;
      forwardPorts = [{
        destination = "10.0.0.4:41642";
        proto = "udp";
        sourcePort = 41642;
      }];
    };
    nftables.tables.accounting = {
      family = "ip";
      content = ''
        set inbound {
          typeof ip saddr . ip protocol
          flags dynamic,timeout
          size 65535
          timeout 24h
          counter
        }
        set outbound {
          typeof ip daddr . ip protocol
          flags dynamic,timeout
          size 65535
          timeout 24h
          counter
        }
        chain prerouting {
          type filter hook prerouting priority 0;
          iifname ${lanInterface} update @inbound { ip saddr . ip protocol }
        }
        chain postrouting {
          type filter hook postrouting priority 0;
          oifname ${lanInterface} update @outbound { ip daddr . ip protocol }
        }
      '';
    };
    firewall.interfaces.${lanInterface} = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 67 ];
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
        dhcp-host = [ "ArcherAX55,10.0.0.2" "nas,10.0.0.3" "sun,10.0.0.4" ];
        bind-interfaces = true;
      };
    };
    prometheus.exporters.dnsmasq = {
      enable = true;
      leasesPath = "/nix/persist/dnsmasq.leases";
    };
  };
}
