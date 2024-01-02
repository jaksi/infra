# Beelink EQ12

{ config, lib, ... }:

with lib;

let
  wanInterface = "enp1s0";
  lanInterface = "enp2s0";
  secrets = import ../secrets.nix;
in {
  imports = [ ../hardware/intel.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "way";

  boot.initrd.availableKernelModules = [ "nvme" ];
  networking = {
    firewall.allowedUDPPorts = [ 41641 ];
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
          typeof ip daddr . ip protocol
          flags dynamic,timeout
          size 65535
          timeout 24h
          counter
        }
        set outbound {
          typeof ip saddr . ip protocol
          flags dynamic,timeout
          size 65535
          timeout 24h
          counter
        }
        chain forward {
          type filter hook forward priority 0;
          iifname ${wanInterface} update @inbound { ip daddr . ip protocol }
          oifname ${wanInterface} update @outbound { ip saddr . ip protocol }
        }
      '';
    };
    firewall.interfaces.${lanInterface} = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 67 ];
    };
  };
  systemd.network.networks."90-lan" = {
    matchConfig.Name = [ lanInterface ];
    address = [ "10.0.0.1/16" ];
  };
  services = {
    tailscale.extraUpFlags =
      [ "--advertise-routes=10.0.0.0/16" "--advertise-exit-node" ];
    dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        server =
          [ "127.0.0.1#${toString config.services.https-dns-proxy.port}" ];
        interface = lanInterface;
        bind-interfaces = true;
        no-resolv = true;
        dhcp-leasefile = "/nix/persist/dnsmasq.leases";
        dhcp-range = "10.0.0.100,10.0.0.200,12h";
        dhcp-host =
          attrsets.mapAttrsToList (name: host: "${host.mac},${host.ip},${name}")
          secrets.dhcpHosts;
        address = "/test.invalid/127.0.0.1";
      };
    };
    prometheus.exporters.dnsmasq = {
      enable = true;
      leasesPath = "/nix/persist/dnsmasq.leases";
    };
  };
}
