# M2 Mac mini

{
  imports =
    [ ../hardware/apple-silicon.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "ant";

  fileSystems."/boot".device = "/dev/disk/by-uuid/33CF-1813";
}
