self: super: {
  vscode-cli = super.callPackage ./vscode.nix {
    package = "cli";
    hashes = {
      x86_64-linux = "sha256-jDW2+xFQcmSwCE/QRyfjwL7B3dqrVAYo1dX4wqx/k9U=";
      aarch64-linux = "sha256-GOegfG0flyOEZUlCYhUfRxgLXqTcKw3lFBM7oU6RfMY=";
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
      x86_64-linux = "sha256-oMfV45cJYZiC35spxi49PNh3iytUpdVjd/C3L4lLWL0=";
      aarch64-linux = "sha256-15JqzUYI/NuQjUGuBOjizx6LlDMkJmfU6H4LWVh2hUk=";
    };
    installPhase = ''
      mkdir -p $out
      cp -r vscode-server-*/* $out/
      ln -sf ${self.nodejs_18}/bin/node $out/
    '';
  };
}
