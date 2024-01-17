{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball
    "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  secrets = import ../secrets.nix;
  colors = {
    air = "#1e66f5";
    jet = "#40a02b";
    dew = "#179299";
    way = "#d20f39";
    sun = "#ea76cb";
    ant = "#df8e1d";
  };
in {
  imports = [ "${impermanence}/nixos.nix" ];

  nix.gc = {
    automatic = true;
    options = "--delete-old";
  };
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ (import ../pkgs) ];
  };
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
      ];
      files = [ "/etc/machine-id" "/root/.nix-channels" ];
    };
    systemPackages = with pkgs; [
      bat
      dig
      eza
      gh
      git-crypt
      go
      jq
      nil
      nixfmt
      python3
      terraform
      terraform-ls
      terraform-providers.namecheap
      yq
    ];
    etc."ssh/authorized_keys_command" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        ${pkgs.curl}/bin/curl -Ls 'https://github.com/jaksi.keys'
      '';
    };
  };
  users = {
    defaultUserShell = pkgs.fish;
    users.root = {
      hashedPassword = secrets.hashedUserPassword;
      openssh.authorizedKeys.keyFiles =
        [ (builtins.fetchurl "https://github.com/jaksi.keys") ];
    };
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
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        if not test "$TERM_PROGRAM" = "vscode"; and not test "$TERM" = "linux"; and not set -q TMUX
          exec tmux new-session -As main
        end
        set -U fish_greeting
        function prompt_login
        end
      '';
      shellAliases = {
        cat = "bat -pp --theme=ansi";
        ls = "eza";
        l = "eza -la";
        ll = "eza -la";
        la = "eza -la";
        lt = "eza -Ta";
        c = "gh copilot suggest -t shell";
        cg = "gh copilot suggest -t git";
        cgh = "gh copilot suggest -t gh";
      };
    };
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        user.name = "Kristof Jakab";
        user.email = "jaksi@users.noreply.github.com";
      };
    };
    htop = {
      enable = true;
      settings = {
        hide_userland_threads = true;
        tree_view = true;
      };
    };
    neovim = {
      enable = true;
      vimAlias = true;
      withNodeJs = true;
      defaultEditor = true;
      configure = {
        customRC = ''
          let g:airline_symbols_ascii=1
          let g:airline#extensions#tabline#enabled=1
          let g:airline_theme='catppuccin'
          colorscheme catppuccin-latte
          set noshowmode
          set mouse=
          set ignorecase smartcase
          set number
          set cursorline
          set tabstop=2 shiftwidth=2 expandtab
          lua <<EOF
          require'lspconfig'.nil_ls.setup{
            settings = {
              ['nil'] = {
                formatting = {
                  command = { "nixfmt" },
                },
              },
            },
          }
          require'lspconfig'.terraformls.setup{}
          vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('UserLspConfig', {}),
            callback = function(ev)
              local opts = { buffer = ev.buf }
              vim.keymap.set('n', '<space>f', function()
                vim.lsp.buf.format { async = true }
              end, opts)
            end,
          })
          EOF
        '';
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [
            catppuccin-nvim
            copilot-vim
            nvim-lspconfig
            vim-airline
            vim-airline-themes
            vim-nix
          ];
        };
      };
    };
    tmux = {
      enable = true;
      extraConfig = ''
        set -g status-left ' #h '
        set -g status-right ' '
        set -g status-style fg=#4c4f69,bg=#ccd0da
        set -g window-status-format ' #I #W '
        set -g window-status-current-format ' #I #W '
        set -g window-status-style fg=#4c4f69,bg=#acb0be
        set -g window-status-bell-style fg=#eff1f5,bg=#8839ef
        set -g escape-time 10
        set -g allow-passthrough 1
        set -g default-terminal "tmux-256color"
        set -g window-status-current-style fg=#eff1f5,bg=${
          colors.${config.networking.hostName}
        }
        set -sa terminal-features ',xterm-256color:RGB'
      '';
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
