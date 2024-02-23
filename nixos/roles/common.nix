{ config, pkgs, ... }:

let
  colors = {
    dew = "#1e66f5";
    way = "#40a02b";
    sun = "#179299";
    ant = "#d20f39";
    win = "#ea76cb";
  };
in {

  nix.gc = {
    automatic = true;
    options = "--delete-old";
  };
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
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
    yq
  ];
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        if set -q SSH_CONNECTION; and not set -q TMUX
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
  users.defaultUserShell = pkgs.fish;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
