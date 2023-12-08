self: super: {
  vscode-cli = super.callPackage ./vscode.nix {
    package = "cli";
    hashes = {
      x86_64-linux = "sha256-P+0L1EP3JtfGJbsvqmGaM30aVMUDadSWZULUuLvfX3U=";
      aarch64-linux = "sha256-eyNh27ZrCWR8TyeGqhQRkCuueAlD08hAZwspI6vpiCU=";
    };
    installPhase = ''
      mkdir -p $out/bin
      cp code $out/bin/
    '';
    linuxPlatform = "alpine";
  };
  vscode-server = super.callPackage ./vscode.nix {
    package = "server";
    hashes = {
      x86_64-linux = "sha256-X4peU0sDYGRDNHVbjdRhuaL2AXHMcI0xmO3s0L8+faI=";
      aarch64-linux = "sha256-lLX6ClXFhBY9C+dYjlf1ICH0MP3nUMrOgFffJsdd5hI=";
    };
    installPhase = ''
      mkdir -p $out
      cp -r vscode-server-*/* $out/
      ln -sf ${self.nodejs_18}/bin/node $out/
    '';
  };
}
