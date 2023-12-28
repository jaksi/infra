# M2 Mac mini

{
  imports =
    [ ../hardware/apple-silicon.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "ant";
}
