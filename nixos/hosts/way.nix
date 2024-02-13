# Beelink EQ12

{ config, lib, modulesPath, ... }:

with lib;

let
  wanInterface = "enp1s0";
  lanInterface = "enp2s0";
  secrets = import ../secrets.nix;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../hardware/x86_64.nix
    ../hardware/efi.nix
    ../roles/common.nix
  ];

  networking.hostName = "way";

  hardware.cpu.intel.updateMicrocode = true;
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
        chain input {
          type filter hook input priority 0;
          iifname ${wanInterface} update @inbound { 127.0.0.1 . ip protocol }
        }
        chain output {
          type filter hook output priority 0;
          oifname ${wanInterface} update @outbound { 127.0.0.1 . ip protocol }
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
  systemd.network.networks."90-wan" = {
    matchConfig.Name = [ wanInterface ];
    DHCP = "yes";
    dns = [ "127.0.0.1" ];
    dhcpV4Config.UseDNS = false;
    dhcpV6Config.UseDNS = false;
    ipv6AcceptRAConfig.UseDNS = false;
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
        dhcp-range = "10.0.0.100,10.0.0.200,30d";
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
