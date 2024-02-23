{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball
    "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  secrets = import ../secrets.nix;
in {
  imports = [ "${impermanence}/nixos.nix" ./common.nix ];

  nixpkgs.overlays = [
    (self: super: {
      vscode-cli = super.callPackage ../pkgs/vscode.nix {
        package = "cli";
        hashes = {
          x86_64-linux = "sha256-+icvN/jEbjzj9dcUbeAl3bI79CX0ndj95ZNskxXt2qA=";
          aarch64-linux = "sha256-GOegfG0flyOEZUlCYhUfRxgLXqTcKw3lFBM7oU6RfMY=";
        };
        installPhase = ''
          mkdir -p $out/bin
          cp code $out/bin/
        '';
        linuxPlatform = "alpine";
      };
      vscode-server = super.callPackage ../pkgs/vscode.nix {
        package = "server";
        hashes = {
          x86_64-linux = "sha256-+yVjfMwA263SgVga7h6ZnGozncGaMJLE8ece3/8UWxo=";
          aarch64-linux = "sha256-15JqzUYI/NuQjUGuBOjizx6LlDMkJmfU6H4LWVh2hUk=";
        };
        installPhase = ''
          mkdir -p $out
          cp -r vscode-server-*/* $out/
          ln -sf ${self.nodejs_18}/bin/node $out/
        '';
      };
    })
  ];
  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=1G" "mode=755" ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/nix";
      fsType = "ext4";
    };
  };
  swapDevices = [{
    size = 2048;
    device = "/nix/persist/swapfile";
  }];
  time.timeZone = "Europe/Dublin";
  networking = {
    useNetworkd = true;
    useDHCP = false;
    nftables.enable = true;
    firewall = {
      allowedTCPPorts = config.services.openssh.ports;
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };
  };
  systemd.network.networks."99-ethernet" = {
    matchConfig.Name = [ "en*" "eth*" ];
    DHCP = "yes";
    dns = [ "127.0.0.1:5053" ];
    dhcpV4Config.UseDNS = false;
    dhcpV6Config.UseDNS = false;
    ipv6AcceptRAConfig.UseDNS = false;
  };
  environment = {
    persistence."/nix/persist/system" = {
      directories = [
        "/tmp"
        "/etc/nixos"
        "/var/log"
        "/var/lib/tailscale"
        {
          directory = "/root/.ssh";
          mode = "0700";
        }
        "/root/.config/gh"
        "/root/.config/github-copilot"
        "/root/.local/share/fish"
        "/root/.vscode-server"
      ];
      files = [ "/etc/machine-id" "/root/.nix-channels" ];
    };
    etc."ssh/authorized_keys_command" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        ${pkgs.curl}/bin/curl -Ls 'https://github.com/jaksi.keys'
      '';
    };
  };
  users.users.root = {
    hashedPassword = secrets.hashedUserPassword;
    openssh.authorizedKeys.keyFiles =
      [ (builtins.fetchurl "https://github.com/jaksi.keys") ];
  };
  services = {
    fstrim.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      hostKeys = [{
        path = "/nix/persist/ssh_host_ed25519_key";
        type = "ed25519";
      }];
      authorizedKeysCommand = "/etc/ssh/authorized_keys_command";
      authorizedKeysCommandUser = "nobody";
    };
    tailscale = {
      enable = true;
      extraUpFlags = [ "--ssh" ];
      useRoutingFeatures = "server";
      authKeyFile = pkgs.writeText "tailscale_key" secrets.tailscaleAuthKey;
    };
    https-dns-proxy = {
      enable = true;
      provider.kind = "google";
    };
    resolved.fallbackDns = [ ];
    prometheus.exporters = {
      blackbox = {
        enable = true;
        configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON {
          modules = {
            icmp = {
              prober = "icmp";
              icmp.preferred_ip_protocol = "ip4";
            };
            tcp = {
              prober = "tcp";
              tcp.preferred_ip_protocol = "ip4";
            };
            tls = {
              prober = "tcp";
              tcp = {
                preferred_ip_protocol = "ip4";
                tls = true;
              };
            };
            dns = {
              prober = "dns";
              dns = {
                preferred_ip_protocol = "ip4";
                query_name = "example.org";
                query_type = "A";
              };
            };
          };
        });
      };
      node = {
        enable = true;
        enabledCollectors = [ "ethtool" "systemd" ];
      };
      systemd.enable = true;
    };
  };
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
}
