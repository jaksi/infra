{ fetchurl, stdenv, package, hashes, installPhase, linuxPlatform ? "linux" }:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";
  plat = {
    x86_64-linux = "${linuxPlatform}-x64";
    aarch64-linux = "${linuxPlatform}-arm64";
  }.${system} or throwSystem;
in stdenv.mkDerivation rec {
  pname = "vscode-${package}";
  version = "1.85.1";
  src = fetchurl {
    url =
      "https://update.code.visualstudio.com/${version}/${package}-${plat}/stable";
    name = "${package}.tar.gz";
    hash = hashes.${system};
  };
  sourceRoot = ".";
  inherit installPhase;
}
