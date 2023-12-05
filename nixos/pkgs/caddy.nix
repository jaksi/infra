{ lib, buildGoModule, caddy, modules ? { }, vendorHash ? "" }:

caddy.override {
  buildGoModule = let
    patchMain = ''
      substituteInPlace cmd/caddy/main.go --replace '	// plug in Caddy modules here' '${
        lib.strings.concatMapStringsSep "\n" (module: "	_ \"${module}\"")
        (lib.attrsets.mapAttrsToList (module: _: module) modules)
      }'
    '';
  in args:
  buildGoModule (args // {
    inherit vendorHash;
    overrideModAttrs = attrs:
      attrs // {
        preBuild = ''
          ${patchMain}
          go get -v ${
            lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList
              (module: version: "${module}@${version}") modules)
          }
          ${attrs.preBuild or ""}
        '';
        postInstall = ''
          ${attrs.postInstall or ""}
          cp go.{mod,sum} $out/
        '';
      };
    preBuild = ''
      ${patchMain}
      cp vendor/go.{mod,sum} .
      ${args.preBuild or ""}
    '';
  });
}
