self: super: {
  vscode-cli = super.callPackage ./vscode.nix {
    package = "cli";
    hashes.x86_64-linux = "sha256-zEaboEYRQfw6WPWJJixufSv6QwRN0mcmfnlOjYm4MdE=";
    installPhase = ''
      mkdir -p $out/bin
      cp code $out/bin/
    '';
    linuxPlatform = "alpine";
  };
  vscode-server = super.callPackage ./vscode.nix {
    package = "server";
    hashes.x86_64-linux = "sha256-IFsnV4g7pZJD4WdOVa8PHsRpVq7whdje/H2drK0Xxxg=";
    installPhase = ''
      mkdir -p $out
      cp -r vscode-server-*/* $out/
      ln -sf ${self.nodejs_18}/bin/node $out/
    '';
  };
}
