# M2 Mac mini

{
  imports =
    [ ../hardware/apple-silicon.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "ant";
  programs.tmux.extraConfig = ''
    set -g window-status-current-style fg=#eff1f5,bg=#40a02b
  '';
}
